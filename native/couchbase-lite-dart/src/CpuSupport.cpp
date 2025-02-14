#include "CpuSupport.h"

#include <cstddef>
#include <cstdint>

#ifdef _WIN32
#include <intrin.h>
#else
#include <cpuid.h>
#endif

#ifdef _WIN32
#define __cross_cpuid(leaf, info) __cpuid(info, leaf)
#else
#define __cross_cpuid(leaf, info) \
  __cpuid(leaf, info[0], info[1], info[2], info[3])
#endif

namespace CBLDart {

bool CpuSupportsAVX2() {
#if !defined(__x86_64__) && !defined(_M_X64)
  // AVX2 is only supported on Intel architectures and we only support 64-bit
  // on those architectures.
  return false;
#else
  const size_t CPU_INFO_SIZE = 4;
  const unsigned int MAX_FUNCTION_LEAF = 0;
  const unsigned int EXTENDED_FEATURES_LEAF = 7;
  const unsigned int AVX2_BIT = 5;
  const unsigned int AVX2_MASK = 1U << AVX2_BIT;

  int32_t cpuInfo[CPU_INFO_SIZE];

  __cross_cpuid(MAX_FUNCTION_LEAF, cpuInfo);
  if (cpuInfo[0] < EXTENDED_FEATURES_LEAF) {
    return false;
  }

  __cross_cpuid(EXTENDED_FEATURES_LEAF, cpuInfo);
  return (cpuInfo[1] & AVX2_MASK) != 0;
#endif
}

}  // namespace CBLDart
