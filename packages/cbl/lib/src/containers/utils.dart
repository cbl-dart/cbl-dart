import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../blob.dart';
import '../fleece.dart' show globalSlice;
import 'array.dart';
import 'dictionary.dart';

late final valueBinds = CBLBindings.instance.fleece.value;
late final arrayBinds = CBLBindings.instance.fleece.array;
late final dictBinds = CBLBindings.instance.fleece.dict;
late final mutArrayBinds = CBLBindings.instance.fleece.mutableArray;
late final mutDictBinds = CBLBindings.instance.fleece.mutableDict;
late final slotBinds = CBLBindings.instance.fleece.slot;
late final dictIterBinds = CBLBindings.instance.fleece.dictIterator;

extension FLValueExt on Pointer<FLValue> {
  ValueType get type => valueBinds.getType(this).toFleeceValueType();

  Object? get value {
    // TODO recognize Blobs
    switch (type) {
      case ValueType.Null:
        return null;
      case ValueType.string:
        return string;
      case ValueType.number:
        return number!;
      case ValueType.boolean:
        return boolean;
      case ValueType.array:
        return getArray();
      case ValueType.dict:
        return getDictionary();

      case ValueType.undefined:
      case ValueType.data:
        throw UnsupportedError('$type is not supported');
    }
  }

  String? get string {
    valueBinds.asString(this, globalSlice);
    return globalSlice.ref.toDartString();
  }

  int get intNumber => valueBinds.asInt(this);

  double get doubleNumber => valueBinds.asDouble(this);

  num? get number {
    if (valueBinds.isDouble(this).toBool()) {
      return valueBinds.asInt(this);
    }
    if (valueBinds.isInteger(this).toBool()) {
      return valueBinds.asDouble(this);
    }
  }

  bool get boolean => valueBinds.asBool(this).toBool();

  DateTime? get date {
    final value = string;
    value == null ? null : DateTime.tryParse(value);
  }

  Blob? get blob => throw UnimplementedError();

  Array? get array {
    switch (type) {
      case ValueType.array:
        return getArray();
      default:
        return null;
    }
  }

  Dictionary? get dictionary {
    switch (type) {
      case ValueType.array:
        return getDictionary();
      default:
        return null;
    }
  }

  Array getArray() {
    final value = cast<FLArray>();
    final mutableValue = CBLBindings.instance.fleece.array.asMutable(value);
    return mutableValue == nullptr
        ? ArrayImpl.fromPointer(value)
        : MutableArrayImpl.fromPointer(mutableValue);
  }

  Dictionary getDictionary() {
    final value = cast<FLDict>();
    final mutableValue = CBLBindings.instance.fleece.dict.asMutable(value);
    return mutableValue == nullptr
        ? DictionaryImpl.fromPointer(value)
        : MutableDictionaryImpl.fromPointer(mutableValue);
  }
}

extension FLSlotExt on Pointer<FLSlot> {
  set value(Object? value) {
    if (value == null) {
      setNull();
    } else if (value is String) {
      string = value;
    } else if (value is num) {
      number = value;
    } else if (value is bool) {
      boolean = value;
    } else if (value is DateTime) {
      date = value;
    } else if (value is Blob) {
      blob = value;
    } else if (value is Iterable) {
      array = MutableArray(value.cast());
    } else if (value is Map) {
      dictionary = MutableDictionary(value.cast());
    } else if (value is Array) {
      array = value;
    } else if (value is Dictionary) {
      dictionary = value;
    } else {
      throw ArgumentError.value(value, 'value', 'type is not supported');
    }
  }

  void setNull() {
    slotBinds.setNull(this);
  }

  set string(String? value) {
    if (value == null) {
      setNull();
    } else {
      runArena(() {
        slotBinds.setString(this, value.toNativeUtf8().withScoped());
      });
    }
  }

  set intNum(int value) {
    slotBinds.setInt(this, value);
  }

  set doubleNum(double value) {
    slotBinds.setDouble(this, value);
  }

  set number(num? value) {
    if (value == null) {
      setNull();
    } else if (value is int) {
      intNum = value;
    } else if (value is double) {
      doubleNum = value;
    }
  }

  set boolean(bool value) {
    slotBinds.setBool(this, value.toInt());
  }

  set date(DateTime? value) {
    if (value == null) {
      setNull();
    } else {
      string = value.toIso8601String();
    }
  }

  set blob(Blob? value) {
    if (value == null) {
      setNull();
    } else {
      throw UnimplementedError();
    }
  }

  set array(Array? value) {
    if (value == null) {
      setNull();
    } else {
      slotBinds.setValue(this, (value as ArrayImpl).pointer.cast());
    }
  }

  set dictionary(Dictionary? value) {
    if (value == null) {
      setNull();
    } else {
      slotBinds.setValue(this, (value as DictionaryImpl).pointer.cast());
    }
  }
}

Object? convertContainersToPrimitives(Object? value) {
  if (value is Array) return value.toList();
  if (value is Dictionary) return value.toMap();
  return value;
}
