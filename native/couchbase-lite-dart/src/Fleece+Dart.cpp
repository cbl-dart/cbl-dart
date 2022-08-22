#include <bitset>

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

  Dart_NewFinalizableHandle_DL(object, _slice, slice.size,
                               CBLDart_FLSliceResultFinalizer);
}

void CBLDart_FLSliceResult_Retain(FLSliceResult slice) {
  FLSliceResult_Retain(slice);
}

void CBLDart_FLSliceResult_Release(FLSliceResult slice) {
  FLSliceResult_Release(slice);
}

// === SharedKeys

static void CBLDart_FLSharedKeysFinalizer(void *dart_callback_data,
                                          void *peer) {
  auto sharedKeys = reinterpret_cast<FLSharedKeys>(peer);
  FLSharedKeys_Release(sharedKeys);
}

void CBLDart_FLSharedKeys_BindToDartObject(Dart_Handle object,
                                           FLSharedKeys sharedKeys,
                                           bool retain) {
  if (retain) {
    FLSharedKeys_Retain(sharedKeys);
  }
  Dart_NewFinalizableHandle_DL(object, sharedKeys,
                               CBLDart_kFakeExternalAllocationSize,
                               CBLDart_FLSharedKeysFinalizer);
}

// === Doc

static void CBLDart_FLDocFinalizer(void *dart_callback_data, void *peer) {
  auto doc = reinterpret_cast<FLDoc>(peer);
  FLDoc_Release(doc);
}

void CBLDart_FLDoc_BindToDartObject(Dart_Handle object, FLDoc doc) {
  auto allocedData = FLDoc_GetAllocedData(doc);
  Dart_NewFinalizableHandle_DL(object, doc, allocedData.size,
                               CBLDart_FLDocFinalizer);
  FLSliceResult_Release(allocedData);
}

// === Value

static void CBLDart_FLValueFinalizer(void *dart_callback_data, void *peer) {
  auto value = reinterpret_cast<FLValue>(peer);
  FLValue_Release(value);
}

void CBLDart_FLValue_BindToDartObject(Dart_Handle object, FLValue value,
                                      bool retain) {
  if (retain) FLValue_Retain(value);

  Dart_NewFinalizableHandle_DL(object, (void *)value,
                               CBLDart_kFakeExternalAllocationSize,
                               CBLDart_FLValueFinalizer);
}

// === Decoder ================================================================

struct KnownSharedKeys {
  /**
   * Marks the give key as known, if it wasn't already.
   *
   * Returns true if the key was previously unknown.
   */
  bool makeKeyKnown(int key) {
    if (_knownKeys[key]) {
      return false;
    } else {
      _knownKeys[key] = true;
      return true;
    }
  };

  std::bitset<2048> _knownKeys;
};

static void CBLDart_KnownSharedKeysFinalizer(void *dart_callback_data,
                                             void *peer) {
  auto keys = reinterpret_cast<KnownSharedKeys *>(peer);
  delete keys;
}

KnownSharedKeys *CBLDart_KnownSharedKeys_New(Dart_Handle object) {
  auto keys = new KnownSharedKeys;
  Dart_NewFinalizableHandle_DL(object, keys, sizeof(KnownSharedKeys),
                               CBLDart_KnownSharedKeysFinalizer);
  return keys;
}

static void CBLDart_GetLoadedDictKey(KnownSharedKeys *knownSharedKeys,
                                     FLDictIterator *iterator,
                                     CBLDart_LoadedDictKey *out) {
  auto key = out->value = FLDictIterator_GetKey(iterator);

  FLString string;

  if (knownSharedKeys) {
    if (FLValue_IsInteger(key)) {
      auto sharedKey = out->sharedKey = static_cast<int>(FLValue_AsInt(key));
      if (knownSharedKeys->makeKeyKnown(sharedKey)) {
        out->isKnownSharedKey = false;
        string = FLDictIterator_GetKeyString(iterator);
      } else {
        out->isKnownSharedKey = true;
        return;
      }
    } else {
      out->sharedKey = -1;
      string = FLValue_AsString(key);
    }
  } else {
    out->sharedKey = -1;
    string = FLDictIterator_GetKeyString(iterator);
  }

  out->stringBuf = string.buf;
  out->stringSize = string.size;
}

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
      auto string = FLValue_AsString(value);
      out->stringBuf = string.buf;
      out->stringSize = string.size;
      break;
    }
    case kFLData: {
      out->asData = FLValue_AsData(value);
      break;
    }
    case kFLArray: {
      out->collectionSize = FLArray_Count((FLArray)value);
      out->value = value;
      break;
    }
    case kFLDict: {
      out->collectionSize = FLDict_Count((FLDict)value);
      out->value = value;
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

struct CBLDart_FLDictIterator {
  CBLDart_LoadedDictKey *_keyOut;
  CBLDart_LoadedFLValue *_valueOut;
  KnownSharedKeys *_knownSharedKeys;
  bool _preLoad;
  FLDictIterator _iterator;
  bool _isDone;
  Dart_FinalizableHandle _objectHandle;
};

static void CBLDart_DictIteratorFinalizer(void *dart_callback_data,
                                          void *peer) {
  auto iterator = reinterpret_cast<CBLDart_FLDictIterator *>(peer);

  if (!iterator->_isDone) FLDictIterator_End(&iterator->_iterator);

  delete iterator;
}

CBLDart_FLDictIterator *CBLDart_FLDictIterator_Begin(
    Dart_Handle object, FLDict dict, KnownSharedKeys *knownSharedKeys,
    CBLDart_LoadedDictKey *keyOut, CBLDart_LoadedFLValue *valueOut,
    bool finalize, bool preLoad) {
  auto iterator = new CBLDart_FLDictIterator;
  iterator->_keyOut = keyOut;
  iterator->_valueOut = valueOut;
  iterator->_knownSharedKeys = knownSharedKeys;
  iterator->_preLoad = preLoad;
  iterator->_isDone = false;
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
      CBLDart_GetLoadedDictKey(iterator->_knownSharedKeys, dictIterator,
                               keyOut);
    }

    auto valueOut = iterator->_valueOut;
    if (valueOut) {
      if (iterator->_preLoad) {
        CBLDart_GetLoadedFLValue(value, valueOut);
      } else {
        valueOut->value = value;
      }
    }

    FLDictIterator_Next(dictIterator);

    return true;
  }

  if (!iterator->_objectHandle) {
    delete iterator;
  }

  return false;
}

struct CBLDart_FLArrayIterator {
  CBLDart_LoadedFLValue *_valueOut;
  FLArrayIterator _iterator;
  Dart_FinalizableHandle _objectHandle;
};

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
  Dart_NewFinalizableHandle_DL(object, encoder,
                               CBLDart_kFakeExternalAllocationSize,
                               CBLDart_FLEncoderFinalizer);
}

bool CBLDart_FLEncoder_WriteArrayValue(FLEncoder encoder, FLArray array,
                                       uint32_t index) {
  return FLEncoder_WriteValue(encoder, FLArray_Get(array, index));
}
