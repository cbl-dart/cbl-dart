// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_positional_boolean_parameters, avoid_private_typedef_functions, camel_case_types

import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'data.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

// === Common ==================================================================

enum FLCopyFlag implements Option {
  deepCopy(0),
  copyImmutables(1);

  const FLCopyFlag(this.bit);

  @override
  final int bit;
}

// === Error ===================================================================

enum FLErrorCode {
  noError,
  memoryError,
  outOfRange,
  invalidData,
  encodeError,
  jsonError,
  unknownValue,
  internalError,
  notFound,
  sharedKeysStateError,
  posixError,
  unsupported,
}

extension FLErrorCodeIntExt on int {
  FLErrorCode toFleeceErrorCode() {
    assert(this >= 0 && this <= 12);
    return FLErrorCode.values[this];
  }
}

void _checkFleeceError() {
  final code = globalFLErrorCode.value.toFleeceErrorCode();
  if (code != FLErrorCode.noError) {
    throw CBLErrorException(CBLErrorDomain.fleece, code, 'Fleece error');
  }
}

extension _FleeceErrorExt<T> on T {
  T checkFleeceError() {
    final self = this;
    if (this == nullptr || self is FLSliceResult && self.buf == nullptr) {
      _checkFleeceError();
    }
    return this;
  }
}

// === Slice ===================================================================

final class FLSlice extends Struct {
  external Pointer<Uint8> buf;

  @Size()
  external int size;
}

extension FLSliceExt on FLSlice {
  bool get isNull => buf == nullptr;
  Data? toData() => SliceResult.fromFLSlice(this)?.toData();
}

final class FLSliceResult extends Struct {
  external Pointer<Uint8> buf;

  @Size()
  external int size;
}

extension FLResultSliceExt on FLSliceResult {
  bool get isNull => buf == nullptr;
  Data? toData({bool retain = false}) =>
      SliceResult.fromFLSliceResult(this, retain: retain)?.toData();
}

final class FLString extends Struct {
  external Pointer<Uint8> buf;

  @Size()
  external int size;
}

extension FLStringExt on FLString {
  bool get isNull => buf == nullptr;
  String? toDartString() =>
      isNull ? null : buf.cast<Utf8>().toDartString(length: size);
}

final class FLStringResult extends Struct {
  external Pointer<Uint8> buf;

  @Size()
  external int size;
}

extension FLStringResultExt on FLStringResult {
  bool get isNull => buf == nullptr;
  String? toDartStringAndRelease({bool allowMalformed = false}) {
    if (isNull) {
      return null;
    }

    final result = utf8.decode(
      buf.cast<Uint8>().asTypedList(size),
      allowMalformed: allowMalformed,
    );

    CBLBindings.instance.fleece.slice.releaseSliceResultByBuf(buf);

    return result;
  }
}

typedef _FLSlice_Equal_C = Bool Function(FLSlice a, FLSlice b);
typedef _FLSlice_Equal = bool Function(FLSlice a, FLSlice b);

typedef _FLSlice_Compare_C = Int Function(FLSlice a, FLSlice b);
typedef _FLSlice_Compare = int Function(FLSlice a, FLSlice b);

typedef _FLSliceResult_New_C = FLSliceResult Function(Size size);
typedef _FLSliceResult_New = FLSliceResult Function(int size);

typedef _FLSlice_Copy_C = FLSliceResult Function(FLSlice slice);
typedef _FLSlice_Copy = FLSliceResult Function(FLSlice slice);

typedef _CBLDart_FLSliceResult_RetainByBuf_C = Void Function(
  Pointer<Uint8> buf,
);
typedef _CBLDart_FLSliceResult_RetainByBuf = void Function(
  Pointer<Uint8> buf,
);

typedef _CBLDart_FLSliceResult_ReleaseByBuf_C = Void Function(
  Pointer<Uint8> buf,
);
typedef _CBLDart_FLSliceResult_ReleaseByBuf = void Function(
  Pointer<Uint8> buf,
);

class SliceBindings extends Bindings {
  SliceBindings(super.parent) {
    _equal = libs.cbl.lookupFunction<_FLSlice_Equal_C, _FLSlice_Equal>(
      'FLSlice_Equal',
    );
    _compare = libs.cbl.lookupFunction<_FLSlice_Compare_C, _FLSlice_Compare>(
      'FLSlice_Compare',
    );
    _new = libs.cbl.lookupFunction<_FLSliceResult_New_C, _FLSliceResult_New>(
      'FLSliceResult_New',
    );
    _copy = libs.cbl.lookupFunction<_FLSlice_Copy_C, _FLSlice_Copy>(
      'FLSlice_Copy',
    );
    _retainSliceResultByBuf = libs.cblDart.lookupFunction<
        _CBLDart_FLSliceResult_RetainByBuf_C,
        _CBLDart_FLSliceResult_RetainByBuf>(
      'CBLDart_FLSliceResult_RetainByBuf',
    );
    _releaseSliceResultByBufPtr =
        libs.cblDart.lookup('CBLDart_FLSliceResult_ReleaseByBuf');
    _releaseSliceResultByBuf =
        _releaseSliceResultByBufPtr.asFunction(isLeaf: useIsLeaf);
  }

  late final _FLSlice_Equal _equal;
  late final _FLSlice_Compare _compare;

  late final _FLSliceResult_New _new;
  late final _FLSlice_Copy _copy;
  late final _CBLDart_FLSliceResult_RetainByBuf _retainSliceResultByBuf;
  late final Pointer<NativeFunction<_CBLDart_FLSliceResult_ReleaseByBuf_C>>
      _releaseSliceResultByBufPtr;
  late final _CBLDart_FLSliceResult_ReleaseByBuf _releaseSliceResultByBuf;

  late final _sliceResultFinalizer =
      NativeFinalizer(_releaseSliceResultByBufPtr.cast());

  bool equal(FLSlice a, FLSlice b) => _equal(a, b);

  int compare(FLSlice a, FLSlice b) => _compare(a, b);

  FLSliceResult create(int size) => _new(size);

  FLSliceResult copy(FLSlice slice) => _copy(slice);

  void bindToDartObject(
    Finalizable object, {
    required Pointer<Uint8> buf,
    required bool retain,
  }) {
    if (retain) {
      _retainSliceResultByBuf(buf);
    }

    _sliceResultFinalizer.attach(object, buf.cast());
  }

  void retainSliceResultByBuf(Pointer<Uint8> buf) {
    _retainSliceResultByBuf(buf);
  }

  void releaseSliceResultByBuf(Pointer<Uint8> buf) {
    _releaseSliceResultByBuf(buf);
  }
}

// === SharedKeys ==============================================================

final class FLSharedKeys extends Opaque {}

typedef _FLSharedKeys_New = Pointer<FLSharedKeys> Function();

typedef _FLSharedKeys_Retain_C = Void Function(
  Pointer<FLSharedKeys> sharedKeys,
);
typedef _FLSharedKeys_Retain = void Function(
  Pointer<FLSharedKeys> sharedKeys,
);

typedef _FLSharedKeys_Release_C = Void Function(
  Pointer<FLSharedKeys> sharedKeys,
);

typedef _FLSharedKeys_Count_C = UnsignedInt Function(
  Pointer<FLSharedKeys> sharedKeys,
);
typedef _FLSharedKeys_Count = int Function(
  Pointer<FLSharedKeys> sharedKeys,
);

