#include "Utils.h"

// === Dart Native ============================================================

int64_t CBLDart_CObject_getIntValueAsInt64(Dart_CObject* object) {
  assert(object->type == Dart_CObject_kInt64 ||
         object->type == Dart_CObject_kInt32);
  return object->type == Dart_CObject_kInt64 ? object->value.as_int64
                                             : object->value.as_int32;
}

void CBLDart_CObject_SetEmptyArray(Dart_CObject* object) {
  object->type = Dart_CObject_kArray;
  object->value.as_array.length = 0;
  object->value.as_array.values = NULL;
}

void CBLDart_CObject_SetPointer(Dart_CObject* object, const void* pointer) {
  if (pointer) {
    object->type = Dart_CObject_kInt64;
    object->value.as_int64 = reinterpret_cast<int64_t>(pointer);
  } else {
    object->type = Dart_CObject_kNull;
  }
}

void CBLDart_CObject_SetFLString(Dart_CObject* object, const FLString string) {
  if (string.buf) {
    object->type = Dart_CObject_kTypedData;
    object->value.as_typed_data.type = Dart_TypedData_kUint8;
    object->value.as_typed_data.values = (uint8_t*)string.buf;
    object->value.as_typed_data.length = string.size;
  } else {
    object->type = Dart_CObject_kNull;
  }
}

// === Fleece =================================================================

FLSlice CBLDart_FLSliceFromDart(CBLDart_FLSlice slice) {
  return {slice.buf, static_cast<size_t>(slice.size)};
}

CBLDart_FLSlice CBLDart_FLSliceToDart(FLSlice slice) {
  return {slice.buf, slice.size};
}

FLSliceResult CBLDart_FLSliceResultFromDart(CBLDart_FLSliceResult slice) {
  return {slice.buf, static_cast<size_t>(slice.size)};
}

CBLDart_FLSliceResult CBLDart_FLSliceResultToDart(FLSliceResult slice) {
  return {slice.buf, slice.size};
}

FLString CBLDart_FLStringFromDart(CBLDart_FLString slice) {
  return {slice.buf, static_cast<size_t>(slice.size)};
}

CBLDart_FLString CBLDart_FLStringToDart(FLString slice) {
  return {slice.buf, slice.size};
}

FLStringResult CBLDart_FLStringResultFromDart(CBLDart_FLStringResult slice) {
  return {slice.buf, static_cast<size_t>(slice.size)};
}

CBLDart_FLStringResult CBLDart_FLStringResultToDart(FLStringResult slice) {
  return {slice.buf, slice.size};
}

std::string CBLDart_FLStringToString(FLString slice) {
  return std::string((char*)slice.buf, slice.size);
}