#include "Fleece+Dart.h"
#include "Utils.h"

// === Fleece =================================================================

// === Slice

static void CBLDart_FLSliceResultFinalizer(void *dart_callback_data,
                                           void *peer) {
  auto slice = reinterpret_cast<FLSliceResult *>(peer);
  FLSliceResult_Release(*slice);
  delete slice;
}

void CBLDart_FLSliceResult_BindToDartObject(Dart_Handle object,
                                            FLSliceResult slice, bool retain) {
  auto _slice = new FLSliceResult;
  *_slice = slice;

  if (retain) {
    FLSliceResult_Retain(*_slice);
  }

  Dart_NewFinalizableHandle_DL(object, _slice, 0,
                               CBLDart_FLSliceResultFinalizer);
}

void CBLDart_FLSliceResult_Retain(FLSliceResult slice) {
  FLSliceResult_Retain(slice);
}

void CBLDart_FLSliceResult_Release(FLSliceResult slice) {
  FLSliceResult_Release(slice);
}

// === Doc

static void CBLDart_FLDocFinalizer(void *dart_callback_data, void *peer) {
  auto doc = reinterpret_cast<FLDoc>(peer);
  FLDoc_Release(doc);
}

void CBLDart_FLDoc_BindToDartObject(Dart_Handle object, FLDoc doc) {
  Dart_NewFinalizableHandle_DL(object, doc, 0, CBLDart_FLDocFinalizer);
}

// === Value

static void CBLDart_FLValueFinalizer(void *dart_callback_data, void *peer) {
  auto value = reinterpret_cast<FLValue>(peer);
  FLValue_Release(value);
}

void CBLDart_FLValue_BindToDartObject(Dart_Handle object, FLValue value,
                                      bool retain) {
  if (retain) FLValue_Retain(value);

  Dart_NewFinalizableHandle_DL(object, (void *)value, 0,
                               CBLDart_FLValueFinalizer);
}

// === Decoder ================================================================

void CBLDart_FLValue_FromData(FLSlice data, uint8_t trust,
                              CBLDart_LoadedFLValue *out) {
  auto value = FLValue_FromData(data, static_cast<FLTrust>(trust));
  CBLDart_GetLoadedFLValue(value, out);
}

void CBLDart_GetLoadedFLValue(FLValue value, CBLDart_LoadedFLValue *out) {
  if (value) {
    out->exists = true;
  } else {
    out->exists = false;
    return;
  }

  auto type = FLValue_GetType(value);
  out->type = type;

  switch (type) {
    case kFLUndefined:
    case kFLNull:
      break;
    case kFLBoolean: {
      out->asBool = FLValue_AsBool(value);
      break;
    }
    case kFLNumber: {
      auto isInteger = FLValue_IsInteger(value);
      out->isInteger = isInteger;
      if (isInteger) {
        out->asInt = FLValue_AsInt(value);
      } else {
        out->asDouble = FLValue_AsDouble(value);
      }
      break;
    }
    case kFLString: {
      out->asString = FLValue_AsString(value);
      out->asValue = value;
      break;
    }
    case kFLData: {
      out->asData = FLValue_AsData(value);
      out->asValue = value;
      break;
    }
    case kFLArray: {
      out->collectionSize = FLArray_Count((FLArray)value);
      out->asValue = value;
      break;
    }
    case kFLDict: {
      out->collectionSize = FLDict_Count((FLDict)value);
      out->asValue = value;
      break;
    }
  }
}

void CBLDart_FLArray_GetLoadedFLValue(FLArray array, uint32_t index,
                                      CBLDart_LoadedFLValue *out) {
  auto value = FLArray_Get(array, index);
  CBLDart_GetLoadedFLValue(value, out);
}

void CBLDart_FLDict_GetLoadedFLValue(FLDict dict, FLString key,
                                     CBLDart_LoadedFLValue *out) {
  CBLDart_GetLoadedFLValue(FLDict_Get(dict, key), out);
}