class SharedKeysBindings extends Bindings {
  SharedKeysBindings(super.parent) {
    _new = libs.cbl.lookupFunction<_FLSharedKeys_New, _FLSharedKeys_New>(
      'FLSharedKeys_New',
      isLeaf: useIsLeaf,
    );
    _retain =
        libs.cbl.lookupFunction<_FLSharedKeys_Retain_C, _FLSharedKeys_Retain>(
      'FLSharedKeys_Retain',
      isLeaf: useIsLeaf,
    );
    _releasePtr = libs.cbl.lookup('FLSharedKeys_Release');
    _count =
        libs.cbl.lookupFunction<_FLSharedKeys_Count_C, _FLSharedKeys_Count>(
      'FLSharedKeys_Count',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLSharedKeys_New _new;
  late final _FLSharedKeys_Retain _retain;
  late final Pointer<NativeFunction<_FLSharedKeys_Release_C>> _releasePtr;
  late final _FLSharedKeys_Count _count;

  late final _finalizer = NativeFinalizer(_releasePtr.cast());

  Pointer<FLSharedKeys> create() => _new();

  void bindToDartObject(
    Finalizable object,
    Pointer<FLSharedKeys> sharedKeys, {
    required bool retain,
  }) {
    if (retain) {
      _retain(sharedKeys);
    }

    _finalizer.attach(object, sharedKeys.cast());
  }

  int count(Pointer<FLSharedKeys> sharedKeys) => _count(sharedKeys);
}

// === Slot ====================================================================

final class FLSlot extends Opaque {}

typedef _FLSlot_SetNull_C = Void Function(Pointer<FLSlot> slot);
typedef _FLSlot_SetNull = void Function(Pointer<FLSlot> slot);

typedef _FLSlot_SetBool_C = Void Function(Pointer<FLSlot> slot, Bool value);
typedef _FLSlot_SetBool = void Function(Pointer<FLSlot> slot, bool value);

typedef _FLSlot_SetInt_C = Void Function(Pointer<FLSlot> slot, Int64 value);
typedef _FLSlot_SetInt = void Function(Pointer<FLSlot> slot, int value);

typedef _FLSlot_SetDouble_C = Void Function(Pointer<FLSlot> slot, Double value);
typedef _FLSlot_SetDouble = void Function(Pointer<FLSlot> slot, double value);

typedef _FLSlot_SetString_C = Void Function(
  Pointer<FLSlot> slot,
  FLString value,
);
typedef _FLSlot_SetString = void Function(
  Pointer<FLSlot> slot,
  FLString value,
);

typedef _FLSlot_SetData_C = Void Function(
  Pointer<FLSlot> slot,
  FLSlice value,
);
typedef _FLSlot_SetData = void Function(
  Pointer<FLSlot> slot,
  FLSlice value,
);

typedef _FLSlot_SetValue_C = Void Function(
  Pointer<FLSlot> slot,
  Pointer<FLValue> value,
);
typedef _FLSlot_SetValue = void Function(
  Pointer<FLSlot> slot,
  Pointer<FLValue> value,
);

class SlotBindings extends Bindings {
  SlotBindings(super.parent) {
    _setNull = libs.cbl.lookupFunction<_FLSlot_SetNull_C, _FLSlot_SetNull>(
      'FLSlot_SetNull',
      isLeaf: useIsLeaf,
    );
    _setBool = libs.cbl.lookupFunction<_FLSlot_SetBool_C, _FLSlot_SetBool>(
      'FLSlot_SetBool',
      isLeaf: useIsLeaf,
    );
    _setInt = libs.cbl.lookupFunction<_FLSlot_SetInt_C, _FLSlot_SetInt>(
      'FLSlot_SetInt',
      isLeaf: useIsLeaf,
    );
    _setDouble =
        libs.cbl.lookupFunction<_FLSlot_SetDouble_C, _FLSlot_SetDouble>(
      'FLSlot_SetDouble',
      isLeaf: useIsLeaf,
    );
    _setString =
        libs.cbl.lookupFunction<_FLSlot_SetString_C, _FLSlot_SetString>(
      'FLSlot_SetString',
      isLeaf: useIsLeaf,
    );
    _setData = libs.cbl.lookupFunction<_FLSlot_SetData_C, _FLSlot_SetData>(
      'FLSlot_SetData',
      isLeaf: useIsLeaf,
    );
    _setValue = libs.cbl.lookupFunction<_FLSlot_SetValue_C, _FLSlot_SetValue>(
      'FLSlot_SetValue',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLSlot_SetNull _setNull;
  late final _FLSlot_SetBool _setBool;
  late final _FLSlot_SetInt _setInt;
  late final _FLSlot_SetDouble _setDouble;
  late final _FLSlot_SetString _setString;
  late final _FLSlot_SetData _setData;
  late final _FLSlot_SetValue _setValue;

  void setNull(Pointer<FLSlot> slot) {
    _setNull(slot);
  }

  void setBool(Pointer<FLSlot> slot, bool value) {
    _setBool(slot, value);
  }

  void setInt(Pointer<FLSlot> slot, int value) {
    _setInt(slot, value);
  }

  void setDouble(Pointer<FLSlot> slot, double value) {
    _setDouble(slot, value);
  }

  void setString(Pointer<FLSlot> slot, String value) {
    runWithSingleFLString(value, (flValue) {
      _setString(slot, flValue);
    });
  }

  void setData(Pointer<FLSlot> slot, Data value) {
    _setData(slot, value.toSliceResult().makeGlobal().ref);
  }

  void setValue(Pointer<FLSlot> slot, Pointer<FLValue> value) {
    _setValue(slot, value);
  }
}

// === Doc =====================================================================

final class FLDoc extends Opaque {}

typedef _FLDoc_FromResultData_C = Pointer<FLDoc> Function(
  FLSliceResult data,
  Uint8 trust,
  Pointer<FLSharedKeys> sharedKeys,
  FLSlice externalData,
);
typedef _FLDoc_FromResultData = Pointer<FLDoc> Function(
  FLSliceResult data,
  int trust,
  Pointer<FLSharedKeys> sharedKeys,
  FLSlice externalData,
);

typedef _FLDoc_FromJSON = Pointer<FLDoc> Function(
  FLString json,
  Pointer<Uint32> errorOut,
);

typedef _FLDoc_Release_C = Void Function(Pointer<FLDoc> doc);

typedef _FLDoc_GetAllocedData = FLSliceResult Function(Pointer<FLDoc> doc);

typedef _FLDoc_GetRoot = Pointer<FLValue> Function(Pointer<FLDoc> doc);

typedef _FLDoc_GetSharedKeys = Pointer<FLSharedKeys> Function(
  Pointer<FLDoc> doc,
);

class DocBindings extends Bindings {
  DocBindings(super.parent) {
    _fromResultData =
        libs.cbl.lookupFunction<_FLDoc_FromResultData_C, _FLDoc_FromResultData>(
      'FLDoc_FromResultData',
      isLeaf: useIsLeaf,
    );
    _fromJSON = libs.cbl.lookupFunction<_FLDoc_FromJSON, _FLDoc_FromJSON>(
      'FLDoc_FromJSON',
      isLeaf: useIsLeaf,
    );
    _releasePtr = libs.cbl.lookup('FLDoc_Release');
    _getAllocedData =
        libs.cbl.lookupFunction<_FLDoc_GetAllocedData, _FLDoc_GetAllocedData>(
      'FLDoc_GetAllocedData',
      isLeaf: useIsLeaf,
    );
    _getRoot = libs.cbl.lookupFunction<_FLDoc_GetRoot, _FLDoc_GetRoot>(
      'FLDoc_GetRoot',
      isLeaf: useIsLeaf,
    );
    _getSharedKeys =
        libs.cbl.lookupFunction<_FLDoc_GetSharedKeys, _FLDoc_GetSharedKeys>(
      'FLDoc_GetSharedKeys',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLDoc_FromResultData _fromResultData;
  late final _FLDoc_FromJSON _fromJSON;
  late final Pointer<NativeFunction<_FLDoc_Release_C>> _releasePtr;
  late final _FLDoc_GetAllocedData _getAllocedData;
  late final _FLDoc_GetRoot _getRoot;
  late final _FLDoc_GetSharedKeys _getSharedKeys;

  late final _finalizer = NativeFinalizer(_releasePtr.cast());

  Pointer<FLDoc> fromResultData(
    Data data,
    FLTrust trust,
    Pointer<FLSharedKeys>? sharedKeys,
  ) {
    final sliceResult = data.toSliceResult();
    return _fromResultData(
      sliceResult.makeGlobalResult().ref,
      trust.toInt(),
      sharedKeys ?? nullptr,
      nullFLSlice.ref,
    );
  }

  Pointer<FLDoc> fromJson(String json) => runWithSingleFLString(
        json,
        (flJson) => _fromJSON(flJson, globalFLErrorCode).checkFleeceError(),
      );

  void bindToDartObject(Finalizable object, Pointer<FLDoc> doc) {
    _finalizer.attach(
      object,
      doc.cast(),
      externalSize: getAllocedData(doc)?.size,
    );
  }

  SliceResult? getAllocedData(Pointer<FLDoc> doc) =>
      SliceResult.fromFLSliceResult(_getAllocedData(doc));

  Pointer<FLValue> getRoot(Pointer<FLDoc> doc) => _getRoot(doc);

  Pointer<FLSharedKeys>? getSharedKeys(Pointer<FLDoc> doc) =>
      _getSharedKeys(doc).toNullable();
}

// === Value ===================================================================

final class FLValue extends Opaque {}

enum FLValueType {
  undefined,
  // ignore: constant_identifier_names
  null_,
  boolean,
  number,
  string,
  data,
  array,
  dict,
}

extension on int {
  FLValueType toFLValueType() {
    assert(this >= -1 && this <= 6);
    return FLValueType.values[this + 1];
  }
}

typedef _FLValue_FromData_C = Pointer<FLValue> Function(
  FLSlice data,
  Uint8 trust,
);
typedef _FLValue_FromData = Pointer<FLValue> Function(
  FLSlice data,
  int trust,
);

typedef _FLValue_FindDoc = Pointer<FLDoc> Function(Pointer<FLValue>);

typedef _FLValue_GetType_C = Int8 Function(Pointer<FLValue> value);
typedef _FLValue_GetType = int Function(Pointer<FLValue> value);

typedef _FLValue_IsInteger_C = Bool Function(Pointer<FLValue> value);
typedef _FLValue_IsInteger = bool Function(Pointer<FLValue> value);

typedef _FLValue_IsDouble_C = Bool Function(Pointer<FLValue> value);
typedef _FLValue_IsDouble = bool Function(Pointer<FLValue> value);

typedef _FLValue_AsBool_C = Bool Function(Pointer<FLValue> value);
typedef _FLValue_AsBool = bool Function(Pointer<FLValue> value);

typedef _FLValue_AsInt_C = Int64 Function(Pointer<FLValue> value);
typedef _FLValue_AsInt = int Function(Pointer<FLValue> value);

typedef _FLValue_AsDouble_C = Double Function(Pointer<FLValue> value);
typedef _FLValue_AsDouble = double Function(Pointer<FLValue> value);

typedef _FLValue_AsString_C = FLString Function(Pointer<FLValue> value);
typedef _FLValue_AsString = FLString Function(Pointer<FLValue> value);

typedef _FLValue_AsData_C = FLSlice Function(Pointer<FLValue> value);
typedef _FLValue_AsData = FLSlice Function(Pointer<FLValue> value);

typedef _FLValue_ToString_C = FLStringResult Function(
  Pointer<FLValue> value,
);
typedef _FLValue_ToString = FLStringResult Function(
  Pointer<FLValue> value,
);

typedef _FLValue_IsEqual_C = Bool Function(
  Pointer<FLValue> v1,
  Pointer<FLValue> v2,
);
typedef _FLValue_IsEqual = bool Function(
  Pointer<FLValue> v1,
  Pointer<FLValue> v2,
);

typedef _FLValue_Retain = Pointer<FLValue> Function(Pointer<FLValue> value);

typedef _FLValue_Release_C = Void Function(Pointer<FLValue> value);
typedef _FLValue_Release = void Function(Pointer<FLValue> value);

typedef _FLValue_ToJSONX_C = FLStringResult Function(
  Pointer<FLValue> value,
  Bool json5,
  Bool canonicalForm,
);
typedef _FLValue_ToJSONX = FLStringResult Function(
  Pointer<FLValue> value,
  bool json5,
  bool canonicalForm,
);

class ValueBindings extends Bindings {
  ValueBindings(super.parent) {
    _fromData = libs.cbl.lookupFunction<_FLValue_FromData_C, _FLValue_FromData>(
      'FLValue_FromData',
      isLeaf: useIsLeaf,
    );
    _findDoc = libs.cbl.lookupFunction<_FLValue_FindDoc, _FLValue_FindDoc>(
      'FLValue_FindDoc',
      isLeaf: useIsLeaf,
    );
    _getType = libs.cbl.lookupFunction<_FLValue_GetType_C, _FLValue_GetType>(
      'FLValue_GetType',
      isLeaf: useIsLeaf,
    );
    _isInteger =
        libs.cbl.lookupFunction<_FLValue_IsInteger_C, _FLValue_IsInteger>(
      'FLValue_IsInteger',
      isLeaf: useIsLeaf,
    );
    _isDouble = libs.cbl.lookupFunction<_FLValue_IsDouble_C, _FLValue_IsDouble>(
      'FLValue_IsDouble',
      isLeaf: useIsLeaf,
    );
    _asBool = libs.cbl.lookupFunction<_FLValue_AsBool_C, _FLValue_AsBool>(
      'FLValue_AsBool',
      isLeaf: useIsLeaf,
    );
    _asInt = libs.cbl.lookupFunction<_FLValue_AsInt_C, _FLValue_AsInt>(
      'FLValue_AsInt',
      isLeaf: useIsLeaf,
    );
    _asDouble = libs.cbl.lookupFunction<_FLValue_AsDouble_C, _FLValue_AsDouble>(
      'FLValue_AsDouble',
      isLeaf: useIsLeaf,
    );
    _asString = libs.cbl.lookupFunction<_FLValue_AsString_C, _FLValue_AsString>(
      'FLValue_AsString',
      isLeaf: useIsLeaf,
    );
    _asData = libs.cbl.lookupFunction<_FLValue_AsData_C, _FLValue_AsData>(
      'FLValue_AsData',
      isLeaf: useIsLeaf,
    );
    _scalarToString =
        libs.cbl.lookupFunction<_FLValue_ToString_C, _FLValue_ToString>(
      'FLValue_ToString',
      isLeaf: useIsLeaf,
    );
    _isEqual = libs.cbl.lookupFunction<_FLValue_IsEqual_C, _FLValue_IsEqual>(
      'FLValue_IsEqual',
      isLeaf: useIsLeaf,
    );
    _retain = libs.cbl.lookupFunction<_FLValue_Retain, _FLValue_Retain>(
      'FLValue_Retain',
      isLeaf: useIsLeaf,
    );
    _releasePtr = libs.cbl.lookup('FLValue_Release');
    _release = _releasePtr.asFunction(isLeaf: useIsLeaf);
    _toJson = libs.cbl.lookupFunction<_FLValue_ToJSONX_C, _FLValue_ToJSONX>(
      'FLValue_ToJSONX',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLValue_FromData _fromData;
  late final _FLValue_FindDoc _findDoc;
  late final _FLValue_GetType _getType;
  late final _FLValue_IsInteger _isInteger;
  late final _FLValue_IsDouble _isDouble;
  late final _FLValue_AsBool _asBool;
  late final _FLValue_AsInt _asInt;
  late final _FLValue_AsDouble _asDouble;
  late final _FLValue_AsString _asString;
  late final _FLValue_AsData _asData;
  late final _FLValue_ToString _scalarToString;
  late final _FLValue_IsEqual _isEqual;
  late final _FLValue_Retain _retain;
  late final Pointer<NativeFunction<_FLValue_Release_C>> _releasePtr;
  late final _FLValue_Release _release;
  late final _FLValue_ToJSONX _toJson;

  late final _finalizer = NativeFinalizer(_releasePtr.cast());

  void bindToDartObject(
    Finalizable object, {
    required Pointer<FLValue> value,
    required bool retain,
  }) {
    if (retain) {
      _retain(value);
    }
    _finalizer.attach(object, value.cast());
  }

  Pointer<FLValue>? fromData(SliceResult data, FLTrust trust) =>
      _fromData(data.makeGlobal().ref, trust.toInt()).toNullable();

  Pointer<FLDoc>? findDoc(Pointer<FLValue> value) =>
      _findDoc(value).toNullable();

  FLValueType getType(Pointer<FLValue> value) =>
      _getType(value).toFLValueType();

  bool isInteger(Pointer<FLValue> value) => _isInteger(value);

  bool isDouble(Pointer<FLValue> value) => _isDouble(value);

  bool asBool(Pointer<FLValue> value) => _asBool(value);

  int asInt(Pointer<FLValue> value) => _asInt(value);

  double asDouble(Pointer<FLValue> value) => _asDouble(value);

  String? asString(Pointer<FLValue> value) => _asString(value).toDartString();

  Data? asData(Pointer<FLValue> value) => _asData(value).toData();

  String? scalarToString(Pointer<FLValue> value) =>
      _scalarToString(value).toDartStringAndRelease();

  bool isEqual(Pointer<FLValue> a, Pointer<FLValue> b) => _isEqual(a, b);

  void retain(Pointer<FLValue> value) => _retain(value);

  void release(Pointer<FLValue> value) => _release(value);

  String toJSONX(
    Pointer<FLValue> value, {
    required bool json5,
    required bool canonical,
  }) =>
      _toJson(value, json5, canonical).toDartStringAndRelease()!;
}

// === Array ===================================================================

final class FLArray extends Opaque {}

typedef _FLArray_Count_C = Uint32 Function(Pointer<FLArray> array);
typedef _FLArray_Count = int Function(Pointer<FLArray> array);

typedef _FLArray_IsEmpty_C = Bool Function(Pointer<FLArray> array);
typedef _FLArray_IsEmpty = bool Function(Pointer<FLArray> array);

typedef _FLArray_AsMutable = Pointer<FLMutableArray> Function(
  Pointer<FLArray> array,
);

typedef _FLArray_Get_C = Pointer<FLValue> Function(
  Pointer<FLArray> array,
  Uint32 index,
);
typedef _FLArray_Get = Pointer<FLValue> Function(
  Pointer<FLArray> array,
  int index,
);

class ArrayBindings extends Bindings {
  ArrayBindings(super.parent) {
    _count = libs.cbl.lookupFunction<_FLArray_Count_C, _FLArray_Count>(
      'FLArray_Count',
      isLeaf: useIsLeaf,
    );
    _isEmpty = libs.cbl.lookupFunction<_FLArray_IsEmpty_C, _FLArray_IsEmpty>(
      'FLArray_IsEmpty',
      isLeaf: useIsLeaf,
    );
    _asMutable =
        libs.cbl.lookupFunction<_FLArray_AsMutable, _FLArray_AsMutable>(
      'FLArray_AsMutable',
      isLeaf: useIsLeaf,
    );
    _get = libs.cbl.lookupFunction<_FLArray_Get_C, _FLArray_Get>(
      'FLArray_Get',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLArray_Count _count;
  late final _FLArray_IsEmpty _isEmpty;
  late final _FLArray_AsMutable _asMutable;
  late final _FLArray_Get _get;

  int count(Pointer<FLArray> array) => _count(array);

  bool isEmpty(Pointer<FLArray> array) => _isEmpty(array);

  Pointer<FLMutableArray>? asMutable(Pointer<FLArray> array) =>
      _asMutable(array).toNullable();

  Pointer<FLValue> get(Pointer<FLArray> array, int index) => _get(array, index);
}

// === MutableArray ============================================================

final class FLMutableArray extends Opaque {}

typedef _FLArray_MutableCopy_C = Pointer<FLMutableArray> Function(
  Pointer<FLArray> array,
  Uint32 flags,
);
typedef _FLArray_MutableCopy = Pointer<FLMutableArray> Function(
  Pointer<FLArray> array,
  int flags,
);

typedef _FLMutableArray_New = Pointer<FLMutableArray> Function();

typedef _FLMutableArray_GetSource = Pointer<FLArray> Function(
  Pointer<FLMutableArray> array,
);

typedef _FLMutableArray_IsChanged_C = Bool Function(
  Pointer<FLMutableArray> array,
);
typedef _FLMutableArray_IsChanged = bool Function(
  Pointer<FLMutableArray> array,
);

typedef _FLMutableArray_Set_C = Pointer<FLSlot> Function(
  Pointer<FLMutableArray> array,
  Uint32 index,
);
typedef _FLMutableArray_Set = Pointer<FLSlot> Function(
  Pointer<FLMutableArray> array,
  int index,
);

typedef _FLMutableArray_Append = Pointer<FLSlot> Function(
  Pointer<FLMutableArray> array,
);

typedef _FLMutableArray_Insert_C = Void Function(
  Pointer<FLMutableArray> array,
  Uint32 firstIndex,
  Uint32 count,
);
typedef _FLMutableArray_Insert = void Function(
  Pointer<FLMutableArray> array,
  int firstIndex,
  int count,
);

typedef _FLMutableArray_Remove_C = Void Function(
  Pointer<FLMutableArray> array,
  Uint32 firstIndex,
  Uint32 count,
);
typedef _FLMutableArray_Remove = void Function(
  Pointer<FLMutableArray> array,
  int firstIndex,
  int count,
);

typedef _FLMutableArray_Resize_C = Void Function(
  Pointer<FLMutableArray> array,
  Uint32 size,
);
typedef _FLMutableArray_Resize = void Function(
  Pointer<FLMutableArray> array,
  int size,
);

typedef _FLMutableArray_GetMutableArray_C = Pointer<FLMutableArray> Function(
  Pointer<FLMutableArray> array,
  Uint32 index,
);
typedef _FLMutableArray_GetMutableArray = Pointer<FLMutableArray> Function(
  Pointer<FLMutableArray> array,
  int index,
);

typedef _FLMutableArray_GetMutableDict_C = Pointer<FLMutableDict> Function(
  Pointer<FLMutableArray> array,
  Uint32 index,
);
typedef _FLMutableArray_GetMutableDict = Pointer<FLMutableDict> Function(
  Pointer<FLMutableArray> array,
  int index,
);

class MutableArrayBindings extends Bindings {
  MutableArrayBindings(super.parent) {
    _mutableCopy =
        libs.cbl.lookupFunction<_FLArray_MutableCopy_C, _FLArray_MutableCopy>(
      'FLArray_MutableCopy',
      isLeaf: useIsLeaf,
    );
    _new = libs.cbl.lookupFunction<_FLMutableArray_New, _FLMutableArray_New>(
      'FLMutableArray_New',
      isLeaf: useIsLeaf,
    );
    _getSource = libs.cbl
        .lookupFunction<_FLMutableArray_GetSource, _FLMutableArray_GetSource>(
      'FLMutableArray_GetSource',
      isLeaf: useIsLeaf,
    );
    _isChanged = libs.cbl
        .lookupFunction<_FLMutableArray_IsChanged_C, _FLMutableArray_IsChanged>(
      'FLMutableArray_IsChanged',
      isLeaf: useIsLeaf,
    );
    _set = libs.cbl.lookupFunction<_FLMutableArray_Set_C, _FLMutableArray_Set>(
      'FLMutableArray_Set',
      isLeaf: useIsLeaf,
    );
    _append =
        libs.cbl.lookupFunction<_FLMutableArray_Append, _FLMutableArray_Append>(
      'FLMutableArray_Append',
      isLeaf: useIsLeaf,
    );
    _insert = libs.cbl
        .lookupFunction<_FLMutableArray_Insert_C, _FLMutableArray_Insert>(
      'FLMutableArray_Insert',
      isLeaf: useIsLeaf,
    );
    _remove = libs.cbl
        .lookupFunction<_FLMutableArray_Remove_C, _FLMutableArray_Remove>(
      'FLMutableArray_Remove',
      isLeaf: useIsLeaf,
    );
    _resize = libs.cbl
        .lookupFunction<_FLMutableArray_Resize_C, _FLMutableArray_Resize>(
      'FLMutableArray_Resize',
      isLeaf: useIsLeaf,
    );
    _getMutableArray = libs.cbl.lookupFunction<
        _FLMutableArray_GetMutableArray_C, _FLMutableArray_GetMutableArray>(
      'FLMutableArray_GetMutableArray',
      isLeaf: useIsLeaf,
    );
    _getMutableDict = libs.cbl.lookupFunction<_FLMutableArray_GetMutableDict_C,
        _FLMutableArray_GetMutableDict>(
      'FLMutableArray_GetMutableDict',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLArray_MutableCopy _mutableCopy;
  late final _FLMutableArray_New _new;
  late final _FLMutableArray_GetSource _getSource;
  late final _FLMutableArray_IsChanged _isChanged;
  late final _FLMutableArray_Set _set;
  late final _FLMutableArray_Append _append;
  late final _FLMutableArray_Insert _insert;
  late final _FLMutableArray_Remove _remove;
  late final _FLMutableArray_Resize _resize;
  late final _FLMutableArray_GetMutableArray _getMutableArray;
  late final _FLMutableArray_GetMutableDict _getMutableDict;

  Pointer<FLMutableArray> mutableCopy(
    Pointer<FLArray> array,
    Set<FLCopyFlag> flags,
  ) =>
      _mutableCopy(array, flags.toCFlags());

  Pointer<FLMutableArray> create() => _new();

  Pointer<FLArray>? getSource(Pointer<FLMutableArray> array) =>
      _getSource(array).toNullable();

  bool isChanged(Pointer<FLMutableArray> array) => _isChanged(array);

  Pointer<FLSlot> set(Pointer<FLMutableArray> array, int index) =>
      _set(array, index);

  Pointer<FLSlot> append(Pointer<FLMutableArray> array) => _append(array);

  void insert(Pointer<FLMutableArray> array, int index, int count) =>
      _insert(array, index, count);

  void remove(Pointer<FLMutableArray> array, int firstIndex, int count) =>
      _remove(array, firstIndex, count);

  void resize(Pointer<FLMutableArray> array, int size) => _resize(array, size);

  Pointer<FLMutableArray>? getMutableArray(
    Pointer<FLMutableArray> array,
    int index,
  ) =>
      _getMutableArray(array, index).toNullable();

  Pointer<FLMutableDict>? getMutableDict(
    Pointer<FLMutableArray> array,
    int index,
  ) =>
      _getMutableDict(array, index).toNullable();
}

// === Dict ====================================================================

final class FLDict extends Opaque {}

typedef _FLDict_Count_C = Uint32 Function(Pointer<FLDict> dict);
typedef _FLDict_Count = int Function(Pointer<FLDict> dict);

typedef _FLDict_IsEmpty_C = Bool Function(Pointer<FLDict> dict);
typedef _FLDict_IsEmpty = bool Function(Pointer<FLDict> dict);

typedef _FLDict_AsMutable = Pointer<FLMutableDict> Function(
  Pointer<FLDict> dict,
);

typedef _FLDict_Get = Pointer<FLValue> Function(
  Pointer<FLDict> dict,
  FLString key,
);

class DictBindings extends Bindings {
  DictBindings(super.parent) {
    _get = libs.cbl.lookupFunction<_FLDict_Get, _FLDict_Get>(
      'FLDict_Get',
      isLeaf: useIsLeaf,
    );
    _count = libs.cbl.lookupFunction<_FLDict_Count_C, _FLDict_Count>(
      'FLDict_Count',
      isLeaf: useIsLeaf,
    );
    _isEmpty = libs.cbl.lookupFunction<_FLDict_IsEmpty_C, _FLDict_IsEmpty>(
      'FLDict_IsEmpty',
      isLeaf: useIsLeaf,
    );
    _asMutable = libs.cbl.lookupFunction<_FLDict_AsMutable, _FLDict_AsMutable>(
      'FLDict_AsMutable',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLDict_Get _get;
  late final _FLDict_Count _count;
  late final _FLDict_IsEmpty _isEmpty;
  late final _FLDict_AsMutable _asMutable;

  Pointer<FLValue>? get(Pointer<FLDict> dict, String key) =>
      runWithSingleFLString(key, (flKey) => _get(dict, flKey)).toNullable();

  Pointer<FLValue>? getWithFLString(Pointer<FLDict> dict, FLString key) =>
      _get(dict, key).toNullable();

  int count(Pointer<FLDict> dict) => _count(dict);

  bool isEmpty(Pointer<FLDict> dict) => _isEmpty(dict);

  Pointer<FLMutableDict>? asMutable(Pointer<FLDict> dict) =>
      _asMutable(dict).toNullable();
}

final class FLDictKey extends Struct {
  // ignore: unused_field
  external FLSlice _private1;
  // ignore: unused_field
  external Pointer<Void> _private2;
  @Uint32()
  // ignore: unused_field
  external int _private3;
  @Uint32()
  // ignore: unused_field
  external int _private4;
  @Bool()
  // ignore: unused_field
  external bool _private5;
}

typedef _FLDictKey_Init = FLDictKey Function(FLString key);

typedef _FLDict_GetWithKey = Pointer<FLValue> Function(
  Pointer<FLDict> dict,
  Pointer<FLDictKey> key,
);

class DictKeyBindings extends Bindings {
  DictKeyBindings(super.parent) {
    _init = libs.cbl.lookupFunction<_FLDictKey_Init, _FLDictKey_Init>(
      'FLDictKey_Init',
      isLeaf: useIsLeaf,
    );
    _getWithKey =
        libs.cbl.lookupFunction<_FLDict_GetWithKey, _FLDict_GetWithKey>(
      'FLDict_GetWithKey',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLDictKey_Init _init;
  late final _FLDict_GetWithKey _getWithKey;

  void init(FLDictKey dictKey, FLString key) {
    final state = _init(key);
    dictKey
      .._private1 = state._private1
      .._private2 = state._private2
      .._private3 = state._private3
      .._private4 = state._private4
      .._private5 = state._private5;
  }

  Pointer<FLValue>? getWithKey(Pointer<FLDict> dict, Pointer<FLDictKey> key) =>
      _getWithKey(dict, key).toNullable();
}

// === MutableDict =============================================================

final class FLMutableDict extends Opaque {}

typedef _FLDict_MutableCopy_C = Pointer<FLMutableDict> Function(
  Pointer<FLDict> source,
  Uint32 flags,
);
typedef _FLDict_MutableCopy = Pointer<FLMutableDict> Function(
  Pointer<FLDict> source,
  int flags,
);

typedef _FLMutableDict_New = Pointer<FLMutableDict> Function();

typedef _FLMutableDict_GetSource = Pointer<FLDict> Function(
  Pointer<FLMutableDict> dict,
);

typedef _FLMutableDict_IsChanged_C = Bool Function(
  Pointer<FLMutableDict> dict,
);
typedef _FLMutableDict_IsChanged = bool Function(Pointer<FLMutableDict> dict);

typedef _FLMutableDict_Set = Pointer<FLSlot> Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

typedef _FLMutableDict_Remove_C = Void Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);
typedef _FLMutableDict_Remove = void Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

typedef _FLMutableDict_RemoveAll_C = Void Function(Pointer<FLMutableDict> dict);
typedef _FLMutableDict_RemoveAll = void Function(Pointer<FLMutableDict> dict);

typedef _FLMutableDict_GetMutableArray = Pointer<FLMutableArray> Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

typedef _FLMutableDict_GetMutableDict = Pointer<FLMutableDict> Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

class MutableDictBindings extends Bindings {
  MutableDictBindings(super.parent) {
    _mutableCopy =
        libs.cbl.lookupFunction<_FLDict_MutableCopy_C, _FLDict_MutableCopy>(
      'FLDict_MutableCopy',
      isLeaf: useIsLeaf,
    );
    _new = libs.cbl.lookupFunction<_FLMutableDict_New, _FLMutableDict_New>(
      'FLMutableDict_New',
      isLeaf: useIsLeaf,
    );
    _getSource = libs.cbl
        .lookupFunction<_FLMutableDict_GetSource, _FLMutableDict_GetSource>(
      'FLMutableDict_GetSource',
      isLeaf: useIsLeaf,
    );
    _isChanged = libs.cbl
        .lookupFunction<_FLMutableDict_IsChanged_C, _FLMutableDict_IsChanged>(
      'FLMutableDict_IsChanged',
      isLeaf: useIsLeaf,
    );
    _set = libs.cbl.lookupFunction<_FLMutableDict_Set, _FLMutableDict_Set>(
      'FLMutableDict_Set',
      isLeaf: useIsLeaf,
    );
    _remove =
        libs.cbl.lookupFunction<_FLMutableDict_Remove_C, _FLMutableDict_Remove>(
      'FLMutableDict_Remove',
      isLeaf: useIsLeaf,
    );
    _removeAll = libs.cbl
        .lookupFunction<_FLMutableDict_RemoveAll_C, _FLMutableDict_RemoveAll>(
      'FLMutableDict_RemoveAll',
      isLeaf: useIsLeaf,
    );
    _getMutableArray = libs.cbl.lookupFunction<_FLMutableDict_GetMutableArray,
        _FLMutableDict_GetMutableArray>(
      'FLMutableDict_GetMutableArray',
      isLeaf: useIsLeaf,
    );
    _getMutableDict = libs.cbl.lookupFunction<_FLMutableDict_GetMutableDict,
        _FLMutableDict_GetMutableDict>(
      'FLMutableDict_GetMutableDict',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLDict_MutableCopy _mutableCopy;
  late final _FLMutableDict_New _new;
  late final _FLMutableDict_GetSource _getSource;
  late final _FLMutableDict_IsChanged _isChanged;
  late final _FLMutableDict_Set _set;
  late final _FLMutableDict_Remove _remove;
  late final _FLMutableDict_RemoveAll _removeAll;
  late final _FLMutableDict_GetMutableArray _getMutableArray;
  late final _FLMutableDict_GetMutableDict _getMutableDict;

  Pointer<FLMutableDict> mutableCopy(
    Pointer<FLDict> source,
    Set<FLCopyFlag> flags,
  ) =>
      _mutableCopy(source, flags.toCFlags());

  Pointer<FLMutableDict> create() => _new();

  Pointer<FLDict>? getSource(Pointer<FLMutableDict> dict) =>
      _getSource(dict).toNullable();

  bool isChanged(Pointer<FLMutableDict> dict) => _isChanged(dict);

  Pointer<FLSlot> set(Pointer<FLMutableDict> dict, String key) =>
      runWithSingleFLString(key, (flKey) => _set(dict, flKey));

  void remove(Pointer<FLMutableDict> dict, String key) {
    runWithSingleFLString(key, (flKey) => _remove(dict, flKey));
  }

  void removeAll(Pointer<FLMutableDict> dict) {
    _removeAll(dict);
  }

  Pointer<FLMutableArray>? getMutableArray(
    Pointer<FLMutableDict> array,
    String key,
  ) =>
      runWithSingleFLString(
        key,
        (flKey) => _getMutableArray(array, flKey).toNullable(),
      );

  Pointer<FLMutableDict>? getMutableDict(
    Pointer<FLMutableDict> array,
    String key,
  ) =>
      runWithSingleFLString(
        key,
        (flKey) => _getMutableDict(array, flKey).toNullable(),
      );
}

// === Decoder =================================================================

@pragma('vm:prefer-inline')
String decodeFLString(int address, int size) =>
    utf8.decode(Pointer<Uint8>.fromAddress(address).asTypedList(size));

enum FLTrust {
  untrusted,
  trusted,
}

extension on FLTrust {
  int toInt() => index;
}

final class KnownSharedKeys extends Opaque {}

typedef _CBLDart_KnownSharedKeys_New = Pointer<KnownSharedKeys> Function();

typedef _CBLDart_KnownSharedKeys_Delete_C = Void Function(
  Pointer<KnownSharedKeys> keys,
);

final class CBLDart_LoadedDictKey extends Struct {
  @Bool()
  external bool isKnownSharedKey;
  @Int()
  external int sharedKey;
  @UintPtr()
  external int stringBuf;
  @Size()
  external int stringSize;
  external Pointer<FLValue> value;
}

final class CBLDart_LoadedFLValue extends Struct {
  @Bool()
  external bool exists;
  @Int8()
  external int _type;
  @Bool()
  external bool isInteger;
  @Uint32()
  external int collectionSize;
  @Bool()
  external bool asBool;
  @Int64()
  external int asInt;
  @Double()
  external double asDouble;
  @UintPtr()
  external int stringBuf;
  @Size()
  external int stringSize;
  external FLSlice asData;
  @UintPtr()
  external int value;
}

// ignore: camel_case_extensions
extension CBLDart_LoadedFLValueExt on CBLDart_LoadedFLValue {
  FLValueType get type => _type.toFLValueType();
}

typedef _FLData_Dump_C = FLStringResult Function(FLSlice slice);
typedef _FLData_Dump = FLStringResult Function(FLSlice slice);

typedef _CBLDart_GetLoaded_FLValue_C = Void Function(
  Pointer<FLValue> value,
  Pointer<CBLDart_LoadedFLValue> out,
);
typedef _CBLDart_GetLoadedFLValue = void Function(
  Pointer<FLValue> value,
  Pointer<CBLDart_LoadedFLValue> out,
);

typedef _CBLDart_FLArray_GetLoaded_FLValue_C = Void Function(
  Pointer<FLArray> array,
  Uint32 index,
  Pointer<CBLDart_LoadedFLValue> out,
);
typedef _CBLDart_FLArray_GetLoadedFLValue = void Function(
  Pointer<FLArray> array,
  int index,
  Pointer<CBLDart_LoadedFLValue> out,
);

typedef _CBLDart_FLDict_GetLoaded_FLValue_C = Void Function(
  Pointer<FLDict> dict,
  FLString key,
  Pointer<CBLDart_LoadedFLValue> out,
);
typedef _CBLDart_FLDict_GetLoadedFLValue = void Function(
  Pointer<FLDict> dict,
  FLString key,
  Pointer<CBLDart_LoadedFLValue> out,
);

final class CBLDart_FLDictIterator extends Opaque {}

typedef _CBLDart_FLDictIterator_Begin_C = Pointer<CBLDart_FLDictIterator>
    Function(
  Pointer<FLDict> dict,
  Pointer<KnownSharedKeys> knownSharedKeys,
  Pointer<CBLDart_LoadedDictKey> keyOut,
  Pointer<CBLDart_LoadedFLValue> valueOut,
  Bool deleteOnDone,
  Bool preLoad,
);
typedef _CBLDart_FLDictIterator_Begin = Pointer<CBLDart_FLDictIterator>
    Function(
  Pointer<FLDict> dict,
  Pointer<KnownSharedKeys> knownSharedKeys,
  Pointer<CBLDart_LoadedDictKey> keyOut,
  Pointer<CBLDart_LoadedFLValue> valueOut,
  bool deleteOnDone,
  bool preLoad,
);

typedef _CBLDart_FLDictIterator_Delete_C = Void Function(
  Pointer<CBLDart_FLDictIterator> iterator,
);

typedef _CBLDart_FLDictIterator_Next_C = Bool Function(
  Pointer<CBLDart_FLDictIterator> iterator,
);
typedef _CBLDart_FLDictIterator_Next = bool Function(
  Pointer<CBLDart_FLDictIterator> iterator,
);

final class CBLDart_FLArrayIterator extends Opaque {}

typedef _CBLDart_FLArrayIterator_Begin_C = Pointer<CBLDart_FLArrayIterator>
    Function(
  Pointer<FLArray> array,
  Pointer<CBLDart_LoadedFLValue> valueOut,
  Bool deleteOnDone,
);
typedef _CBLDart_FLArrayIterator_Begin = Pointer<CBLDart_FLArrayIterator>
    Function(
  Pointer<FLArray> array,
  Pointer<CBLDart_LoadedFLValue> valueOut,
  bool deleteOnDone,
);

typedef _CBLDart_FLArrayIterator_Delete_C = Void Function(
  Pointer<CBLDart_FLArrayIterator> iterator,
);

typedef _CBLDart_FLArrayIterator_Next_C = Bool Function(
  Pointer<CBLDart_FLArrayIterator> iterator,
);
typedef _CBLDart_FLArrayIterator_Next = bool Function(
  Pointer<CBLDart_FLArrayIterator> iterator,
);

class FleeceDecoderBindings extends Bindings {
  FleeceDecoderBindings(super.parent) {
    _dumpData = libs.cbl.lookupFunction<_FLData_Dump_C, _FLData_Dump>(
      'FLData_Dump',
      isLeaf: useIsLeaf,
    );
    _knownSharedKeysNew = libs.cblDart.lookupFunction<
        _CBLDart_KnownSharedKeys_New, _CBLDart_KnownSharedKeys_New>(
      'CBLDart_KnownSharedKeys_New',
    );
    _knownSharedKeysDeletePtr =
        libs.cblDart.lookup('CBLDart_KnownSharedKeys_Delete');
    _getLoadedFLValue = libs.cblDart.lookupFunction<
        _CBLDart_GetLoaded_FLValue_C, _CBLDart_GetLoadedFLValue>(
      'CBLDart_GetLoadedFLValue',
      isLeaf: useIsLeaf,
    );
    _getLoadedFLValueFromArray = libs.cblDart.lookupFunction<
        _CBLDart_FLArray_GetLoaded_FLValue_C,
        _CBLDart_FLArray_GetLoadedFLValue>(
      'CBLDart_FLArray_GetLoadedFLValue',
      isLeaf: useIsLeaf,
    );
    _getLoadedFLValueFromDict = libs.cblDart.lookupFunction<
        _CBLDart_FLDict_GetLoaded_FLValue_C, _CBLDart_FLDict_GetLoadedFLValue>(
      'CBLDart_FLDict_GetLoadedFLValue',
      isLeaf: useIsLeaf,
    );
    _dictIteratorBegin = libs.cblDart.lookupFunction<
        _CBLDart_FLDictIterator_Begin_C, _CBLDart_FLDictIterator_Begin>(
      'CBLDart_FLDictIterator_Begin',
    );
    _dictIteratorDeletePtr =
        libs.cblDart.lookup('CBLDart_FLDictIterator_Delete');
    _dictIteratorNext = libs.cblDart.lookupFunction<
        _CBLDart_FLDictIterator_Next_C, _CBLDart_FLDictIterator_Next>(
      'CBLDart_FLDictIterator_Next',
      isLeaf: useIsLeaf,
    );
    _arrayIteratorBegin = libs.cblDart.lookupFunction<
        _CBLDart_FLArrayIterator_Begin_C, _CBLDart_FLArrayIterator_Begin>(
      'CBLDart_FLArrayIterator_Begin',
    );
    _arrayIteratorDeletePtr =
        libs.cblDart.lookup('CBLDart_FLArrayIterator_Delete');
    _arrayIteratorNext = libs.cblDart.lookupFunction<
        _CBLDart_FLArrayIterator_Next_C, _CBLDart_FLArrayIterator_Next>(
      'CBLDart_FLArrayIterator_Next',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLData_Dump _dumpData;
  late final _CBLDart_KnownSharedKeys_New _knownSharedKeysNew;
  late final Pointer<NativeFunction<_CBLDart_KnownSharedKeys_Delete_C>>
      _knownSharedKeysDeletePtr;
  late final _CBLDart_GetLoadedFLValue _getLoadedFLValue;
  late final _CBLDart_FLArray_GetLoadedFLValue _getLoadedFLValueFromArray;
  late final _CBLDart_FLDict_GetLoadedFLValue _getLoadedFLValueFromDict;
  late final _CBLDart_FLDictIterator_Begin _dictIteratorBegin;
  late final Pointer<NativeFunction<_CBLDart_FLDictIterator_Delete_C>>
      _dictIteratorDeletePtr;
  late final _CBLDart_FLDictIterator_Next _dictIteratorNext;
  late final _CBLDart_FLArrayIterator_Begin _arrayIteratorBegin;
  late final Pointer<NativeFunction<_CBLDart_FLArrayIterator_Delete_C>>
      _arrayIteratorDeletePtr;
  late final _CBLDart_FLArrayIterator_Next _arrayIteratorNext;

  late final _knownSharedKeysFinalizer =
      NativeFinalizer(_knownSharedKeysDeletePtr.cast());
  late final _dictIteratorFinalizer =
      NativeFinalizer(_dictIteratorDeletePtr.cast());
  late final _arrayIteratorFinalizer =
      NativeFinalizer(_arrayIteratorDeletePtr.cast());

  String dumpData(Data data) => _dumpData(data.toSliceResult().makeGlobal().ref)
      .toDartStringAndRelease()!;

  Pointer<KnownSharedKeys> createKnownSharedKeys(Finalizable object) {
    final result = _knownSharedKeysNew();
    _knownSharedKeysFinalizer.attach(object, result.cast());
    return result;
  }

  void getLoadedValue(Pointer<FLValue> value) {
    _getLoadedFLValue(value, globalLoadedFLValue);
  }

  void getLoadedValueFromArray(
    Pointer<FLArray> array,
    int index,
  ) {
    _getLoadedFLValueFromArray(array, index, globalLoadedFLValue);
  }

  void getLoadedValueFromDict(
    Pointer<FLDict> array,
    String key,
  ) {
    runWithSingleFLString(key, (flKey) {
      _getLoadedFLValueFromDict(array, flKey, globalLoadedFLValue);
    });
  }

  Pointer<CBLDart_FLDictIterator> dictIteratorBegin(
    Finalizable? object,
    Pointer<FLDict> dict,
    Pointer<KnownSharedKeys> knownSharedKeys,
    Pointer<CBLDart_LoadedDictKey> keyOut,
    Pointer<CBLDart_LoadedFLValue> valueOut, {
    required bool preLoad,
  }) {
    final result = _dictIteratorBegin(
      dict,
      knownSharedKeys,
      keyOut,
      valueOut,
      object == null,
      preLoad,
    );

    if (object != null) {
      _dictIteratorFinalizer.attach(object, result.cast());
    }

    return result;
  }

  bool dictIteratorNext(Pointer<CBLDart_FLDictIterator> iterator) =>
      _dictIteratorNext(iterator);

  Pointer<CBLDart_FLArrayIterator> arrayIteratorBegin(
    Finalizable? object,
    Pointer<FLArray> array,
    Pointer<CBLDart_LoadedFLValue> valueOut,
  ) {
    final result = _arrayIteratorBegin(array, valueOut, object == null);

    if (object != null) {
      _arrayIteratorFinalizer.attach(object, result.cast());
    }

    return result;
  }

  bool arrayIteratorNext(Pointer<CBLDart_FLArrayIterator> iterator) =>
      _arrayIteratorNext(iterator);
}

// === Encoder =================================================================

enum FLEncoderFormat {
  fleece,
  json,
  json5,
}

extension on FLEncoderFormat {
  int toInt() => index;
}

final class FLEncoder extends Opaque {}

typedef _FLEncoder_NewWithOptions_C = Pointer<FLEncoder> Function(
  Uint8 format,
  Size reserveSize,
  Bool uniqueStrings,
);
typedef _FLEncoder_NewWithOptions = Pointer<FLEncoder> Function(
  int format,
  int reserveSize,
  bool uniqueStrings,
);

typedef _FLEncoder_Free_C = Void Function(Pointer<FLEncoder> encoder);

typedef _FLEncoder_SetSharedKeys_C = Void Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLSharedKeys> sharedKeys,
);
typedef _FLEncoder_SetSharedKeys = void Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLSharedKeys> sharedKeys,
);

typedef _FLEncoder_Reset_C = Void Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_Reset = void Function(Pointer<FLEncoder> encoder);

typedef _CBLDart_FLEncoder_WriteArrayValue_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLArray> array,
  Uint32 index,
);
typedef _CBLDart_FLEncoder_WriteArrayValue = bool Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLArray> array,
  int index,
);

typedef _FLEncoder_WriteValue_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLValue> value,
);
typedef _FLEncoder_WriteValue = bool Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLValue> value,
);

typedef _FLEncoder_WriteNull_C = Bool Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_WriteNull = bool Function(Pointer<FLEncoder> encoder);

typedef _FLEncoder_WriteBool_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Bool value,
);
typedef _FLEncoder_WriteBool = bool Function(
  Pointer<FLEncoder> encoder,
  bool value,
);

typedef _FLEncoder_WriteInt_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Int64 value,
);
typedef _FLEncoder_WriteInt = bool Function(
  Pointer<FLEncoder> encoder,
  int value,
);

typedef _FLEncoder_WriteDouble_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Double value,
);
typedef _FLEncoder_WriteDouble = bool Function(
  Pointer<FLEncoder> encoder,
  double value,
);

typedef _FLEncoder_WriteString_C = Bool Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);
typedef _FLEncoder_WriteString = bool Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);

typedef _FLEncoder_WriteData_C = Bool Function(
  Pointer<FLEncoder> encoder,
  FLSlice value,
);
typedef _FLEncoder_WriteData = bool Function(
  Pointer<FLEncoder> encoder,
  FLSlice value,
);

typedef _FLEncoder_ConvertJSON_C = Bool Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);
typedef _FLEncoder_ConvertJSON = bool Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);

typedef _FLEncoder_BeginArray_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Size reserveCount,
);
typedef _FLEncoder_BeginArray = bool Function(
  Pointer<FLEncoder> encoder,
  int reserveCount,
);

typedef _FLEncoder_EndArray_C = Bool Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_EndArray = bool Function(Pointer<FLEncoder> encoder);

typedef _FLEncoder_BeginDict_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Size reserveCount,
);
typedef _FLEncoder_BeginDict = bool Function(
  Pointer<FLEncoder> encoder,
  int reserveCount,
);

typedef _FLEncoder_WriteKey_C = Bool Function(
  Pointer<FLEncoder> encoder,
  FLString key,
);
typedef _FLEncoder_WriteKey = bool Function(
  Pointer<FLEncoder> encoder,
  FLString key,
);

typedef _FLEncoder_WriteKeyValue_C = Bool Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLValue> key,
);
typedef _FLEncoder_WriteKeyValue = bool Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLValue> key,
);

typedef _FLEncoder_EndDict_C = Bool Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_EndDict = bool Function(Pointer<FLEncoder> encoder);

typedef _FLEncoder_Finish_C = FLSliceResult Function(
  Pointer<FLEncoder> encoder,
  Pointer<Uint32> errorOut,
);
typedef _FLEncoder_Finish = FLSliceResult Function(
  Pointer<FLEncoder> encoder,
  Pointer<Uint32> errorOut,
);

typedef _FLEncoder_GetError_C = Uint32 Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_GetError = int Function(Pointer<FLEncoder> encoder);

typedef _FLEncoder_GetErrorMessage_C = Pointer<Utf8> Function(
  Pointer<FLEncoder> encoder,
);
typedef _FLEncoder_GetErrorMessage = Pointer<Utf8> Function(
  Pointer<FLEncoder> encoder,
);

class FleeceEncoderBindings extends Bindings {
  FleeceEncoderBindings(super.parent) {
    _new = libs.cbl
        .lookupFunction<_FLEncoder_NewWithOptions_C, _FLEncoder_NewWithOptions>(
      'FLEncoder_NewWithOptions',
      isLeaf: useIsLeaf,
    );
    _freePtr = libs.cbl.lookup('FLEncoder_Free');
    _setSharedKeys = libs.cbl
        .lookupFunction<_FLEncoder_SetSharedKeys_C, _FLEncoder_SetSharedKeys>(
      'FLEncoder_SetSharedKeys',
      isLeaf: useIsLeaf,
    );
    _reset = libs.cbl.lookupFunction<_FLEncoder_Reset_C, _FLEncoder_Reset>(
      'FLEncoder_Reset',
      isLeaf: useIsLeaf,
    );
    _writeArrayValue = libs.cblDart.lookupFunction<
        _CBLDart_FLEncoder_WriteArrayValue_C,
        _CBLDart_FLEncoder_WriteArrayValue>(
      'CBLDart_FLEncoder_WriteArrayValue',
      isLeaf: useIsLeaf,
    );
    _writeValue =
        libs.cbl.lookupFunction<_FLEncoder_WriteValue_C, _FLEncoder_WriteValue>(
      'FLEncoder_WriteValue',
      isLeaf: useIsLeaf,
    );
    _writeNull =
        libs.cbl.lookupFunction<_FLEncoder_WriteNull_C, _FLEncoder_WriteNull>(
      'FLEncoder_WriteNull',
      isLeaf: useIsLeaf,
    );
    _writeBool =
        libs.cbl.lookupFunction<_FLEncoder_WriteBool_C, _FLEncoder_WriteBool>(
      'FLEncoder_WriteBool',
      isLeaf: useIsLeaf,
    );
    _writeInt =
        libs.cbl.lookupFunction<_FLEncoder_WriteInt_C, _FLEncoder_WriteInt>(
      'FLEncoder_WriteInt',
      isLeaf: useIsLeaf,
    );
    _writeDouble = libs.cbl
        .lookupFunction<_FLEncoder_WriteDouble_C, _FLEncoder_WriteDouble>(
      'FLEncoder_WriteDouble',
      isLeaf: useIsLeaf,
    );
    _writeString = libs.cbl
        .lookupFunction<_FLEncoder_WriteString_C, _FLEncoder_WriteString>(
      'FLEncoder_WriteString',
      isLeaf: useIsLeaf,
    );
    _writeData =
        libs.cbl.lookupFunction<_FLEncoder_WriteData_C, _FLEncoder_WriteData>(
      'FLEncoder_WriteData',
      isLeaf: useIsLeaf,
    );
    _writeJSON = libs.cbl
        .lookupFunction<_FLEncoder_ConvertJSON_C, _FLEncoder_ConvertJSON>(
      'FLEncoder_ConvertJSON',
      isLeaf: useIsLeaf,
    );
    _beginArray =
        libs.cbl.lookupFunction<_FLEncoder_BeginArray_C, _FLEncoder_BeginArray>(
      'FLEncoder_BeginArray',
      isLeaf: useIsLeaf,
    );
    _endArray =
        libs.cbl.lookupFunction<_FLEncoder_EndArray_C, _FLEncoder_EndArray>(
      'FLEncoder_EndArray',
      isLeaf: useIsLeaf,
    );
    _beginDict =
        libs.cbl.lookupFunction<_FLEncoder_BeginDict_C, _FLEncoder_BeginDict>(
      'FLEncoder_BeginDict',
      isLeaf: useIsLeaf,
    );
    _writeKey =
        libs.cbl.lookupFunction<_FLEncoder_WriteKey_C, _FLEncoder_WriteKey>(
      'FLEncoder_WriteKey',
      isLeaf: useIsLeaf,
    );
    _writeKeyValue = libs.cbl
        .lookupFunction<_FLEncoder_WriteKeyValue_C, _FLEncoder_WriteKeyValue>(
      'FLEncoder_WriteKeyValue',
      isLeaf: useIsLeaf,
    );
    _endDict =
        libs.cbl.lookupFunction<_FLEncoder_EndDict_C, _FLEncoder_EndDict>(
      'FLEncoder_EndDict',
      isLeaf: useIsLeaf,
    );
    _finish = libs.cbl.lookupFunction<_FLEncoder_Finish_C, _FLEncoder_Finish>(
      'FLEncoder_Finish',
      isLeaf: useIsLeaf,
    );
    __getError =
        libs.cbl.lookupFunction<_FLEncoder_GetError_C, _FLEncoder_GetError>(
      'FLEncoder_GetError',
      isLeaf: useIsLeaf,
    );
    __getErrorMessage = libs.cbl.lookupFunction<_FLEncoder_GetErrorMessage_C,
        _FLEncoder_GetErrorMessage>(
      'FLEncoder_GetErrorMessage',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLEncoder_NewWithOptions _new;
  late final Pointer<NativeFunction<_FLEncoder_Free_C>> _freePtr;
  late final _FLEncoder_SetSharedKeys _setSharedKeys;
  late final _FLEncoder_Reset _reset;
  late final _CBLDart_FLEncoder_WriteArrayValue _writeArrayValue;
  late final _FLEncoder_WriteValue _writeValue;
  late final _FLEncoder_WriteNull _writeNull;
  late final _FLEncoder_WriteBool _writeBool;
  late final _FLEncoder_WriteInt _writeInt;
  late final _FLEncoder_WriteDouble _writeDouble;
  late final _FLEncoder_WriteString _writeString;
  late final _FLEncoder_WriteData _writeData;
  late final _FLEncoder_ConvertJSON _writeJSON;
  late final _FLEncoder_BeginArray _beginArray;
  late final _FLEncoder_EndArray _endArray;
  late final _FLEncoder_BeginDict _beginDict;
  late final _FLEncoder_WriteKey _writeKey;
  late final _FLEncoder_WriteKeyValue _writeKeyValue;
  late final _FLEncoder_EndDict _endDict;
  late final _FLEncoder_Finish _finish;
  late final _FLEncoder_GetError __getError;
  late final _FLEncoder_GetErrorMessage __getErrorMessage;

  late final _finalizer = NativeFinalizer(_freePtr.cast());

  void bindToDartObject(Finalizable object, Pointer<FLEncoder> encoder) {
    _finalizer.attach(object, encoder.cast());
  }

  Pointer<FLEncoder> create({
    required FLEncoderFormat format,
    required int reserveSize,
    required bool uniqueStrings,
  }) =>
      _new(format.toInt(), reserveSize, uniqueStrings);

  void setSharedKeys(Pointer<FLEncoder> encoder, Pointer<FLSharedKeys> keys) {
    _setSharedKeys(encoder, keys);
  }

  void reset(Pointer<FLEncoder> encoder) {
    _reset(encoder);
  }

  void writeArrayValue(
    Pointer<FLEncoder> encoder,
    Pointer<FLArray> array,
    int index,
  ) {
    _checkError(encoder, _writeArrayValue(encoder, array, index));
  }

  void writeValue(Pointer<FLEncoder> encoder, Pointer<FLValue> value) {
    if (value == nullptr) {
      throw ArgumentError.value(value, 'value', 'must not be `nullptr`');
    }

    _checkError(encoder, _writeValue(encoder, value));
  }

  void writeNull(Pointer<FLEncoder> encoder) {
    _checkError(encoder, _writeNull(encoder));
  }

  void writeBool(Pointer<FLEncoder> encoder, bool value) {
    _checkError(encoder, _writeBool(encoder, value));
  }

  void writeInt(Pointer<FLEncoder> encoder, int value) {
    _checkError(encoder, _writeInt(encoder, value));
  }

  void writeDouble(Pointer<FLEncoder> encoder, double value) {
    _checkError(encoder, _writeDouble(encoder, value));
  }

  void writeString(Pointer<FLEncoder> encoder, String value) {
    runWithSingleFLString(value, (flValue) {
      _checkError(encoder, _writeString(encoder, flValue));
    });
  }

  void writeData(Pointer<FLEncoder> encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      _writeData(encoder, sliceResult.makeGlobal().ref),
    );
  }

  void writeJSON(Pointer<FLEncoder> encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      _writeJSON(
        encoder,
        sliceResult.makeGlobal().cast<FLString>().ref,
      ),
    );
  }

  void beginArray(Pointer<FLEncoder> encoder, int reserveCount) {
    _checkError(encoder, _beginArray(encoder, reserveCount));
  }

  void endArray(Pointer<FLEncoder> encoder) {
    _checkError(encoder, _endArray(encoder));
  }

  void beginDict(Pointer<FLEncoder> encoder, int reserveCount) {
    _checkError(encoder, _beginDict(encoder, reserveCount));
  }

  void writeKey(Pointer<FLEncoder> encoder, String key) {
    runWithSingleFLString(key, (flKey) {
      _checkError(encoder, _writeKey(encoder, flKey));
    });
  }

  void writeKeyFLString(Pointer<FLEncoder> encoder, FLString key) {
    _checkError(encoder, _writeKey(encoder, key));
  }

  void writeKeyValue(Pointer<FLEncoder> encoder, Pointer<FLValue> key) {
    _checkError(encoder, _writeKeyValue(encoder, key));
  }

  void endDict(Pointer<FLEncoder> encoder) {
    _checkError(encoder, _endDict(encoder));
  }

  Data? finish(Pointer<FLEncoder> encoder) =>
      _checkError(encoder, _finish(encoder, globalFLErrorCode))
          .let(SliceResult.fromFLSliceResult)
          ?.toData();

  FLErrorCode _getError(Pointer<FLEncoder> encoder) =>
      __getError(encoder).toFleeceErrorCode();

  String _getErrorMessage(Pointer<FLEncoder> encoder) =>
      __getErrorMessage(encoder).toDartStringAndFree();

  T _checkError<T>(Pointer<FLEncoder> encoder, T result) {
    final mayHaveError = (result is bool && !result) ||
        (result is FLSliceResult && result.buf == nullptr);

    if (mayHaveError) {
      final errorCode = _getError(encoder);
      if (errorCode == FLErrorCode.noError) {
        return result;
      }

      throw CBLErrorException(
        CBLErrorDomain.fleece,
        errorCode,
        _getErrorMessage(encoder),
      );
    }

    return result;
  }
}

// === FleeceBindings ==========================================================

class FleeceBindings extends Bindings {
  FleeceBindings(super.parent) {
    slice = SliceBindings(this);
    sharedKeys = SharedKeysBindings(this);
    slot = SlotBindings(this);
    doc = DocBindings(this);
    value = ValueBindings(this);
    array = ArrayBindings(this);
    mutableArray = MutableArrayBindings(this);
    dict = DictBindings(this);
    dictKey = DictKeyBindings(this);
    mutableDict = MutableDictBindings(this);
    decoder = FleeceDecoderBindings(this);
    encoder = FleeceEncoderBindings(this);
  }

  late final SliceBindings slice;
  late final SharedKeysBindings sharedKeys;
  late final SlotBindings slot;
  late final DocBindings doc;
  late final ValueBindings value;
  late final ArrayBindings array;
  late final MutableArrayBindings mutableArray;
  late final DictBindings dict;
  late final DictKeyBindings dictKey;
  late final MutableDictBindings mutableDict;
  late final FleeceDecoderBindings decoder;
  late final FleeceEncoderBindings encoder;
}
