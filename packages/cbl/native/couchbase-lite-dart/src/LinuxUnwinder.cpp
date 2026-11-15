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
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
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

// The unwinder API of libgcc_s.
constexpr const char* kUnwindFunctions[] = {
    "_Unwind_Backtrace",
    "_Unwind_DeleteException",
    "_Unwind_FindEnclosingFunction",
    "_Unwind_Find_FDE",
    "_Unwind_ForcedUnwind",
    "_Unwind_GetCFA",
    "_Unwind_GetDataRelBase",
    "_Unwind_GetGR",
    "_Unwind_GetIP",
    "_Unwind_GetIPInfo",
    "_Unwind_GetLanguageSpecificData",
    "_Unwind_GetRegionStart",
    "_Unwind_GetTextRelBase",
    "_Unwind_RaiseException",
    "_Unwind_Resume",
    "_Unwind_Resume_or_Rethrow",
    "_Unwind_SetGR",
    "_Unwind_SetIP",
};

struct Definitions {
  void* conflicting;
  void* libgcc;
};

/// Rewrites the `_Unwind_*` relocations of loaded objects, which are bound to
/// the conflicting object, to the definitions in libgcc_s.
///
/// Objects are processed from within the dl_iterate_phdr callback. The
/// callback must not call into the loader (dlsym, dladdr, ...), since that
/// can deadlock. Only pinned objects are processed: objects that a concurrent
/// dlopen is still relocating are also visible to dl_iterate_phdr and must
/// not be touched.
class UnwindRebinder {
 public:
  UnwindRebinder(ElfW(Addr) conflictingLoadAddress,
                 std::unordered_set<ElfW(Addr)> pinnedLoadAddresses,
                 std::unordered_map<std::string, Definitions> definitions)
      : conflictingLoadAddress_(conflictingLoadAddress),
        pinnedLoadAddresses_(std::move(pinnedLoadAddresses)),
        definitions_(std::move(definitions)),
        pageSize_(static_cast<ElfW(Addr)>(sysconf(_SC_PAGESIZE))) {}

  static int Rebind(dl_phdr_info* info, size_t, void* data) {
    static_cast<UnwindRebinder*>(data)->rebind(*info);
    return 0;
  }

  int reboundCount() const { return reboundCount_; }

  const std::string& problems() const { return problems_; }

