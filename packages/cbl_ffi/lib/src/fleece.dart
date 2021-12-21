import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'data.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

// === Common ==================================================================

class FLCopyFlag extends Option {
  const FLCopyFlag._(int bits) : super(bits);

  static const deepCopy = FLCopyFlag._(0);
  static const copyImmutables = FLCopyFlag._(1);

  static const values = [deepCopy, copyImmutables];
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

class FLSlice extends Struct {
  external Pointer<Uint8> buf;

  // TODO(blaugold): remove FLSlice wrapper, https://github.com/cbl-dart/cbl-dart/issues/139
  // This is actually a size_t, but Dart FFI does not support it yet.
  // See https://github.com/dart-lang/sdk/issues/36140.
  // We work around this by translating between an actual FLSlice(Result)
  // and this fixed size struct. Also applies to FLSliceResult, FLString and
  // FLStringResult.
  @Uint64()
  external int size;
}

extension FLSliceExt on FLSlice {
  bool get isNull => buf == nullptr;
  Data? toData() => SliceResult.copyFLSlice(this)?.toData();
}

class FLSliceResult extends Struct {
  external Pointer<Uint8> buf;

  @Uint64()
  external int size;
}

extension FLResultSliceExt on FLSliceResult {
  bool get isNull => buf == nullptr;
  Data? toData() => SliceResult.copyFLSliceResult(this)?.toData();
}

class FLString extends Struct {
  external Pointer<Uint8> buf;

  @Uint64()
  external int size;
}

extension FLStringExt on FLString {
  bool get isNull => buf == nullptr;
  String? toDartString() =>
      isNull ? null : buf.cast<Utf8>().toDartString(length: size);
}

class FLStringResult extends Struct {
  external Pointer<Uint8> buf;

  @Uint64()
  external int size;
}

extension FLStringResultExt on FLStringResult {
  bool get isNull => buf == nullptr;
  String? toDartStringAndRelease() {
    if (isNull) {
      return null;
    }

    final result = buf.cast<Utf8>().toDartString(length: size);

    CBLBindings.instance.fleece.slice.releaseStringResult(this);

    return result;
  }
}

typedef _CBLDart_FLSlice_Equal_C = Uint8 Function(FLSlice a, FLSlice b);
typedef _CBLDart_FLSlice_Equal = int Function(FLSlice a, FLSlice b);

typedef _CBLDart_FLSlice_Compare_C = Int64 Function(FLSlice a, FLSlice b);
typedef _CBLDart_FLSlice_Compare = int Function(FLSlice a, FLSlice b);

typedef _CBLDart_FLSliceResult_New_C = FLSliceResult Function(Uint64 size);
typedef _CBLDart_FLSliceResult_New = FLSliceResult Function(int size);

typedef _CBLDart_FLSlice_Copy_C = FLSliceResult Function(FLSlice slice);
typedef _CBLDart_FLSlice_Copy = FLSliceResult Function(FLSlice slice);

typedef _CBLDart_FLSliceResult_BindToDartObject_C = Void Function(
  Handle object,
  FLSliceResult slice,
  Uint8 retain,
);
typedef _CBLDart_FLSliceResult_BindToDartObject = void Function(
  Object object,
  FLSliceResult slice,
  int retain,
);

typedef _CBLDart_FLSliceResult_Retain_C = Void Function(FLSliceResult);
typedef _CBLDart_FLSliceResult_Retain = void Function(FLSliceResult);

typedef _CBLDart_FLSliceResult_Release_C = Void Function(FLSliceResult);
typedef _CBLDart_FLSliceResult_Release = void Function(FLSliceResult);

typedef _CBLDart_FLStringResult_Release_C = Void Function(FLStringResult);
typedef _CBLDart_FLStringResult_Release = void Function(FLStringResult);

class SliceBindings extends Bindings {
  SliceBindings(Bindings parent) : super(parent) {
    _equal = libs.cblDart
        .lookupFunction<_CBLDart_FLSlice_Equal_C, _CBLDart_FLSlice_Equal>(
      'CBLDart_FLSlice_Equal',
    );
    _compare = libs.cblDart
        .lookupFunction<_CBLDart_FLSlice_Compare_C, _CBLDart_FLSlice_Compare>(
      'CBLDart_FLSlice_Compare',
    );
    _new = libs.cblDart.lookupFunction<_CBLDart_FLSliceResult_New_C,
        _CBLDart_FLSliceResult_New>(
      'CBLDart_FLSliceResult_New',
    );
    _copy = libs.cblDart
        .lookupFunction<_CBLDart_FLSlice_Copy_C, _CBLDart_FLSlice_Copy>(
      'CBLDart_FLSlice_Copy',
    );
    _bindToDartObject = libs.cblDart.lookupFunction<
        _CBLDart_FLSliceResult_BindToDartObject_C,
        _CBLDart_FLSliceResult_BindToDartObject>(
      'CBLDart_FLSliceResult_BindToDartObject',
    );
    _retainSliceResult = libs.cblDart.lookupFunction<
        _CBLDart_FLSliceResult_Retain_C, _CBLDart_FLSliceResult_Retain>(
      'CBLDart_FLSliceResult_Retain',
    );
    _releaseSliceResult = libs.cblDart.lookupFunction<
        _CBLDart_FLSliceResult_Release_C, _CBLDart_FLSliceResult_Release>(
      'CBLDart_FLSliceResult_Release',
    );
    _releaseStringResult = libs.cblDart.lookupFunction<
        _CBLDart_FLStringResult_Release_C, _CBLDart_FLStringResult_Release>(
      'CBLDart_FLSliceResult_Release',
    );
  }

