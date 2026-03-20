#pragma once

#include "CBLDart_Export.h"
#include "dart/dart_api_dl.h"
#ifdef CBL_FRAMEWORK_HEADERS
#include <CouchbaseLite/FLExpert.h>
#include <CouchbaseLite/Fleece.h>
#else
#include "fleece/FLExpert.h"
#include "fleece/Fleece.h"
#endif

// Helper to construct FLSlice from (buf, size) pair.
#define FLSLICE_FROM_ARGS(buf, size) ((FLSlice){(buf), (size)})

// === Slice ==================================================================

CBLDART_EXPORT
void CBLDart_FLSliceResult_RetainByBuf(void* buf);

CBLDART_EXPORT
void CBLDart_FLSliceResult_ReleaseByBuf(void* buf);

CBLDART_EXPORT
bool CBLDart_FLSlice_Equal(const void* aBuf, size_t aSize, const void* bBuf,
                           size_t bSize);

CBLDART_EXPORT
int CBLDart_FLSlice_Compare(const void* aBuf, size_t aSize, const void* bBuf,
                            size_t bSize);

CBLDART_EXPORT
FLSliceResult CBLDart_FLSlice_Copy(const void* buf, size_t size);

// === Data ===================================================================

CBLDART_EXPORT
FLStringResult CBLDart_FLData_Dump(const void* dataBuf, size_t dataSize);

// === Value ==================================================================

CBLDART_EXPORT
FLValue CBLDart_FLValue_FromData(const void* buf, size_t size, int trust);

// === Doc ====================================================================

CBLDART_EXPORT
FLDoc CBLDart_FLDoc_FromResultData(const void* dataBuf, size_t dataSize,
                                   int trust, FLSharedKeys sharedKeys,
                                   const void* externBuf, size_t externSize);

CBLDART_EXPORT
FLDoc CBLDart_FLDoc_FromJSON(const void* jsonBuf, size_t jsonSize,
                             FLError* outError);

// === Dict ===================================================================

CBLDART_EXPORT
FLValue CBLDart_FLDict_Get(FLDict dict, const void* keyBuf, size_t keySize);

CBLDART_EXPORT
FLDictKey CBLDart_FLDictKey_Init(const void* keyBuf, size_t keySize);

// === MutableDict ============================================================

CBLDART_EXPORT
FLSlot CBLDart_FLMutableDict_Set(FLMutableDict dict, const void* keyBuf,
                                 size_t keySize);

CBLDART_EXPORT
void CBLDart_FLMutableDict_Remove(FLMutableDict dict, const void* keyBuf,
                                  size_t keySize);

CBLDART_EXPORT
FLMutableArray CBLDart_FLMutableDict_GetMutableArray(FLMutableDict dict,
                                                     const void* keyBuf,
                                                     size_t keySize);

CBLDART_EXPORT
FLMutableDict CBLDart_FLMutableDict_GetMutableDict(FLMutableDict dict,
                                                   const void* keyBuf,
                                                   size_t keySize);

// === Slot ===================================================================

CBLDART_EXPORT
void CBLDart_FLSlot_SetString(FLSlot slot, const void* valueBuf,
                              size_t valueSize);

CBLDART_EXPORT
void CBLDart_FLSlot_SetData(FLSlot slot, const void* dataBuf, size_t dataSize);

// === Decoder ================================================================

// An object which remembers which shared keys have been seen. This is used
// to avoid decoding the same shared key multiple times.
struct KnownSharedKeys;

CBLDART_EXPORT
KnownSharedKeys* CBLDart_KnownSharedKeys_New();

CBLDART_EXPORT
void CBLDart_KnownSharedKeys_Delete(KnownSharedKeys* keys);

struct CBLDart_LoadedDictKey {
  bool isKnownSharedKey;  // Whether the key has been seen before. For shared
                          // keys, stringBuf and stringSize are only set the
                          // first time the key is seen.
  int sharedKey;  // The id of the shared key or -1 if the key is not shared.
  const void* stringBuf;  // The pointer to the start of the key string.
  size_t stringSize;      // The length of the key string.
  FLValue value;          // The Fleece value of the key.
};

struct CBLDart_LoadedFLValue {
  bool exists;
  int8_t type;
  bool isInteger;
  uint32_t collectionSize;
  bool asBool;
  int64_t asInt;
  double asDouble;
  const void* stringBuf;
  size_t stringSize;
  FLSlice asData;
  FLValue value;
};

CBLDART_EXPORT
void CBLDart_GetLoadedFLValue(FLValue value, CBLDart_LoadedFLValue* out);

CBLDART_EXPORT
void CBLDart_FLArray_GetLoadedFLValue(FLArray array, uint32_t index,
                                      CBLDart_LoadedFLValue* out);

CBLDART_EXPORT
void CBLDart_FLDict_GetLoadedFLValue(FLDict dict, const void* keyBuf,
                                     size_t keySize,
                                     CBLDart_LoadedFLValue* out);

struct CBLDart_FLDictIterator;

CBLDART_EXPORT
CBLDart_FLDictIterator* CBLDart_FLDictIterator_Begin(
    FLDict dict, KnownSharedKeys* knownSharedKeys,
    CBLDart_LoadedDictKey* keyOut, CBLDart_LoadedFLValue* valueOut,
    bool deleteOnDone, bool preLoad);

CBLDART_EXPORT
void CBLDart_FLDictIterator_Delete(CBLDart_FLDictIterator* iterator);

CBLDART_EXPORT
bool CBLDart_FLDictIterator_Next(CBLDart_FLDictIterator* iterator);

struct CBLDart_FLArrayIterator;

CBLDART_EXPORT
CBLDart_FLArrayIterator* CBLDart_FLArrayIterator_Begin(
    FLArray array, CBLDart_LoadedFLValue* valueOut, bool deleteOnDone);

CBLDART_EXPORT
void CBLDart_FLArrayIterator_Delete(CBLDart_FLArrayIterator* iterator);

CBLDART_EXPORT
bool CBLDart_FLArrayIterator_Next(CBLDart_FLArrayIterator* iterator);

// === Encoder ================================================================

CBLDART_EXPORT
bool CBLDart_FLEncoder_WriteArrayValue(FLEncoder encoder, FLArray array,
                                       uint32_t index);

CBLDART_EXPORT
bool CBLDart_FLEncoder_WriteString(FLEncoder encoder, const void* strBuf,
                                   size_t strSize);

CBLDART_EXPORT
bool CBLDart_FLEncoder_WriteKey(FLEncoder encoder, const void* keyBuf,
                                size_t keySize);

CBLDART_EXPORT
bool CBLDart_FLEncoder_WriteData(FLEncoder encoder, const void* dataBuf,
                                 size_t dataSize);

CBLDART_EXPORT
bool CBLDart_FLEncoder_ConvertJSON(FLEncoder encoder, const void* jsonBuf,
                                   size_t jsonSize);