 private:
  void rebind(const dl_phdr_info& object) {
    // The conflicting object keeps using its own unwinder.
    if (object.dlpi_addr == conflictingLoadAddress_ ||
        !pinnedLoadAddresses_.count(object.dlpi_addr)) {
      return;
    }

    const ElfW(Phdr)* dynamicPhdr = nullptr;
    const ElfW(Phdr)* relroPhdr = nullptr;
    for (ElfW(Half) i = 0; i < object.dlpi_phnum; i++) {
      if (object.dlpi_phdr[i].p_type == PT_DYNAMIC) {
        dynamicPhdr = &object.dlpi_phdr[i];
      } else if (object.dlpi_phdr[i].p_type == PT_GNU_RELRO) {
        relroPhdr = &object.dlpi_phdr[i];
      }
    }
    if (!dynamicPhdr) {
      return;
    }

    auto base = object.dlpi_addr;
    auto dynamic =
        reinterpret_cast<const ElfW(Dyn)*>(base + dynamicPhdr->p_vaddr);

    // glibc rewrites these entries to absolute addresses in memory, unless
    // the dynamic section is read-only (e.g. the vDSO).
    auto toAddress = [&](ElfW(Addr) pointer) {
      return pointer < base ? pointer + base : pointer;
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

    // RELRO pages are read-only after relocation. glibc protects the range
    // rounded down to page boundaries at both ends.
    ElfW(Addr) relroStart = 0, relroEnd = 0;
    if (relroPhdr) {
      relroStart = (base + relroPhdr->p_vaddr) & ~(pageSize_ - 1);
      relroEnd =
          (base + relroPhdr->p_vaddr + relroPhdr->p_memsz) & ~(pageSize_ - 1);
    }
    auto isInRelro = [&](ElfW(Addr) address) {
      return address >= relroStart && address < relroEnd;
    };

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
        auto definitions = definitions_.find(strings + nameOffset);
        if (definitions == definitions_.end()) {
          continue;
        }
        auto slot = base + relocs[i].r_offset;
        if (!isMapped(object, slot, sizeof(void*), PF_W)) {
          addProblem(object, std::string("slot of ") + definitions->first +
                                 " not writable");
          continue;
        }
        auto current = *reinterpret_cast<void* const*>(slot);
        if (current == definitions->second.libgcc) {
          continue;
        }
        writes.emplace_back(slot, definitions->second.libgcc);
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

    bool needsUnprotect = false;
    for (auto& write : writes) {
      if (isInRelro(write.first)) {
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
      if (isInRelro(write.first) && !relroWritable) {
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

  static bool isMapped(const dl_phdr_info& object, ElfW(Addr) address,
                       size_t size, ElfW(Word) requiredFlags = 0) {
    for (ElfW(Half) i = 0; i < object.dlpi_phnum; i++) {
      auto& phdr = object.dlpi_phdr[i];
      if (phdr.p_type != PT_LOAD ||
          (phdr.p_flags & requiredFlags) != requiredFlags) {
        continue;
      }
      auto start = object.dlpi_addr + phdr.p_vaddr;
      auto end = start + phdr.p_memsz;
      if (address >= start && address <= end && size <= end - address) {
        return true;
      }
    }
    return false;
  }

  void addProblem(const dl_phdr_info& object, const std::string& problem) {
    if (!problems_.empty()) {
      problems_ += "; ";
    }
    problems_ +=
        (object.dlpi_name && object.dlpi_name[0] ? object.dlpi_name : "<main>");
    problems_ += ": " + problem;
  }

  ElfW(Addr) conflictingLoadAddress_;
  std::unordered_set<ElfW(Addr)> pinnedLoadAddresses_;
  std::unordered_map<std::string, Definitions> definitions_;
  ElfW(Addr) pageSize_;
  int reboundCount_ = 0;
  std::string problems_;
};

int CollectName(dl_phdr_info* info, size_t, void* data) {
  static_cast<std::vector<std::string>*>(data)->emplace_back(
      info->dlpi_name ? info->dlpi_name : "");
  return 0;
}

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
  link_map* conflictingMap = nullptr;
  if (libgccRaise &&
      dladdr1(defaultRaise, &defaultInfo,
              reinterpret_cast<void**>(&conflictingMap), RTLD_DL_LINKMAP) &&
      conflictingMap && dladdr(libgccRaise, &libgccInfo) &&
      defaultInfo.dli_fbase != libgccInfo.dli_fbase) {
    // Resolve everything up front, since the rebinder must not call into the
    // loader.
    std::unordered_map<std::string, Definitions> definitions;
    for (auto name : kUnwindFunctions) {
      auto conflicting = dlsym(RTLD_DEFAULT, name);
      auto gcc = dlsym(libgcc, name);
      Dl_info info;
      if (conflicting && gcc && dladdr(conflicting, &info) &&
          info.dli_fbase == defaultInfo.dli_fbase) {
        definitions.emplace(name, Definitions{conflicting, gcc});
      }
    }
    dlerror();

    // Pin all loaded objects. dlopen waits for a concurrent dlopen or dlclose
    // to finish, so pinned objects are fully relocated and stay loaded.
    std::vector<std::string> names;
    dl_iterate_phdr(CollectName, &names);
    std::vector<void*> handles;
    std::unordered_set<ElfW(Addr)> pinnedLoadAddresses;
    for (auto& name : names) {
      auto handle = dlopen(name.empty() ? nullptr : name.c_str(),
                           RTLD_LAZY | RTLD_NOLOAD);
      if (!handle) {
        continue;
      }
      handles.push_back(handle);
      link_map* map = nullptr;
      if (dlinfo(handle, RTLD_DI_LINKMAP, &map) == 0 && map) {
        pinnedLoadAddresses.insert(map->l_addr);
      }
    }
    dlerror();

    UnwindRebinder rebinder(conflictingMap->l_addr,
                            std::move(pinnedLoadAddresses),
                            std::move(definitions));
    dl_iterate_phdr(UnwindRebinder::Rebind, &rebinder);

    for (auto handle : handles) {
      dlclose(handle);
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
