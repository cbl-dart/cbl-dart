#pragma once

#include "cbldart_export.h"
#include "dart/dart_api_dl.h"
#include "fleece/Fleece.h"

extern "C" {
// Slice -------------------------------------------------------------------

/**
 * See `FLSlice` in Dart code.
 */
struct CBLDartSlice {
  const void *buf;
  uint64_t size;
};

#define kCBLDartNullSlice ((CBLDartSlice){NULL, 0})

FLSliceResult CBLDart_FLSliceResultFromDart(CBLDartSlice slice);

CBLDartSlice CBLDart_FLSliceResultToDart(FLSliceResult slice);

CBLDartSlice CBLDart_FLSliceToDart(FLSlice slice);

CBLDART_EXPORT
void CBLDart_FLSliceResult_Release(CBLDartSlice *slice);

// Doc ---------------------------------------------------------------------

CBLDART_EXPORT
FLDoc CBLDart_FLDoc_FromJSON(char *json, FLError *error);

CBLDART_EXPORT
void CBLDart_FLDoc_BindToDartObject(Dart_Handle handle, FLDoc doc);

// Value -------------------------------------------------------------------

CBLDART_EXPORT
void CBLDart_FLValue_BindToDartObject(Dart_Handle handle, FLValue value,
                                      bool retain);

CBLDART_EXPORT
void CBLDart_FLValue_AsString(FLValue value, CBLDartSlice *slice);

CBLDART_EXPORT
void CBLDart_FLValue_AsData(FLValue value, CBLDartSlice *slice);

CBLDART_EXPORT
void CBLDart_FLValue_ToString(FLValue value, CBLDartSlice *slice);

CBLDART_EXPORT
void CBLDart_FLValue_ToJSONX(FLValue value, bool json5, bool canonicalForm,
                             CBLDartSlice *result);

// Dict --------------------------------------------------------------------

CBLDART_EXPORT
FLValue CBLDart_FLDict_Get(FLDict dict, char *keyString);

typedef struct {
  FLDictIterator *iterator;
  CBLDartSlice keyString;
  bool done;
} CBLDart_DictIterator;

CBLDART_EXPORT
CBLDart_DictIterator *CBLDart_FLDictIterator_Begin(Dart_Handle handle,
                                                   FLDict dict);

CBLDART_EXPORT
void CBLDart_FLDictIterator_Next(CBLDart_DictIterator *iterator);

CBLDART_EXPORT
void CBLDart_FLMutableDict_Remove(FLMutableDict dict, char *key);

CBLDART_EXPORT
FLSlot CBLDart_FLMutableDict_Set(FLMutableDict dict, char *key);

CBLDART_EXPORT
void CBLDart_FLSlot_SetString(FLSlot slot, char *value);

CBLDART_EXPORT
FLMutableArray CBLDart_FLMutableDict_GetMutableArray(FLMutableDict dict,
                                                     char *key);

CBLDART_EXPORT
FLMutableDict CBLDart_FLMutableDict_GetMutableDict(FLMutableDict dict,
                                                   char *key);
}
