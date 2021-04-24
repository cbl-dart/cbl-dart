#include "Utils.hh"

int64_t CBLDart_CObject_getIntValueAsInt64(Dart_CObject *object) {
  assert(object->type == Dart_CObject_kInt64 ||
         object->type == Dart_CObject_kInt32);
  return object->type == Dart_CObject_kInt64 ? object->value.as_int64
                                             : object->value.as_int32;
}
