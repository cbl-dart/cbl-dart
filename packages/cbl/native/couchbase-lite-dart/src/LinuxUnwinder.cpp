#include "LinuxUnwinder.h"

#if defined(__linux__) && !defined(__ANDROID__) && \
    (defined(__x86_64__) || defined(__aarch64__))

#include <dlfcn.h>
#include <elf.h>
#include <link.h>
#include <sys/mman.h>
#include <unistd.h>

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "cbl/CouchbaseLite.h"

namespace CBLDart {

namespace {

#if defined(__x86_64__)
constexpr uint32_t kJumpSlotReloc = R_X86_64_JUMP_SLOT;
constexpr uint32_t kGlobDatReloc = R_X86_64_GLOB_DAT;
#else
constexpr uint32_t kJumpSlotReloc = R_AARCH64_JUMP_SLOT;
constexpr uint32_t kGlobDatReloc = R_AARCH64_GLOB_DAT;
#endif

constexpr const char* kUnwindPrefix = "_Unwind_";
constexpr size_t kUnwindPrefixLength = 8;

struct LoadedObject {
  std::string name;
  ElfW(Addr) base;
  const ElfW(Phdr) * phdrs;
  ElfW(Half) phnum;
};

int CollectLoadedObject(dl_phdr_info* info, size_t, void* data) {
  static_cast<std::vector<LoadedObject>*>(data)->push_back(
      {info->dlpi_name ? info->dlpi_name : "", info->dlpi_addr, info->dlpi_phdr,
       info->dlpi_phnum});
  return 0;
}

/// Rewrites the `_Unwind_*` relocations of loaded objects, which are bound to
/// the conflicting object, to the definitions in libgcc_s.
class UnwindRebinder {
 public:
  UnwindRebinder(void* libgcc, const void* conflictingBase)
      : libgcc_(libgcc), conflictingBase_(conflictingBase) {}

