// C++-compatible version of dart_api_dl.c.
//
// CBuilder compiles all sources as C++ when `language: Language.cpp` is set.
// The original dart_api_dl.c contains an implicit function-pointer-to-void*
// cast that is valid in C but not in C++. This file reimplements the same
// logic with an explicit reinterpret_cast.

extern "C" {
#include "dart/dart_api_dl.h"  // NOLINT

#include "dart/dart_version.h"               // NOLINT
#include "dart/internal/dart_api_dl_impl.h"  // NOLINT
}

#include <cstring>

#define DART_API_DL_DEFINITIONS(name, R, A) name##_Type name##_DL = nullptr;

DART_API_ALL_DL_SYMBOLS(DART_API_DL_DEFINITIONS)

#undef DART_API_DL_DEFINITIONS

using DartApiEntry_function = void*;

static DartApiEntry_function FindFunctionPointer(const DartApiEntry* entries,
                                                 const char* name) {
  while (entries->name != nullptr) {
    if (std::strcmp(entries->name, name) == 0) {
      return reinterpret_cast<void*>(entries->function);
    }
    entries++;
  }
  return nullptr;
}

extern "C" intptr_t Dart_InitializeApiDL(void* data) {
  auto* dart_api_data = static_cast<DartApi*>(data);

  if (dart_api_data->major != DART_API_DL_MAJOR_VERSION) {
    return -1;
  }

  const DartApiEntry* dart_api_function_pointers = dart_api_data->functions;

#define DART_API_DL_INIT(name, R, A) \
  name##_DL =                        \
      (name##_Type)(FindFunctionPointer(dart_api_function_pointers, #name));
  DART_API_ALL_DL_SYMBOLS(DART_API_DL_INIT)
#undef DART_API_DL_INIT

  return 0;
}
