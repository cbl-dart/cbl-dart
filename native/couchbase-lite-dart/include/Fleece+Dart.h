#pragma once

#include "CBLDart_Export.h"
#include "dart/dart_api_dl.h"
#ifdef CBL_FRAMEWORK_HEADERS
#include <CouchbaseLite/Fleece.h>
#else
#include "fleece/Fleece.h"
#endif

extern "C" {

// === Slice ==================================================================

CBLDART_EXPORT
void CBLDart_FLSliceResult_BindToDartObject(Dart_Handle object,
                                            FLSliceResult slice, bool retain);

CBLDART_EXPORT
void CBLDart_FLSliceResult_Retain(FLSliceResult slice);

CBLDART_EXPORT
void CBLDart_FLSliceResult_Release(FLSliceResult slice);

// === Doc ====================================================================

CBLDART_EXPORT
void CBLDart_FLDoc_BindToDartObject(Dart_Handle object, FLDoc doc);

// === Value ==================================================================

CBLDART_EXPORT
void CBLDart_FLValue_BindToDartObject(Dart_Handle object, FLValue value,
                                      bool retain);

// === Dict ===================================================================

typedef struct {
  FLDictIterator *iterator;
  FLSlice keyString;
  bool done;
} CBLDart_DictIterator;

CBLDART_EXPORT
CBLDart_DictIterator *CBLDart_FLDictIterator_Begin(Dart_Handle object,
                                                   FLDict dict);

CBLDART_EXPORT
void CBLDart_FLDictIterator_Next(CBLDart_DictIterator *iterator);

// === Decoder ================================================================

struct CBLDart_LoadedFLValue {
  bool exists;
  int8_t type;
  bool isInteger;
  uint32_t collectionSize;
  bool asBool;
  int64_t asInt;
  double asDouble;
  FLString asString;
  FLSlice asData;
  FLValue asValue;
};

CBLDART_EXPORT
void CBLDart_FLValue_FromData(FLSlice data, uint8_t trust,
                              CBLDart_LoadedFLValue *out);

CBLDART_EXPORT
void CBLDart_GetLoadedFLValue(FLValue value, CBLDart_LoadedFLValue *out);

CBLDART_EXPORT
void CBLDart_FLArray_GetLoadedFLValue(FLArray array, uint32_t index,
                                      CBLDart_LoadedFLValue *out);

CBLDART_EXPORT
void CBLDart_FLDict_GetLoadedFLValue(FLDict dict, FLString key,
                                     CBLDart_LoadedFLValue *out);

struct CBLDart_FLDictIterator2 {
  bool isDone;
  FLString *keyOut;
  CBLDart_LoadedFLValue *valueOut;
  FLDictIterator *_iterator;
};

CBLDART_EXPORT
CBLDart_FLDictIterator2 *CBLDart_FLDictIterator2_Begin(
    Dart_Handle object, FLDict dict, FLString *keyOut,
    CBLDart_LoadedFLValue *valueOut);

CBLDART_EXPORT
void CBLDart_FLDictIterator2_Next(CBLDart_FLDictIterator2 *iterator);

// === Encoder ================================================================

CBLDART_EXPORT
void CBLDart_FLEncoder_BindToDartObject(Dart_Handle object, FLEncoder encoder);

CBLDART_EXPORT
bool CBLDart_FLEncoder_WriteArrayValue(FLEncoder encoder, FLArray array,
                                       uint32_t index);
}
