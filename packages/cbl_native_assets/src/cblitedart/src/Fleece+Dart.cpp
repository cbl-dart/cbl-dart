#include <bitset>

#include "Fleece+Dart.h"
#include "Utils.h"

// === Fleece =================================================================

// === Slice

void CBLDart_FLSliceResult_RetainByBuf(void *buf) {
  FLSliceResult_Retain({buf, 0});
}

void CBLDart_FLSliceResult_ReleaseByBuf(void *buf) {
  FLSliceResult_Release({buf, 0});
}

// === Decoder ================================================================

static const size_t kMaxSharedKeys = 2048;

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

  std::bitset<kMaxSharedKeys> _knownKeys;
};

KnownSharedKeys *CBLDart_KnownSharedKeys_New() { return new KnownSharedKeys; }

void CBLDart_KnownSharedKeys_Delete(KnownSharedKeys *keys) { delete keys; }

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
  bool _deleteOnDone;
};

CBLDart_FLDictIterator *CBLDart_FLDictIterator_Begin(
    FLDict dict, KnownSharedKeys *knownSharedKeys,
    CBLDart_LoadedDictKey *keyOut, CBLDart_LoadedFLValue *valueOut,
    bool deleteOnDone, bool preLoad) {
  auto iterator = new CBLDart_FLDictIterator{};
  iterator->_keyOut = keyOut;
  iterator->_valueOut = valueOut;
  iterator->_knownSharedKeys = knownSharedKeys;
  iterator->_preLoad = preLoad;
  iterator->_isDone = false;
  iterator->_deleteOnDone = deleteOnDone;

  FLDictIterator_Begin(dict, &iterator->_iterator);

  return iterator;
}

void CBLDart_FLDictIterator_Delete(CBLDart_FLDictIterator *iterator) {
  delete iterator;
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

  if (iterator->_deleteOnDone) {
    delete iterator;
  }

  return false;
}

struct CBLDart_FLArrayIterator {
  CBLDart_LoadedFLValue *_valueOut;
  FLArrayIterator _iterator;
  bool _deleteOnDone;
};

CBLDart_FLArrayIterator *CBLDart_FLArrayIterator_Begin(
    FLArray array, CBLDart_LoadedFLValue *valueOut, bool deleteOnDone) {
  auto iterator = new CBLDart_FLArrayIterator{};
  iterator->_valueOut = valueOut;
  iterator->_deleteOnDone = deleteOnDone;

  FLArrayIterator_Begin(array, &iterator->_iterator);

  return iterator;
}

void CBLDart_FLArrayIterator_Delete(CBLDart_FLArrayIterator *iterator) {
  delete iterator;
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

  if (iterator->_deleteOnDone) {
    delete iterator;
  }

  return false;
}

// === Encoder ================================================================

bool CBLDart_FLEncoder_WriteArrayValue(FLEncoder encoder, FLArray array,
                                       uint32_t index) {
  return FLEncoder_WriteValue(encoder, FLArray_Get(array, index));
}
