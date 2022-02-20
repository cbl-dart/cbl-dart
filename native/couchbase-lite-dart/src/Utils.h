#include "dart/dart_api_dl.h"
#ifdef CBL_FRAMEWORK_HEADERS
#include <CouchbaseLite/Fleece.h>
#else
#include "fleece/Fleece.h"
#endif
#include "Fleece+Dart.h"

/**
 * The external allocation size that is used for objects for which the exact
 * size is not known.
 *
 * This value is used when creating finalizers for Dart objects. The value is
 * larger than 0 to signal to the Dart VM that running the finalizer will free
 * memory.
 */
#define CBLDart_kFakeExternalAllocationSize 64

// === Dart Native ============================================================

/**
 * Returns the value of the given Dart CObject, wich is expected to be either an
 * int32 or int64, as an int64_t.
 */
int64_t CBLDart_CObject_getIntValueAsInt64(Dart_CObject* object);

void CBLDart_CObject_SetEmptyArray(Dart_CObject* object);

void CBLDart_CObject_SetPointer(Dart_CObject* object, const void* pointer);

void CBLDart_CObject_SetFLString(Dart_CObject* object, const FLString string);

// === Fleece =================================================================

std::string CBLDart_FLStringToString(FLString slice);
