#include <iostream>

#include "FleeceDart.h"

// Fleece ----------------------------------------------------------------------

// -- Slice

FLSliceResult CBLDart_FLSliceResultFromDart(CBLDart_FLSlice slice)
{
    FLSliceResult result = {slice.buf, slice.size};
    return result;
}

CBLDart_FLSlice CBLDart_FLSliceResultToDart(FLSliceResult slice)
{
    CBLDart_FLSlice result = {slice.buf, slice.size};
    return result;
}

CBLDart_FLSlice CBLDart_FLSliceToDart(FLSlice slice)
{
    CBLDart_FLSlice result = {slice.buf, slice.size};
    return result;
}

void CBLDart_FLSliceResult_Release(CBLDart_FLSlice *slice)
{
    FLSliceResult_Release(CBLDart_FLSliceResultFromDart(*slice));
}

// -- Doc

FLDoc CBLDart_FLDoc_FromJSON(char *json,
                             FLError *error)
{
    return FLDoc_FromJSON(FLStr(json), error);
}

void CBLDart_ReleaseDartObjectBoundFLDoc(void *dart_callback_data,
                                         void *peer)
{
    auto doc = reinterpret_cast<FLDoc>(peer);
    FLDoc_Release(doc);
}

void CBLDart_FLDoc_BindToDartObject(Dart_Handle handle,
                                    FLDoc doc)
{
    Dart_NewWeakPersistentHandle_DL(
        handle,
        doc,
        0,
        CBLDart_ReleaseDartObjectBoundFLDoc);
}

// -- Value

void CBLDart_ReleaseDartObjectBoundFLValue(void *dart_callback_data,
                                           void *peer)
{
    auto value = reinterpret_cast<FLValue>(peer);
    FLValue_Release(value);
}

void CBLDart_FLValue_BindToDartObject(Dart_Handle handle,
                                      FLValue value,
                                      bool retain)
{
    // There is nothing to be done for `null` und `undefined`.
    if (value == NULL || // The null pointer represents `undefined` values.
        value == kFLNullValue)
        return;

    if (retain)
        FLValue_Retain(value);

    Dart_NewWeakPersistentHandle_DL(
        handle,
        (void *)value,
        0,
        CBLDart_ReleaseDartObjectBoundFLValue);
}

void CBLDart_FLValue_BindDocToDartObject(Dart_Handle handle,
                                         FLValue value)
{
    auto doc = FLValue_FindDoc(value);
    if (doc == NULL)
        return;

    Dart_NewWeakPersistentHandle_DL(
        handle,
        doc,
        0,
        CBLDart_ReleaseDartObjectBoundFLDoc);
}

void CBLDart_FLValue_AsString(FLValue value,
                              CBLDart_FLSlice *slice)
{
    auto fl_slice = FLValue_AsString(value);
    slice->buf = fl_slice.buf;
    slice->size = fl_slice.size;
}

void CBLDart_FLValue_ToString(FLValue value,
                              CBLDart_FLSlice *slice)
{
    *slice = CBLDart_FLSliceResultToDart(FLValue_ToString(value));
}

void CBLDart_FLValue_ToJSONX(FLValue value,
                             bool json5,
                             bool canonicalForm,
                             CBLDart_FLSlice *result)
{
    auto json = FLValue_ToJSONX(value, json5, canonicalForm);
    *result = CBLDart_FLSliceResultToDart(json);
}

// -- Dict

FLValue CBLDart_FLDict_Get(FLDict dict,
                           char *keyString)
{
    return FLDict_Get(dict, FLStr(keyString));
}

void CBLDart_FinalizeDartObjectBoundDictIterator(
    void *dart_callback_data,
    void *peer)
{
    auto iterator = reinterpret_cast<CBLDart_DictIterator *>(peer);

    if (FLDictIterator_Next(iterator->iterator))
        FLDictIterator_End(iterator->iterator);

    delete iterator->iterator;
    delete iterator->keyString;
    delete iterator;
}

CBLDart_DictIterator *CBLDart_FLDictIterator_Begin(Dart_Handle handle,
                                                   FLDict dict)
{
    auto iterator = new CBLDart_DictIterator;
    iterator->iterator = new FLDictIterator;
    iterator->keyString = new CBLDart_FLSlice;

    FLDictIterator_Begin(dict, iterator->iterator);

    Dart_NewWeakPersistentHandle_DL(
        handle,
        iterator,
        sizeof(iterator),
        CBLDart_FinalizeDartObjectBoundDictIterator);

    return iterator;
}

void CBLDart_FLDictIterator_GetKeyString(FLDictIterator *iterator,
                                         CBLDart_FLSlice *keyString)
{
    *keyString = CBLDart_FLSliceToDart(FLDictIterator_GetKeyString(iterator));
}

void CBLDart_FLMutableDict_Remove(FLMutableDict dict,
                                  char *key)
{
    FLMutableDict_Remove(dict, FLStr(key));
}

FLSlot CBLDart_FLMutableDict_Set(FLMutableDict dict,
                                 char *key)
{
    return FLMutableDict_Set(dict, FLStr(key));
}

void CBLDart_FLSlot_SetString(FLSlot slot,
                              char *value)
{
    FLSlot_SetString(slot, FLStr(value));
}

FLMutableArray CBLDart_FLMutableDict_GetMutableArray(FLMutableDict dict,
                                                     char *key)
{
    return FLMutableDict_GetMutableArray(dict, FLStr(key));
}

FLMutableDict CBLDart_FLMutableDict_GetMutableDict(FLMutableDict dict,
                                                   char *key)
{
    return FLMutableDict_GetMutableDict(dict, FLStr(key));
}