  void rebind(const LoadedObject& object) {
    const ElfW(Phdr)* dynamicPhdr = nullptr;
    const ElfW(Phdr)* relroPhdr = nullptr;
    for (ElfW(Half) i = 0; i < object.phnum; i++) {
      if (object.phdrs[i].p_type == PT_DYNAMIC) {
        dynamicPhdr = &object.phdrs[i];
      } else if (object.phdrs[i].p_type == PT_GNU_RELRO) {
        relroPhdr = &object.phdrs[i];
      }
    }
    if (!dynamicPhdr) {
      return;
    }

    auto dynamic =
        reinterpret_cast<const ElfW(Dyn)*>(object.base + dynamicPhdr->p_vaddr);

    // The conflicting object keeps using its own unwinder.
    Dl_info objectInfo;
    if (dladdr(dynamic, &objectInfo) &&
        objectInfo.dli_fbase == conflictingBase_) {
      return;
    }

    // glibc rewrites these entries to absolute addresses in memory, unless
    // the dynamic section is read-only (e.g. the vDSO).
    auto toAddress = [&](ElfW(Addr) pointer) {
      return pointer < object.base ? pointer + object.base : pointer;
    };

    ElfW(Addr) symtab = 0, strtab = 0, rela = 0, jmprel = 0;
    size_t strsz = 0, relasz = 0, pltrelsz = 0;
    ElfW(Sxword) pltrel = DT_RELA;
    for (auto entry = dynamic; entry->d_tag != DT_NULL; entry++) {
      switch (entry->d_tag) {
        case DT_SYMTAB:
          symtab = toAddress(entry->d_un.d_ptr);
          break;
        case DT_STRTAB:
          strtab = toAddress(entry->d_un.d_ptr);
          break;
        case DT_STRSZ:
          strsz = entry->d_un.d_val;
          break;
        case DT_RELA:
          rela = toAddress(entry->d_un.d_ptr);
          break;
        case DT_RELASZ:
          relasz = entry->d_un.d_val;
          break;
        case DT_JMPREL:
          jmprel = toAddress(entry->d_un.d_ptr);
          break;
        case DT_PLTRELSZ:
          pltrelsz = entry->d_un.d_val;
          break;
        case DT_PLTREL:
          pltrel = entry->d_un.d_val;
          break;
      }
    }

    if ((!rela || !relasz) && (!jmprel || !pltrelsz)) {
      return;
    }
    if (!symtab || !strtab || !isMapped(object, symtab, sizeof(ElfW(Sym))) ||
        !isMapped(object, strtab, strsz ? strsz : 1)) {
      addProblem(object, "symbol or string table not found");
      return;
    }

    std::vector<std::pair<ElfW(Addr), void*>> writes;
    auto collectWrites = [&](ElfW(Addr) table, size_t size) {
      if (!table || !size) {
        return;
      }
      if (!isMapped(object, table, size)) {
        addProblem(object, "relocation table not mapped");
        return;
      }
      auto relocs = reinterpret_cast<const ElfW(Rela)*>(table);
      auto symbols = reinterpret_cast<const ElfW(Sym)*>(symtab);
      auto strings = reinterpret_cast<const char*>(strtab);
      for (size_t i = 0; i < size / sizeof(ElfW(Rela)); i++) {
        auto type = ELF64_R_TYPE(relocs[i].r_info);
        auto symbolIndex = ELF64_R_SYM(relocs[i].r_info);
        if ((type != kJumpSlotReloc && type != kGlobDatReloc) ||
            symbolIndex == 0) {
          continue;
        }
        auto nameOffset = symbols[symbolIndex].st_name;
        if (strsz && nameOffset >= strsz) {
          continue;
        }
        auto name = strings + nameOffset;
        if (strncmp(name, kUnwindPrefix, kUnwindPrefixLength) != 0) {
          continue;
        }
        auto target = resolveLibgccDefinition(name);
        if (!target) {
          continue;
        }
        auto slot = object.base + relocs[i].r_offset;
        if (!isMapped(object, slot, sizeof(void*), PF_W)) {
          addProblem(object, std::string("slot of ") + name + " not writable");
          continue;
        }
        if (*reinterpret_cast<void* const*>(slot) != target) {
          writes.emplace_back(slot, target);
        }
      }
    };
    collectWrites(rela, relasz);
    if (pltrel == DT_RELA) {
      collectWrites(jmprel, pltrelsz);
    } else if (jmprel) {
      addProblem(object, "unsupported PLT relocation format");
    }

    if (writes.empty()) {
      return;
    }

    // RELRO pages are read-only after relocation. glibc protects the range
    // rounded down to page boundaries at both ends.
    ElfW(Addr) relroStart = 0, relroEnd = 0;
    if (relroPhdr) {
      auto pageSize = static_cast<ElfW(Addr)>(sysconf(_SC_PAGESIZE));
      relroStart = (object.base + relroPhdr->p_vaddr) & ~(pageSize - 1);
      relroEnd = (object.base + relroPhdr->p_vaddr + relroPhdr->p_memsz) &
                 ~(pageSize - 1);
    }
    bool needsUnprotect = false;
    for (auto& write : writes) {
      if (write.first >= relroStart && write.first < relroEnd) {
        needsUnprotect = true;
      }
    }

    auto relroPointer = reinterpret_cast<void*>(relroStart);
    auto relroSize = relroEnd - relroStart;
    bool relroWritable = false;
    if (needsUnprotect) {
      relroWritable =
          mprotect(relroPointer, relroSize, PROT_READ | PROT_WRITE) == 0;
      if (!relroWritable) {
        addProblem(object, "mprotect of RELRO failed");
      }
    }

    for (auto& write : writes) {
      bool inRelro = write.first >= relroStart && write.first < relroEnd;
      if (inRelro && !relroWritable) {
        continue;
      }
      __atomic_store_n(reinterpret_cast<void**>(write.first), write.second,
                       __ATOMIC_RELEASE);
      reboundCount_++;
    }

    if (relroWritable && mprotect(relroPointer, relroSize, PROT_READ) != 0) {
      addProblem(object, "restoring RELRO protection failed");
    }
  }

  int reboundCount() const { return reboundCount_; }

  const std::string& problems() const { return problems_; }

 private:
  void* resolveLibgccDefinition(const char* name) {
    auto cached = definitions_.find(name);
    if (cached != definitions_.end()) {
      return cached->second;
    }

    void* result = nullptr;
    Dl_info info;
    auto defaultDefinition = dlsym(RTLD_DEFAULT, name);
    if (defaultDefinition && dladdr(defaultDefinition, &info) &&
        info.dli_fbase == conflictingBase_) {
      result = dlsym(libgcc_, name);
    }
    definitions_.emplace(name, result);
    return result;
  }

