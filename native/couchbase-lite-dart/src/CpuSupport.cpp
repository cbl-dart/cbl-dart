#include "CpuSupport.h"

namespace CBLDart {

bool CpuSupportsAVX2() { return __builtin_cpu_supports("avx2"); }

}  // namespace CBLDart
