#include <iostream>

#include "Fleece+Dart.h"

// Fleece ----------------------------------------------------------------------

// -- Slice

FLSliceResult CBLDart_FLSliceResultFromDart(CBLDart_FLSlice slice) {
  return {slice.buf, static_cast<size_t>(slice.size)};
}

CBLDart_FLSlice CBLDart_FLSliceResultToDart(FLSliceResult slice) {
  return {slice.buf, slice.size};
}

FLSlice CBLDart_FLSliceFromDart(CBLDart_FLSlice slice) {
  return {slice.buf, static_cast<size_t>(slice.size)};
}

CBLDart_FLSlice CBLDart_FLSliceToDart(FLSlice slice) {
  return {slice.buf, slice.size};
}

uint8_t CBLDart_FLSlice_Equal(CBLDart_FLSlice a, CBLDart_FLSlice b) {
  return FLSlice_Equal(CBLDart_FLSliceFromDart(a), CBLDart_FLSliceFromDart(b));
}

int64_t CBLDart_FLSlice_Compare(CBLDart_FLSlice a, CBLDart_FLSlice b) {
  return FLSlice_Compare(CBLDart_FLSliceFromDart(a),
                         CBLDart_FLSliceFromDart(b));
}

CBLDart_FLSlice CBLDart_FLSliceResult_New(uint64_t size) {
  return CBLDart_FLSliceResultToDart(FLSliceResult_New(size));
}

CBLDart_FLSlice CBLDart_FLSlice_Copy(CBLDart_FLSlice slice) {
  return CBLDart_FLSliceResultToDart(
      FLSlice_Copy(CBLDart_FLSliceFromDart(slice)));
}

void CBLDart_ReleaseDartObjectBoundFLSliceResult(void *dart_callback_data,
                                                 void *peer) {
  auto slice = reinterpret_cast<FLSliceResult *>(peer);
  FLSliceResult_Release(*slice);
  delete slice;
}

void CBLDart_FLSliceResult_BindToDartObject(Dart_Handle object,
                                            CBLDart_FLSlice slice,
                                            uint8_t retain) {
  auto _slice = new FLSliceResult;
  *_slice = CBLDart_FLSliceResultFromDart(slice);

  if (retain) {
    FLSliceResult_Retain(*_slice);
  }

  Dart_NewFinalizableHandle_DL(object, _slice, 0,
                               CBLDart_ReleaseDartObjectBoundFLSliceResult);
}

void CBLDart_FLSliceResult_Release(CBLDart_FLSlice *slice) {
  FLSliceResult_Release(CBLDart_FLSliceResultFromDart(*slice));
}

// -- Doc

FLDoc CBLDart_FLDoc_FromJSON(char *json, FLError *error) {
  return FLDoc_FromJSON(FLStr(json), error);
}

void CBLDart_ReleaseDartObjectBoundFLDoc(void *dart_callback_data, void *peer) {
  auto doc = reinterpret_cast<FLDoc>(peer);
  FLDoc_Release(doc);
}

void CBLDart_FLDoc_BindToDartObject(Dart_Handle handle, FLDoc doc) {
  Dart_NewFinalizableHandle_DL(handle, doc, 0,
                               CBLDart_ReleaseDartObjectBoundFLDoc);
}

// -- Value

void CBLDart_ReleaseDartObjectBoundFLValue(void *dart_callback_data,
                                           void *peer) {
  auto value = reinterpret_cast<FLValue>(peer);
  FLValue_Release(value);
}

void CBLDart_FLValue_BindToDartObject(Dart_Handle handle, FLValue value,
                                      bool retain) {
  // There is nothing to be done for `null` und `undefined`.
  if (value == NULL ||  // The null pointer represents `undefined` values.
      value == kFLNullValue)
    return;

  if (retain) FLValue_Retain(value);

  Dart_NewFinalizableHandle_DL(handle, (void *)value, 0,
                               CBLDart_ReleaseDartObjectBoundFLValue);
}

void CBLDart_FLValue_AsString(FLValue value, CBLDart_FLSlice *slice) {
  *slice = CBLDart_FLSliceToDart(FLValue_AsString(value));
}

void CBLDart_FLValue_AsData(FLValue value, CBLDart_FLSlice *slice) {
  *slice = CBLDart_FLSliceToDart(FLValue_AsData(value));
}

void CBLDart_FLValue_ToString(FLValue value, CBLDart_FLSlice *slice) {
  *slice = CBLDart_FLSliceResultToDart(FLValue_ToString(value));
}

void CBLDart_FLValue_ToJSONX(FLValue value, bool json5, bool canonicalForm,
                             CBLDart_FLSlice *result) {
  auto json = FLValue_ToJSONX(value, json5, canonicalForm);
  *result = CBLDart_FLSliceResultToDart(json);
}

// -- Dict

FLValue CBLDart_FLDict_Get(FLDict dict, char *keyString) {
  return FLDict_Get(dict, FLStr(keyString));
}

void CBLDart_FinalizeDartObjectBoundDictIterator(void *dart_callback_data,
                                                 void *peer) {
  auto iterator = reinterpret_cast<CBLDart_DictIterator *>(peer);

  if (!iterator->done) FLDictIterator_End(iterator->iterator);

  delete iterator->iterator;
  delete iterator;
}

CBLDart_DictIterator *CBLDart_FLDictIterator_Begin(Dart_Handle handle,
                                                   FLDict dict) {
  auto iterator = new CBLDart_DictIterator;
  iterator->iterator = new FLDictIterator;
  iterator->keyString = kCBLDartNullSlice;
  iterator->done = false;

  FLDictIterator_Begin(dict, iterator->iterator);

  Dart_NewFinalizableHandle_DL(handle, iterator, sizeof(iterator),
                               CBLDart_FinalizeDartObjectBoundDictIterator);

  return iterator;
}

void CBLDart_FLDictIterator_Next(CBLDart_DictIterator *iterator) {
  auto value = FLDictIterator_GetValue(iterator->iterator);
  if (value != NULL) {
    auto key = FLDictIterator_GetKeyString(iterator->iterator);
    iterator->keyString = CBLDart_FLSliceToDart(key);
    iterator->done = !FLDictIterator_Next(iterator->iterator);
  } else {
    iterator->keyString = kCBLDartNullSlice;
    iterator->done = true;
  }
}

void CBLDart_FLMutableDict_Remove(FLMutableDict dict, char *key) {
  FLMutableDict_Remove(dict, FLStr(key));
}

FLSlot CBLDart_FLMutableDict_Set(FLMutableDict dict, char *key) {
  return FLMutableDict_Set(dict, FLStr(key));
}

void CBLDart_FLSlot_SetString(FLSlot slot, char *value) {
  FLSlot_SetString(slot, FLStr(value));
}

FLMutableArray CBLDart_FLMutableDict_GetMutableArray(FLMutableDict dict,
                                                     char *key) {
  return FLMutableDict_GetMutableArray(dict, FLStr(key));
}

FLMutableDict CBLDart_FLMutableDict_GetMutableDict(FLMutableDict dict,
                                                   char *key) {
  return FLMutableDict_GetMutableDict(dict, FLStr(key));
}