static void CBLDart_DictIteratorFinalizer(void *dart_callback_data,
                                          void *peer) {
  auto iterator = reinterpret_cast<CBLDart_FLDictIterator *>(peer);

  if (!iterator->_isDone) FLDictIterator_End(&iterator->_iterator);

  delete iterator;
}

CBLDart_FLDictIterator *CBLDart_FLDictIterator_Begin(
    Dart_Handle object, FLDict dict, FLString *keyOut,
    CBLDart_LoadedFLValue *valueOut, bool finalize) {
  auto iterator = new CBLDart_FLDictIterator;
  iterator->_isDone = false;
  iterator->_keyOut = keyOut;
  iterator->_valueOut = valueOut;
  iterator->_objectHandle = finalize ? Dart_NewFinalizableHandle_DL(
                                           object, iterator, sizeof(iterator),
                                           CBLDart_DictIteratorFinalizer)
                                     : nullptr;

  FLDictIterator_Begin(dict, &iterator->_iterator);

  return iterator;
}

bool CBLDart_FLDictIterator_Next(CBLDart_FLDictIterator *iterator) {
  auto dictIterator = &iterator->_iterator;
  auto value = FLDictIterator_GetValue(dictIterator);
  iterator->_isDone = value == nullptr;
  if (value) {
    auto keyOut = iterator->_keyOut;
    if (keyOut) {
      *keyOut = FLDictIterator_GetKeyString(dictIterator);
    }

    auto valueOut = iterator->_valueOut;
    if (valueOut) CBLDart_GetLoadedFLValue(value, valueOut);

    FLDictIterator_Next(dictIterator);

    return true;
  }

  if (!iterator->_objectHandle) {
    delete iterator;
  }

  return false;
}

static void CBLDart_ArrayIteratorFinalizer(void *dart_callback_data,
                                           void *peer) {
  auto iterator = reinterpret_cast<CBLDart_FLArrayIterator *>(peer);

  delete iterator;
}

CBLDart_FLArrayIterator *CBLDart_FLArrayIterator_Begin(
    Dart_Handle object, FLArray array, CBLDart_LoadedFLValue *valueOut,
    bool finalize) {
  auto iterator = new CBLDart_FLArrayIterator;
  iterator->_valueOut = valueOut;
  iterator->_objectHandle = finalize ? Dart_NewFinalizableHandle_DL(
                                           object, iterator, sizeof(iterator),
                                           CBLDart_ArrayIteratorFinalizer)
                                     : nullptr;

  FLArrayIterator_Begin(array, &iterator->_iterator);

  return iterator;
}

bool CBLDart_FLArrayIterator_Next(CBLDart_FLArrayIterator *iterator) {
  auto arrayIterator = &iterator->_iterator;
  auto value = FLArrayIterator_GetValue(arrayIterator);
  if (value) {
    auto valueOut = iterator->_valueOut;
    if (valueOut) CBLDart_GetLoadedFLValue(value, valueOut);

    FLArrayIterator_Next(arrayIterator);

    return true;
  }

  if (!iterator->_objectHandle) {
    delete iterator;
  }

  return false;
}

// === Encoder ================================================================

static void CBLDart_FLEncoderFinalizer(void *dart_callback_data, void *peer) {
  auto encoder = reinterpret_cast<FLEncoder>(peer);
  FLEncoder_Free(encoder);
}

void CBLDart_FLEncoder_BindToDartObject(Dart_Handle object, FLEncoder encoder) {
  Dart_NewFinalizableHandle_DL(object, encoder, 0, CBLDart_FLEncoderFinalizer);
}

bool CBLDart_FLEncoder_WriteArrayValue(FLEncoder encoder, FLArray array,
                                       uint32_t index) {
  return FLEncoder_WriteValue(encoder, FLArray_Get(array, index));
}