  late final _CBLDart_FLSlice_Equal _equal;
  late final _CBLDart_FLSlice_Compare _compare;

  late final _CBLDart_FLSliceResult_New _new;
  late final _CBLDart_FLSlice_Copy _copy;
  late final _CBLDart_FLSliceResult_BindToDartObject _bindToDartObject;
  late final _CBLDart_FLSliceResult_Retain _retainSliceResult;
  late final _CBLDart_FLSliceResult_Release _releaseSliceResult;
  late final _CBLDart_FLStringResult_Release _releaseStringResult;

  bool equal(FLSlice a, FLSlice b) => _equal(a, b).toBool();

  int compare(FLSlice a, FLSlice b) => _compare(a, b);

  FLSliceResult create(int size) => _new(size);

  FLSliceResult copy(FLSlice slice) => _copy(slice);

  void bindToDartObject(
    Object object,
    FLSliceResult sliceResult, {
    required bool retain,
  }) {
    _bindToDartObject(object, sliceResult, retain.toInt());
  }

  void retainSliceResult(FLSliceResult result) {
    _retainSliceResult(result);
  }

  void releaseSliceResult(FLSliceResult result) {
    _releaseSliceResult(result);
  }

  void releaseStringResult(FLStringResult result) {
    _releaseStringResult(result);
  }
}

// === Slot ====================================================================

class FLSlot extends Opaque {}

typedef _FLSlot_SetNull_C = Void Function(Pointer<FLSlot> slot);
typedef _FLSlot_SetNull = void Function(Pointer<FLSlot> slot);

typedef _FLSlot_SetBool_C = Void Function(Pointer<FLSlot> slot, Uint8 value);
typedef _FLSlot_SetBool = void Function(Pointer<FLSlot> slot, int value);

typedef _FLSlot_SetInt_C = Void Function(Pointer<FLSlot> slot, Int64 value);
typedef _FLSlot_SetInt = void Function(Pointer<FLSlot> slot, int value);

typedef _FLSlot_SetDouble_C = Void Function(Pointer<FLSlot> slot, Double value);
typedef _FLSlot_SetDouble = void Function(Pointer<FLSlot> slot, double value);

typedef _CBLDart_FLSlot_SetString_C = Void Function(
  Pointer<FLSlot> slot,
  FLString value,
);
typedef _CBLDart_FLSlot_SetString = void Function(
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
  SlotBindings(Bindings parent) : super(parent) {
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
    _setString = libs.cblDart
        .lookupFunction<_CBLDart_FLSlot_SetString_C, _CBLDart_FLSlot_SetString>(
      'CBLDart_FLSlot_SetString',
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
  late final _CBLDart_FLSlot_SetString _setString;
  late final _FLSlot_SetData _setData;
  late final _FLSlot_SetValue _setValue;

  void setNull(Pointer<FLSlot> slot) {
    _setNull(slot);
  }

  // ignore: avoid_positional_boolean_parameters
  void setBool(Pointer<FLSlot> slot, bool value) {
    _setBool(slot, value.toInt());
  }

  void setInt(Pointer<FLSlot> slot, int value) {
    _setInt(slot, value);
  }

  void setDouble(Pointer<FLSlot> slot, double value) {
    _setDouble(slot, value);
  }

  void setString(Pointer<FLSlot> slot, String value) {
    withZoneArena(() => _setString(slot, value.toFLStringInArena().ref));
  }

  void setData(Pointer<FLSlot> slot, Data value) {
    _setData(slot, value.toSliceResult().makeGlobal().ref);
  }

  void setValue(Pointer<FLSlot> slot, Pointer<FLValue> value) {
    _setValue(slot, value);
  }
}

// === Doc =====================================================================

class FLDoc extends Opaque {}

typedef _CBLDart_FLDoc_FromResultData_C = Pointer<FLDoc> Function(
  FLSliceResult data,
  Uint8 trust,
  Pointer<Void> sharedKeys,
  FLSlice externalData,
);
typedef _CBLDart_FLDoc_FromResultData = Pointer<FLDoc> Function(
  FLSliceResult data,
  int trust,
  Pointer<Void> sharedKeys,
  FLSlice externalData,
);

typedef _CBLDart_FLDoc_FromJSON = Pointer<FLDoc> Function(
  FLString json,
  Pointer<Uint32> errorOut,
);

typedef _CBLDart_FLDoc_BindToDartObject_C = Void Function(
  Handle object,
  Pointer<FLDoc> doc,
);
typedef _CBLDart_FLDoc_BindToDartObject = void Function(
  Object object,
  Pointer<FLDoc> doc,
);

typedef _FLDoc_GetAllocedData = FLSliceResult Function(Pointer<FLDoc> doc);

typedef _FLDoc_GetRoot = Pointer<FLValue> Function(Pointer<FLDoc> doc);

class DocBindings extends Bindings {
  DocBindings(Bindings parent) : super(parent) {
    _fromResultData = libs.cblDart.lookupFunction<
        _CBLDart_FLDoc_FromResultData_C, _CBLDart_FLDoc_FromResultData>(
      'CBLDart_FLDoc_FromResultData',
      isLeaf: useIsLeaf,
    );
    _fromJSON = libs.cblDart
        .lookupFunction<_CBLDart_FLDoc_FromJSON, _CBLDart_FLDoc_FromJSON>(
      'CBLDart_FLDoc_FromJSON',
      isLeaf: useIsLeaf,
    );
    _bindToDartObject = libs.cblDart.lookupFunction<
        _CBLDart_FLDoc_BindToDartObject_C, _CBLDart_FLDoc_BindToDartObject>(
      'CBLDart_FLDoc_BindToDartObject',
    );
    _getAllocedData =
        libs.cbl.lookupFunction<_FLDoc_GetAllocedData, _FLDoc_GetAllocedData>(
      'FLDoc_GetAllocedData',
      isLeaf: useIsLeaf,
    );
    _getRoot = libs.cbl.lookupFunction<_FLDoc_GetRoot, _FLDoc_GetRoot>(
      'FLDoc_GetRoot',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDart_FLDoc_FromResultData _fromResultData;
  late final _CBLDart_FLDoc_FromJSON _fromJSON;
  late final _CBLDart_FLDoc_BindToDartObject _bindToDartObject;
  late final _FLDoc_GetAllocedData _getAllocedData;
  late final _FLDoc_GetRoot _getRoot;

  Pointer<FLDoc>? fromResultData(
    Data data,
    FLTrust trust,
  ) =>
      _fromResultData(
        data.toSliceResult().makeGlobalResult().ref,
        trust.toInt(),
        nullptr,
        nullFLSlice.ref,
      ).toNullable();

  Pointer<FLDoc> fromJson(String json) => withZoneArena(() =>
      _fromJSON(json.toFLStringInArena().ref, globalFLErrorCode)
          .checkFleeceError());

  void bindToDartObject(Object object, Pointer<FLDoc> doc) {
    _bindToDartObject(object, doc);
  }

  FLSliceResult getAllocedData(Pointer<FLDoc> doc) => _getAllocedData(doc);

  Pointer<FLValue> getRoot(Pointer<FLDoc> doc) => _getRoot(doc);
}

// === Value ===================================================================

class FLValue extends Opaque {}

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

typedef _CBLDart_FLValue_BindToDartObject_C = Void Function(
  Handle object,
  Pointer<FLValue> value,
  Uint8 retain,
);
typedef _CBLDart_FLValue_BindToDartObject = void Function(
  Object object,
  Pointer<FLValue> value,
  int retain,
);

typedef _FLValue_FindDoc = Pointer<FLDoc> Function(Pointer<FLValue>);

typedef _FLValue_GetType_C = Int8 Function(Pointer<FLValue> value);
typedef _FLValue_GetType = int Function(Pointer<FLValue> value);

typedef _FLValue_IsInteger_C = Uint8 Function(Pointer<FLValue> value);
typedef _FLValue_IsInteger = int Function(Pointer<FLValue> value);

typedef _FLValue_IsDouble_C = Uint8 Function(Pointer<FLValue> value);
typedef _FLValue_IsDouble = int Function(Pointer<FLValue> value);

typedef _FLValue_AsBool_C = Uint8 Function(Pointer<FLValue> value);
typedef _FLValue_AsBool = int Function(Pointer<FLValue> value);

typedef _FLValue_AsInt_C = Int64 Function(Pointer<FLValue> value);
typedef _FLValue_AsInt = int Function(Pointer<FLValue> value);

typedef _FLValue_AsDouble_C = Double Function(Pointer<FLValue> value);
typedef _FLValue_AsDouble = double Function(Pointer<FLValue> value);

typedef _CBLDart_FLValue_AsString_C = FLString Function(Pointer<FLValue> value);
typedef _CBLDart_FLValue_AsString = FLString Function(Pointer<FLValue> value);

typedef _CBLDart_FLValue_AsData_C = FLSlice Function(Pointer<FLValue> value);
typedef _CBLDart_FLValue_AsData = FLSlice Function(Pointer<FLValue> value);

typedef _CBLDart_FLValue_ToString_C = FLStringResult Function(
  Pointer<FLValue> value,
);
typedef _CBLDart_FLValue_ToString = FLStringResult Function(
  Pointer<FLValue> value,
);

typedef _FLValue_IsEqual_C = Uint8 Function(
  Pointer<FLValue> v1,
  Pointer<FLValue> v2,
);
typedef _FLValue_IsEqual = int Function(
  Pointer<FLValue> v1,
  Pointer<FLValue> v2,
);

typedef _CBLDart_FLValue_ToJSONX_C = FLStringResult Function(
  Pointer<FLValue> value,
  Uint8 json5,
  Uint8 canonicalForm,
);
typedef _CBLDart_FLValue_ToJSONX = FLStringResult Function(
  Pointer<FLValue> value,
  int json5,
  int canonicalForm,
);

class ValueBindings extends Bindings {
  ValueBindings(Bindings parent) : super(parent) {
    _bindToDartObject = libs.cblDart.lookupFunction<
        _CBLDart_FLValue_BindToDartObject_C, _CBLDart_FLValue_BindToDartObject>(
      'CBLDart_FLValue_BindToDartObject',
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
    _asString = libs.cblDart
        .lookupFunction<_CBLDart_FLValue_AsString_C, _CBLDart_FLValue_AsString>(
      'CBLDart_FLValue_AsString',
      isLeaf: useIsLeaf,
    );
    _asData = libs.cblDart
        .lookupFunction<_CBLDart_FLValue_AsData_C, _CBLDart_FLValue_AsData>(
      'CBLDart_FLValue_AsData',
      isLeaf: useIsLeaf,
    );
    _scalarToString = libs.cblDart
        .lookupFunction<_CBLDart_FLValue_ToString_C, _CBLDart_FLValue_ToString>(
      'CBLDart_FLValue_ToString',
      isLeaf: useIsLeaf,
    );
    _isEqual = libs.cbl.lookupFunction<_FLValue_IsEqual_C, _FLValue_IsEqual>(
      'FLValue_IsEqual',
      isLeaf: useIsLeaf,
    );
    _toJson = libs.cblDart
        .lookupFunction<_CBLDart_FLValue_ToJSONX_C, _CBLDart_FLValue_ToJSONX>(
      'CBLDart_FLValue_ToJSONX',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDart_FLValue_BindToDartObject _bindToDartObject;
  late final _FLValue_FindDoc _findDoc;
  late final _FLValue_GetType _getType;
  late final _FLValue_IsInteger _isInteger;
  late final _FLValue_IsDouble _isDouble;
  late final _FLValue_AsBool _asBool;
  late final _FLValue_AsInt _asInt;
  late final _FLValue_AsDouble _asDouble;
  late final _CBLDart_FLValue_AsString _asString;
  late final _CBLDart_FLValue_AsData _asData;
  late final _CBLDart_FLValue_ToString _scalarToString;
  late final _FLValue_IsEqual _isEqual;
  late final _CBLDart_FLValue_ToJSONX _toJson;

  void bindToDartObject(
    Object object, {
    required Pointer<FLValue> value,
    required bool retain,
  }) {
    _bindToDartObject(object, value, retain.toInt());
  }

  Pointer<FLDoc> findDoc(Pointer<FLValue> value) => _findDoc(value);

  FLValueType getType(Pointer<FLValue> value) =>
      _getType(value).toFLValueType();

  bool isInteger(Pointer<FLValue> value) => _isInteger(value).toBool();

  bool isDouble(Pointer<FLValue> value) => _isDouble(value).toBool();

  bool asBool(Pointer<FLValue> value) => _asBool(value).toBool();

  int asInt(Pointer<FLValue> value) => _asInt(value);

  double asDouble(Pointer<FLValue> value) => _asDouble(value);

  String? asString(Pointer<FLValue> value) => _asString(value).toDartString();

  Data? asData(Pointer<FLValue> value) => _asData(value).toData();

  String? scalarToString(Pointer<FLValue> value) =>
      _scalarToString(value).toDartStringAndRelease();

  bool isEqual(Pointer<FLValue> a, Pointer<FLValue> b) =>
      _isEqual(a, b).toBool();

  String toJSONX(
    Pointer<FLValue> value, {
    required bool json5,
    required bool canonical,
  }) =>
      _toJson(value, json5.toInt(), canonical.toInt())
          .toDartStringAndRelease()!;
}

// === Array ===================================================================

class FLArray extends Opaque {}

typedef _FLArray_Count_C = Uint32 Function(Pointer<FLArray> array);
typedef _FLArray_Count = int Function(Pointer<FLArray> array);

typedef _FLArray_IsEmpty_C = Uint8 Function(Pointer<FLArray> array);
typedef _FLArray_IsEmpty = int Function(Pointer<FLArray> array);

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
  ArrayBindings(Bindings parent) : super(parent) {
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

  bool isEmpty(Pointer<FLArray> array) => _isEmpty(array).toBool();

  Pointer<FLMutableArray>? asMutable(Pointer<FLArray> array) =>
      _asMutable(array).toNullable();

  Pointer<FLValue> get(Pointer<FLArray> array, int index) => _get(array, index);
}

// === MutableArray ============================================================

class FLMutableArray extends Opaque {}

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

typedef _FLMutableArray_IsChanged_C = Uint8 Function(
  Pointer<FLMutableArray> array,
);
typedef _FLMutableArray_IsChanged = int Function(
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
  MutableArrayBindings(Bindings parent) : super(parent) {
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

  Pointer<FLArray> getSource(Pointer<FLMutableArray> array) =>
      _getSource(array);

  bool isChanged(Pointer<FLMutableArray> array) => _isChanged(array).toBool();

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

class FLDict extends Opaque {}

typedef _FLDict_Count_C = Uint32 Function(Pointer<FLDict> dict);
typedef _FLDict_Count = int Function(Pointer<FLDict> dict);

typedef _FLDict_IsEmpty_C = Uint8 Function(Pointer<FLDict> dict);
typedef _FLDict_IsEmpty = int Function(Pointer<FLDict> dict);

typedef _FLDict_AsMutable = Pointer<FLMutableDict> Function(
  Pointer<FLDict> dict,
);

typedef _FLDict_Get = Pointer<FLValue> Function(
  Pointer<FLDict> dict,
  FLString key,
);

class DictBindings extends Bindings {
  DictBindings(Bindings parent) : super(parent) {
    _get = libs.cblDart.lookupFunction<_FLDict_Get, _FLDict_Get>(
      'CBLDart_FLDict_Get',
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

  Pointer<FLValue> get(Pointer<FLDict> dict, String key) =>
      withZoneArena(() => _get(dict, key.toFLStringInArena().ref));

  int count(Pointer<FLDict> dict) => _count(dict);

  bool isEmpty(Pointer<FLDict> dict) => _isEmpty(dict).toBool();

  Pointer<FLMutableDict>? asMutable(Pointer<FLDict> dict) =>
      _asMutable(dict).toNullable();
}

class DictIterator extends Struct {
  // ignore: unused_element
  external Pointer<Void> get _iterator;
  external FLString get _keyString;
  @Uint8()
  external int get _done;
}

extension DictIteratorExt on DictIterator {
  String? get keyString => _keyString.toDartString();
  bool get done => _done.toBool();
}

typedef _CBLDart_FLDictIterator_Begin_C = Pointer<DictIterator> Function(
  Handle object,
  Pointer<FLDict> dict,
);
typedef _CBLDart_FLDictIterator_Begin = Pointer<DictIterator> Function(
  Object object,
  Pointer<FLDict> dict,
);

typedef _CBLDart_FLDictIterator_Next_C = Void Function(
  Pointer<DictIterator> iterator,
);
typedef _CBLDart_FLDictIterator_Next = void Function(
  Pointer<DictIterator> iterator,
);

class DictIteratorBindings extends Bindings {
  DictIteratorBindings(Bindings parent) : super(parent) {
    _begin = libs.cblDart.lookupFunction<_CBLDart_FLDictIterator_Begin_C,
        _CBLDart_FLDictIterator_Begin>(
      'CBLDart_FLDictIterator_Begin',
    );
    _next = libs.cblDart.lookupFunction<_CBLDart_FLDictIterator_Next_C,
        _CBLDart_FLDictIterator_Next>(
      'CBLDart_FLDictIterator_Next',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDart_FLDictIterator_Begin _begin;
  late final _CBLDart_FLDictIterator_Next _next;

  Pointer<DictIterator> begin(Object object, Pointer<FLDict> dict) =>
      _begin(object, dict);

  void next(Pointer<DictIterator> iterator) {
    _next(iterator);
  }
}

// === MutableDict =============================================================

class FLMutableDict extends Opaque {}

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

typedef _FLMutableDict_IsChanged_C = Uint8 Function(
  Pointer<FLMutableDict> dict,
);
typedef _FLMutableDict_IsChanged = int Function(Pointer<FLMutableDict> dict);

typedef _CBLDart_FLMutableDict_Set = Pointer<FLSlot> Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

typedef _CBLDart_FLMutableDict_Remove_C = Void Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);
typedef _CBLDart_FLMutableDict_Remove = void Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

typedef _FLMutableDict_RemoveAll_C = Void Function(Pointer<FLMutableDict> dict);
typedef _FLMutableDict_RemoveAll = void Function(Pointer<FLMutableDict> dict);

typedef _CBLDart_FLMutableDict_GetMutableArray = Pointer<FLMutableArray>
    Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

typedef _CBLDart_FLMutableDict_GetMutableDict = Pointer<FLMutableDict> Function(
  Pointer<FLMutableDict> dict,
  FLString key,
);

class MutableDictBindings extends Bindings {
  MutableDictBindings(Bindings parent) : super(parent) {
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
    _set = libs.cblDart
        .lookupFunction<_CBLDart_FLMutableDict_Set, _CBLDart_FLMutableDict_Set>(
      'CBLDart_FLMutableDict_Set',
      isLeaf: useIsLeaf,
    );
    _remove = libs.cblDart.lookupFunction<_CBLDart_FLMutableDict_Remove_C,
        _CBLDart_FLMutableDict_Remove>(
      'CBLDart_FLMutableDict_Remove',
      isLeaf: useIsLeaf,
    );
    _removeAll = libs.cbl
        .lookupFunction<_FLMutableDict_RemoveAll_C, _FLMutableDict_RemoveAll>(
      'FLMutableDict_RemoveAll',
      isLeaf: useIsLeaf,
    );
    _getMutableArray = libs.cblDart.lookupFunction<
        _CBLDart_FLMutableDict_GetMutableArray,
        _CBLDart_FLMutableDict_GetMutableArray>(
      'CBLDart_FLMutableDict_GetMutableArray',
      isLeaf: useIsLeaf,
    );
    _getMutableDict = libs.cblDart.lookupFunction<
        _CBLDart_FLMutableDict_GetMutableDict,
        _CBLDart_FLMutableDict_GetMutableDict>(
      'CBLDart_FLMutableDict_GetMutableDict',
      isLeaf: useIsLeaf,
    );
  }

  late final _FLDict_MutableCopy _mutableCopy;
  late final _FLMutableDict_New _new;
  late final _FLMutableDict_GetSource _getSource;
  late final _FLMutableDict_IsChanged _isChanged;
  late final _CBLDart_FLMutableDict_Set _set;
  late final _CBLDart_FLMutableDict_Remove _remove;
  late final _FLMutableDict_RemoveAll _removeAll;
  late final _CBLDart_FLMutableDict_GetMutableArray _getMutableArray;
  late final _CBLDart_FLMutableDict_GetMutableDict _getMutableDict;

  Pointer<FLMutableDict> mutableCopy(
    Pointer<FLDict> source,
    Set<FLCopyFlag> flags,
  ) =>
      _mutableCopy(source, flags.toCFlags());

  Pointer<FLMutableDict> create() => _new();

  Pointer<FLDict> getSource(Pointer<FLMutableDict> dict) => _getSource(dict);

  bool isChanged(Pointer<FLMutableDict> dict) => _isChanged(dict).toBool();

  Pointer<FLSlot> set(Pointer<FLMutableDict> dict, String key) =>
      withZoneArena(() => _set(dict, key.toFLStringInArena().ref));

  void remove(Pointer<FLMutableDict> dict, String key) {
    withZoneArena(() => _remove(dict, key.toFLStringInArena().ref));
  }

  void removeAll(Pointer<FLMutableDict> dict) {
    _removeAll(dict);
  }

  Pointer<FLMutableArray>? getMutableArray(
    Pointer<FLMutableDict> array,
    String key,
  ) =>
      withZoneArena(() =>
          _getMutableArray(array, key.toFLStringInArena().ref).toNullable());

  Pointer<FLMutableDict>? getMutableDict(
    Pointer<FLMutableDict> array,
    String key,
  ) =>
      withZoneArena(() =>
          _getMutableDict(array, key.toFLStringInArena().ref).toNullable());
}

// === Decoder =================================================================

enum FLTrust {
  untrusted,
  trusted,
}

extension on FLTrust {
  int toInt() => index;
}

class CBLDart_LoadedFLValue extends Struct {
  @Uint8()
  external int _exists;
  @Int8()
  external int _type;
  @Uint8()
  external int _isInteger;
  @Uint32()
  external int collectionSize;
  @Uint8()
  external int _asBool;
  @Int64()
  external int asInt;
  @Double()
  external double asDouble;
  external FLString asString;
  external FLSlice asData;
  external Pointer<FLValue> asValue;
}

// ignore: camel_case_extensions
extension CBLDart_LoadedFLValueExt on CBLDart_LoadedFLValue {
  bool get exists => _exists.toBool();
  FLValueType get type => _type.toFLValueType();
  bool get isInteger => _isInteger.toBool();
  bool get asBool => _asBool.toBool();
}

typedef _CBLDart_FLData_Dump_C = FLStringResult Function(FLSlice slice);
typedef _CBLDart_FLData_Dump = FLStringResult Function(FLSlice slice);

typedef _CBLDart_FLValue_FromData_C = Void Function(
  FLSlice data,
  Uint8 trust,
  Pointer<CBLDart_LoadedFLValue> out,
);
typedef _CBLDart_FLValue_FromData = void Function(
  FLSlice data,
  int trust,
  Pointer<CBLDart_LoadedFLValue> out,
);

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

class CBLDart_FLDictIterator2 extends Struct {
  @Uint8()
  external int _isDone;
  // ignore: unused_field
  external Pointer<FLString> _keyOut;
  // ignore: unused_field
  external Pointer<CBLDart_LoadedFLValue> _valueOut;
  // ignore: unused_field
  external Pointer<Void> _iterator;
}

// ignore: camel_case_extensions
extension CBLDart_FLDictIterator2Ext on CBLDart_FLDictIterator2 {
  bool get isDone => _isDone.toBool();
}

typedef _CBLDart_FLDictIterator2_Begin_C = Pointer<CBLDart_FLDictIterator2>
    Function(
  Handle object,
  Pointer<FLDict> dict,
  Pointer<FLString> keyOut,
  Pointer<CBLDart_LoadedFLValue> valueOut,
);
typedef _CBLDart_FLDictIterator2_Begin = Pointer<CBLDart_FLDictIterator2>
    Function(
  Object object,
  Pointer<FLDict> dict,
  Pointer<FLString> keyOut,
  Pointer<CBLDart_LoadedFLValue> valueOut,
);

typedef _CBLDart_FLDictIterator2_Next_C = Void Function(
  Pointer<CBLDart_FLDictIterator2> iterator,
);
typedef _CBLDart_FLDictIterator2_Next = void Function(
  Pointer<CBLDart_FLDictIterator2> iterator,
);

class FleeceDecoderBindings extends Bindings {
  FleeceDecoderBindings(Bindings parent) : super(parent) {
    _dumpData = libs.cblDart
        .lookupFunction<_CBLDart_FLData_Dump_C, _CBLDart_FLData_Dump>(
      'CBLDart_FLData_Dump',
      isLeaf: useIsLeaf,
    );
    _getLoadedFLValueFromData = libs.cblDart
        .lookupFunction<_CBLDart_FLValue_FromData_C, _CBLDart_FLValue_FromData>(
      'CBLDart_FLValue_FromData',
      isLeaf: useIsLeaf,
    );
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
        _CBLDart_FLDictIterator2_Begin_C, _CBLDart_FLDictIterator2_Begin>(
      'CBLDart_FLDictIterator2_Begin',
    );
    _dictIteratorNext = libs.cblDart.lookupFunction<
        _CBLDart_FLDictIterator2_Next_C, _CBLDart_FLDictIterator2_Next>(
      'CBLDart_FLDictIterator2_Next',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDart_FLData_Dump _dumpData;
  late final _CBLDart_FLValue_FromData _getLoadedFLValueFromData;
  late final _CBLDart_GetLoadedFLValue _getLoadedFLValue;
  late final _CBLDart_FLArray_GetLoadedFLValue _getLoadedFLValueFromArray;
  late final _CBLDart_FLDict_GetLoadedFLValue _getLoadedFLValueFromDict;
  late final _CBLDart_FLDictIterator2_Begin _dictIteratorBegin;
  late final _CBLDart_FLDictIterator2_Next _dictIteratorNext;

  String dumpData(Data data) => _dumpData(data.toSliceResult().makeGlobal().ref)
      .toDartStringAndRelease()!;

  void getLoadedFLValueFromData(Slice data, FLTrust trust) =>
      _getLoadedFLValueFromData(
        data.makeGlobal().ref,
        trust.toInt(),
        globalLoadedFLValue,
      );

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
    withZoneArena(() {
      _getLoadedFLValueFromDict(
        array,
        key.toFLStringInArena().ref,
        globalLoadedFLValue,
      );
    });
  }

  Pointer<CBLDart_FLDictIterator2> dictIteratorBegin(
    Object object,
    Pointer<FLDict> dict,
    Pointer<FLString> keyOut,
    Pointer<CBLDart_LoadedFLValue> valueOut,
  ) =>
      _dictIteratorBegin(object, dict, keyOut, valueOut);

  void dictIteratorNext(Pointer<CBLDart_FLDictIterator2> iterator) {
    _dictIteratorNext(iterator);
  }
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

class FLEncoder extends Opaque {}

typedef _CBLDart_FLEncoder_BindToDartObject_C = Void Function(
  Handle object,
  Pointer<FLEncoder> encoder,
);
typedef _CBLDart_FLEncoder_BindToDartObject = void Function(
  Object object,
  Pointer<FLEncoder> encoder,
);

typedef _CBLDart_FLEncoder_New_C = Pointer<FLEncoder> Function(
  Uint8 format,
  Uint64 reserveSize,
  Uint8 uniqueStrings,
);
typedef _CBLDart_FLEncoder_New = Pointer<FLEncoder> Function(
  int format,
  int reserveSize,
  int uniqueStrings,
);

typedef _FLEncoder_Reset_C = Void Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_Reset = void Function(Pointer<FLEncoder> encoder);

typedef _CBLDart_FLEncoder_WriteArrayValue_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLArray> array,
  Uint32 index,
);
typedef _CBLDart_FLEncoder_WriteArrayValue = int Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLArray> array,
  int index,
);

typedef _FLEncoder_WriteValue_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLValue> value,
);
typedef _FLEncoder_WriteValue = int Function(
  Pointer<FLEncoder> encoder,
  Pointer<FLValue> value,
);

typedef _FLEncoder_WriteNull_C = Uint8 Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_WriteNull = int Function(Pointer<FLEncoder> encoder);

typedef _FLEncoder_WriteBool_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Uint8 value,
);
typedef _FLEncoder_WriteBool = int Function(
  Pointer<FLEncoder> encoder,
  int value,
);

typedef _FLEncoder_WriteInt_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Int64 value,
);
typedef _FLEncoder_WriteInt = int Function(
  Pointer<FLEncoder> encoder,
  int value,
);

typedef _FLEncoder_WriteDouble_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Double value,
);
typedef _FLEncoder_WriteDouble = int Function(
  Pointer<FLEncoder> encoder,
  double value,
);

typedef _CBLDart_FLEncoder_WriteString_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);
typedef _CBLDart_FLEncoder_WriteString = int Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);

typedef _CBLDart_FLEncoder_WriteData_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  FLSlice value,
);
typedef _CBLDart_FLEncoder_WriteData = int Function(
  Pointer<FLEncoder> encoder,
  FLSlice value,
);

typedef _CBLDart_FLEncoder_WriteJSON_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);
typedef _CBLDart_FLEncoder_WriteJSON = int Function(
  Pointer<FLEncoder> encoder,
  FLString value,
);

typedef _CBLDart_FLEncoder_BeginArray_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Uint64 reserveCount,
);
typedef _CBLDart_FLEncoder_BeginArray = int Function(
  Pointer<FLEncoder> encoder,
  int reserveCount,
);

typedef _FLEncoder_EndArray_C = Uint8 Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_EndArray = int Function(Pointer<FLEncoder> encoder);

typedef _CBLDart_FLEncoder_BeginDict_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  Uint64 reserveCount,
);
typedef _CBLDart_FLEncoder_BeginDict = int Function(
  Pointer<FLEncoder> encoder,
  int reserveCount,
);

typedef _CBLDart_FLEncoder_WriteKey_C = Uint8 Function(
  Pointer<FLEncoder> encoder,
  FLString key,
);
typedef _CBLDart_FLEncoder_WriteKey = int Function(
  Pointer<FLEncoder> encoder,
  FLString key,
);

typedef _FLEncoder_EndDict_C = Uint8 Function(Pointer<FLEncoder> encoder);
typedef _FLEncoder_EndDict = int Function(Pointer<FLEncoder> encoder);

typedef _CBLDart_FLEncoder_Finish_C = FLSliceResult Function(
  Pointer<FLEncoder> encoder,
  Pointer<Uint32> errorOut,
);
typedef _CBLDart_FLEncoder_Finish = FLSliceResult Function(
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
  FleeceEncoderBindings(Bindings parent) : super(parent) {
    _bindToDartObject = libs.cblDart.lookupFunction<
        _CBLDart_FLEncoder_BindToDartObject_C,
        _CBLDart_FLEncoder_BindToDartObject>(
      'CBLDart_FLEncoder_BindToDartObject',
    );
    _new = libs.cblDart
        .lookupFunction<_CBLDart_FLEncoder_New_C, _CBLDart_FLEncoder_New>(
      'CBLDart_FLEncoder_New',
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
    _writeString = libs.cblDart.lookupFunction<_CBLDart_FLEncoder_WriteString_C,
        _CBLDart_FLEncoder_WriteString>(
      'CBLDart_FLEncoder_WriteString',
      isLeaf: useIsLeaf,
    );
    _writeData = libs.cblDart.lookupFunction<_CBLDart_FLEncoder_WriteData_C,
        _CBLDart_FLEncoder_WriteData>(
      'CBLDart_FLEncoder_WriteData',
      isLeaf: useIsLeaf,
    );
    _writeJSON = libs.cblDart.lookupFunction<_CBLDart_FLEncoder_WriteJSON_C,
        _CBLDart_FLEncoder_WriteJSON>(
      'CBLDart_FLEncoder_WriteJSON',
      isLeaf: useIsLeaf,
    );
    _beginArray = libs.cblDart.lookupFunction<_CBLDart_FLEncoder_BeginArray_C,
        _CBLDart_FLEncoder_BeginArray>(
      'CBLDart_FLEncoder_BeginArray',
      isLeaf: useIsLeaf,
    );
    _endArray =
        libs.cbl.lookupFunction<_FLEncoder_EndArray_C, _FLEncoder_EndArray>(
      'FLEncoder_EndArray',
      isLeaf: useIsLeaf,
    );
    _beginDict = libs.cblDart.lookupFunction<_CBLDart_FLEncoder_BeginDict_C,
        _CBLDart_FLEncoder_BeginDict>(
      'CBLDart_FLEncoder_BeginDict',
      isLeaf: useIsLeaf,
    );
    _writeKey = libs.cblDart.lookupFunction<_CBLDart_FLEncoder_WriteKey_C,
        _CBLDart_FLEncoder_WriteKey>(
      'CBLDart_FLEncoder_WriteKey',
      isLeaf: useIsLeaf,
    );
    _endDict =
        libs.cbl.lookupFunction<_FLEncoder_EndDict_C, _FLEncoder_EndDict>(
      'FLEncoder_EndDict',
      isLeaf: useIsLeaf,
    );
    _finish = libs.cblDart
        .lookupFunction<_CBLDart_FLEncoder_Finish_C, _CBLDart_FLEncoder_Finish>(
      'CBLDart_FLEncoder_Finish',
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

  late final _CBLDart_FLEncoder_BindToDartObject _bindToDartObject;
  late final _CBLDart_FLEncoder_New _new;
  late final _FLEncoder_Reset _reset;
  late final _CBLDart_FLEncoder_WriteArrayValue _writeArrayValue;
  late final _FLEncoder_WriteValue _writeValue;
  late final _FLEncoder_WriteNull _writeNull;
  late final _FLEncoder_WriteBool _writeBool;
  late final _FLEncoder_WriteInt _writeInt;
  late final _FLEncoder_WriteDouble _writeDouble;
  late final _CBLDart_FLEncoder_WriteString _writeString;
  late final _CBLDart_FLEncoder_WriteData _writeData;
  late final _CBLDart_FLEncoder_WriteJSON _writeJSON;
  late final _CBLDart_FLEncoder_BeginArray _beginArray;
  late final _FLEncoder_EndArray _endArray;
  late final _CBLDart_FLEncoder_BeginDict _beginDict;
  late final _CBLDart_FLEncoder_WriteKey _writeKey;
  late final _FLEncoder_EndDict _endDict;
  late final _CBLDart_FLEncoder_Finish _finish;
  late final _FLEncoder_GetError __getError;
  late final _FLEncoder_GetErrorMessage __getErrorMessage;

  void bindToDartObject(Object object, Pointer<FLEncoder> encoder) {
    _bindToDartObject(object, encoder);
  }

  Pointer<FLEncoder> create({
    required FLEncoderFormat format,
    required int reserveSize,
    required bool uniqueStrings,
  }) =>
      _new(format.toInt(), reserveSize, uniqueStrings.toInt());

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

  // ignore: avoid_positional_boolean_parameters
  void writeBool(Pointer<FLEncoder> encoder, bool value) {
    _checkError(encoder, _writeBool(encoder, value.toInt()));
  }

  void writeInt(Pointer<FLEncoder> encoder, int value) {
    _checkError(encoder, _writeInt(encoder, value));
  }

  void writeDouble(Pointer<FLEncoder> encoder, double value) {
    _checkError(encoder, _writeDouble(encoder, value));
  }

  void writeString(Pointer<FLEncoder> encoder, String value) {
    withZoneArena(() {
      _checkError(
        encoder,
        _writeString(encoder, value.toFLStringInArena().ref),
      );
    });
  }

  void writeData(Pointer<FLEncoder> encoder, Data value) {
    _checkError(
      encoder,
      _writeData(encoder, value.toSliceResult().makeGlobal().ref),
    );
  }

  void writeJSON(Pointer<FLEncoder> encoder, Data value) {
    _checkError(
      encoder,
      _writeJSON(
        encoder,
        value.toSliceResult().makeGlobal().cast<FLString>().ref,
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

  void writeKey(Pointer<FLEncoder> encoder, String value) {
    withZoneArena(() {
      _checkError(
        encoder,
        _writeKey(encoder, value.toFLStringInArena().ref),
      );
    });
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
    final mayHaveError = (result is int && !result.toBool()) ||
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
  FleeceBindings(Bindings parent) : super(parent) {
    slice = SliceBindings(this);
    slot = SlotBindings(this);
    doc = DocBindings(this);
    value = ValueBindings(this);
    array = ArrayBindings(this);
    mutableArray = MutableArrayBindings(this);
    dict = DictBindings(this);
    dictIterator = DictIteratorBindings(this);
    mutableDict = MutableDictBindings(this);
    decoder = FleeceDecoderBindings(this);
    encoder = FleeceEncoderBindings(this);
  }

  late final SliceBindings slice;
  late final SlotBindings slot;
  late final DocBindings doc;
  late final ValueBindings value;
  late final ArrayBindings array;
  late final MutableArrayBindings mutableArray;
  late final DictBindings dict;
  late final DictIteratorBindings dictIterator;
  late final MutableDictBindings mutableDict;
  late final FleeceDecoderBindings decoder;
  late final FleeceEncoderBindings encoder;
}