  static bool isMapped(const LoadedObject& object, ElfW(Addr) address,
                       size_t size, ElfW(Word) requiredFlags = 0) {
    for (ElfW(Half) i = 0; i < object.phnum; i++) {
      auto& phdr = object.phdrs[i];
      if (phdr.p_type != PT_LOAD ||
          (phdr.p_flags & requiredFlags) != requiredFlags) {
        continue;
      }
      auto start = object.base + phdr.p_vaddr;
      auto end = start + phdr.p_memsz;
      if (address >= start && address <= end && size <= end - address) {
        return true;
      }
    }
    return false;
  }

  void addProblem(const LoadedObject& object, const std::string& problem) {
    if (!problems_.empty()) {
      problems_ += "; ";
    }
    problems_ +=
        (object.name.empty() ? "<main>" : object.name) + ": " + problem;
  }

  void* libgcc_;
  const void* conflictingBase_;
  std::unordered_map<std::string, void*> definitions_;
  int reboundCount_ = 0;
  std::string problems_;
};

struct LoadCounters {
  bool available;
  unsigned long long adds;
  unsigned long long subs;
};

int ReadLoadCounters(dl_phdr_info* info, size_t size, void* data) {
  auto counters = static_cast<LoadCounters*>(data);
  counters->available =
      size >= offsetof(dl_phdr_info, dlpi_subs) + sizeof(info->dlpi_subs);
  if (counters->available) {
    counters->adds = info->dlpi_adds;
    counters->subs = info->dlpi_subs;
  }
  return 1;
}

void RebindUnwinder() {
  auto defaultRaise = dlsym(RTLD_DEFAULT, "_Unwind_RaiseException");
  if (!defaultRaise) {
    dlerror();
    return;
  }

  // Only take a reference if libgcc_s is already loaded. Otherwise nothing
  // uses the GNU unwinder.
  auto libgcc = dlopen("libgcc_s.so.1", RTLD_NOW | RTLD_NOLOAD);
  if (!libgcc) {
    dlerror();
    return;
  }

  auto libgccRaise = dlsym(libgcc, "_Unwind_RaiseException");
  Dl_info defaultInfo, libgccInfo;
  if (libgccRaise && dladdr(defaultRaise, &defaultInfo) &&
      dladdr(libgccRaise, &libgccInfo) &&
      defaultInfo.dli_fbase != libgccInfo.dli_fbase) {
    std::vector<LoadedObject> objects;
    dl_iterate_phdr(CollectLoadedObject, &objects);

    UnwindRebinder rebinder(libgcc, defaultInfo.dli_fbase);
    for (auto& object : objects) {
      rebinder.rebind(object);
    }

    auto conflictingName =
        defaultInfo.dli_fname ? defaultInfo.dli_fname : "<unknown>";
    if (!rebinder.problems().empty()) {
      CBL_Log(kCBLLogDomainDatabase, kCBLLogWarning,
              "Could not rebind all _Unwind_* relocations from %s to "
              "libgcc_s.so.1. C++ exceptions might abort the process: %s",
              conflictingName, rebinder.problems().c_str());
    }
    if (rebinder.reboundCount() > 0) {
      CBL_Log(kCBLLogDomainDatabase, kCBLLogVerbose,
              "Rebound %d _Unwind_* relocations from %s to libgcc_s.so.1",
              rebinder.reboundCount(), conflictingName);
    }
  }

  dlclose(libgcc);
  dlerror();
}

}  // namespace

void EnsureGccUnwinderBinding() {
  static std::mutex mutex;
  static bool checked = false;
  static LoadCounters lastCounters{};

  std::scoped_lock lock(mutex);

  // Only check again if objects have been loaded or unloaded since the last
  // check.
  LoadCounters counters{};
  dl_iterate_phdr(ReadLoadCounters, &counters);
  if (checked && counters.available && lastCounters.available &&
      counters.adds == lastCounters.adds &&
      counters.subs == lastCounters.subs) {
    return;
  }
  checked = true;
  lastCounters = counters;

  RebindUnwinder();
}

}  // namespace CBLDart

#else

namespace CBLDart {

void EnsureGccUnwinderBinding() {}

}  // namespace CBLDart

#endif
