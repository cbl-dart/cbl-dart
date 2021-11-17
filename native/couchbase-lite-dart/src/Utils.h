#include "dart/dart_api_dl.h"
#ifdef CBL_FRAMEWORK_HEADERS
#include <CouchbaseLite/Fleece.h>
#else
#include "fleece/Fleece.h"
#endif
#include "Fleece+Dart.h"

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

#define kCBLDartNullSlice (struct CBLDart_FLSlice{nullptr, 0})

FLSlice CBLDart_FLSliceFromDart(CBLDart_FLSlice slice);

CBLDart_FLSlice CBLDart_FLSliceToDart(FLSlice slice);

FLSliceResult CBLDart_FLSliceResultFromDart(CBLDart_FLSliceResult slice);

CBLDart_FLSliceResult CBLDart_FLSliceResultToDart(FLSliceResult slice);

FLString CBLDart_FLStringFromDart(CBLDart_FLString slice);

CBLDart_FLString CBLDart_FLStringToDart(FLString slice);

FLStringResult CBLDart_FLStringResultFromDart(CBLDart_FLStringResult slice);

CBLDart_FLStringResult CBLDart_FLStringResultToDart(FLStringResult slice);

std::string CBLDart_FLStringToString(FLString slice);
