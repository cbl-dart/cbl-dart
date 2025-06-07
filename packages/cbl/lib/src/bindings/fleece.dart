import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'data.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

export 'cblite.dart'
    show
        FLArray,
        FLCopyFlags,
        FLDict,
        FLDictKey,
        FLDoc,
        FLEncoder,
        FLEncoderFormat,
        FLError,
        FLMutableArray,
        FLMutableDict,
        FLSharedKeys,
        FLSliceResult,
        FLSlot,
        FLString,
        FLStringResult,
        FLTrust,
        FLValue,
        FLValueType;
export 'cblitedart.dart'
    show
        KnownSharedKeys,
        CBLDart_LoadedFLValue,
        CBLDart_LoadedDictKey,
        CBLDart_FLDictIterator,
        CBLDart_FLArrayIterator;

// === Error ===================================================================

enum FLError {
  noError(cblite_lib.FLError.kFLNoError),
  memoryError(cblite_lib.FLError.kFLMemoryError),
  outOfRange(cblite_lib.FLError.kFLOutOfRange),
  invalidData(cblite_lib.FLError.kFLInvalidData),
  encodeError(cblite_lib.FLError.kFLEncodeError),
  jsonError(cblite_lib.FLError.kFLJSONError),
  unknownValue(cblite_lib.FLError.kFLUnknownValue),
  internalError(cblite_lib.FLError.kFLInternalError),
  notFound(cblite_lib.FLError.kFLNotFound),
  sharedKeysStateError(cblite_lib.FLError.kFLSharedKeysStateError),
  posixError(cblite_lib.FLError.kFLPOSIXError),
  unsupported(cblite_lib.FLError.kFLUnsupported);

  const FLError(this.value);

  static FLError fromValue(int value) => switch (value) {
    cblite_lib.FLError.kFLNoError => noError,
    cblite_lib.FLError.kFLMemoryError => memoryError,
    cblite_lib.FLError.kFLOutOfRange => outOfRange,
    cblite_lib.FLError.kFLInvalidData => invalidData,
    cblite_lib.FLError.kFLEncodeError => encodeError,
    cblite_lib.FLError.kFLJSONError => jsonError,
    cblite_lib.FLError.kFLUnknownValue => unknownValue,
    cblite_lib.FLError.kFLInternalError => internalError,
    cblite_lib.FLError.kFLNotFound => notFound,
    _ => throw ArgumentError('Unknown value for FLError: $value'),
  };

  final int value;
}

void _checkFleeceError() {
  final code = FLError.fromValue(globalFLErrorCode.value);
  if (code != FLError.noError) {
    throw createCouchbaseLiteException(
      domain: CBLErrorDomain.fleece,
      code: code,
      message: 'Fleece error',
    );
  }
}

extension _FleeceErrorExt<T> on T {
  T checkFleeceError() {
    final self = this;
    if (this == nullptr ||
        self is cblite_lib.FLSliceResult && self.buf == nullptr) {
      _checkFleeceError();
    }
    return this;
  }
}

// === Slice ===================================================================

extension FLSliceExt on cblite_lib.FLSlice {
  bool get isNull => buf == nullptr;
  Data? toData() => SliceResult.fromFLSlice(this)?.toData();
}

extension FLResultSliceExt on cblite_lib.FLSliceResult {
  bool get isNull => buf == nullptr;
  Data? toData({bool retain = false}) =>
      SliceResult.fromFLSliceResult(this, retain: retain)?.toData();
}

extension FLStringExt on cblite_lib.FLString {
  bool get isNull => buf == nullptr;
  String? toDartString() =>
      isNull ? null : buf.cast<Utf8>().toDartString(length: size);
}

extension FLStringResultExt on cblite_lib.FLStringResult {
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

final class SliceBindings extends Bindings {
  SliceBindings(super.libraries);

  late final _sliceResultFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_FLSliceResult_ReleaseByBuf.cast(),
  );

  bool equal(cblite_lib.FLSlice a, cblite_lib.FLSlice b) =>
      cblite.FLSlice_Equal(a, b);

  int compare(cblite_lib.FLSlice a, cblite_lib.FLSlice b) =>
      cblite.FLSlice_Compare(a, b);

  cblite_lib.FLSliceResult create(int size) => cblite.FLSliceResult_New(size);

  cblite_lib.FLSliceResult copy(cblite_lib.FLSlice slice) =>
      cblite.FLSlice_Copy(slice);

  void bindToDartObject(
    Finalizable object, {
    required Pointer<Void> buf,
    required bool retain,
  }) {
    if (retain) {
      cblitedart.CBLDart_FLSliceResult_RetainByBuf(buf);
    }

    _sliceResultFinalizer.attach(object, buf.cast());
  }

  void retainSliceResultByBuf(Pointer<Void> buf) {
    cblitedart.CBLDart_FLSliceResult_RetainByBuf(buf);
  }

  void releaseSliceResultByBuf(Pointer<Void> buf) {
    cblitedart.CBLDart_FLSliceResult_ReleaseByBuf(buf);
  }
}

// === SharedKeys ==============================================================

final class SharedKeysBindings extends Bindings {
  SharedKeysBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblite.addresses.FLSharedKeys_Release.cast(),
  );

  cblite_lib.FLSharedKeys create() => cblite.FLSharedKeys_New();

  void bindToDartObject(
    Finalizable object,
    cblite_lib.FLSharedKeys sharedKeys, {
    required bool retain,
  }) {
    if (retain) {
      cblite.FLSharedKeys_Retain(sharedKeys);
    }

    _finalizer.attach(object, sharedKeys.cast());
  }

  int count(cblite_lib.FLSharedKeys sharedKeys) =>
      cblite.FLSharedKeys_Count(sharedKeys);
}

// === Slot ====================================================================

final class SlotBindings extends Bindings {
  SlotBindings(super.libraries);

  void setNull(cblite_lib.FLSlot slot) {
    cblite.FLSlot_SetNull(slot);
  }

  // ignore: avoid_positional_boolean_parameters
  void setBool(cblite_lib.FLSlot slot, bool value) {
    cblite.FLSlot_SetBool(slot, value);
  }

  void setInt(cblite_lib.FLSlot slot, int value) {
    cblite.FLSlot_SetInt(slot, value);
  }

  void setDouble(cblite_lib.FLSlot slot, double value) {
    cblite.FLSlot_SetDouble(slot, value);
  }

  void setString(cblite_lib.FLSlot slot, String value) {
    runWithSingleFLString(value, (flValue) {
      cblite.FLSlot_SetString(slot, flValue);
    });
  }

  void setData(cblite_lib.FLSlot slot, Data value) {
    cblite.FLSlot_SetData(slot, value.toSliceResult().makeGlobal().ref);
  }

  void setValue(cblite_lib.FLSlot slot, cblite_lib.FLValue value) {
    cblite.FLSlot_SetValue(slot, value);
  }
}

// === Doc =====================================================================

enum FLTrust {
  untrusted(cblite_lib.FLTrust.kFLUntrusted),
  trusted(cblite_lib.FLTrust.kFLTrusted);

  const FLTrust(this.value);

  static FLTrust fromValue(int value) => switch (value) {
    cblite_lib.FLTrust.kFLUntrusted => untrusted,
    cblite_lib.FLTrust.kFLTrusted => trusted,
    _ => throw ArgumentError('Unknown value for FLTrust: $value'),
  };

  final int value;
}

final class DocBindings extends Bindings {
  DocBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblite.addresses.FLDoc_Release.cast(),
  );

  cblite_lib.FLDoc fromResultData(
    Data data,
    FLTrust trust,
    cblite_lib.FLSharedKeys? sharedKeys,
  ) {
    final sliceResult = data.toSliceResult();
    return cblite.FLDoc_FromResultData(
      sliceResult.makeGlobalResult().ref,
      trust.value,
      sharedKeys ?? nullptr,
      nullFLSlice.ref,
    );
  }

  cblite_lib.FLDoc fromJson(String json) => runWithSingleFLString(
    json,
    (flJson) =>
        cblite.FLDoc_FromJSON(flJson, globalFLErrorCode).checkFleeceError(),
  );

  void bindToDartObject(Finalizable object, cblite_lib.FLDoc doc) {
    _finalizer.attach(
      object,
      doc.cast(),
      externalSize: getAllocedData(doc)?.size,
    );
  }

  SliceResult? getAllocedData(cblite_lib.FLDoc doc) =>
      SliceResult.fromFLSliceResult(cblite.FLDoc_GetAllocedData(doc));

  cblite_lib.FLValue getRoot(cblite_lib.FLDoc doc) => cblite.FLDoc_GetRoot(doc);

  cblite_lib.FLSharedKeys? getSharedKeys(cblite_lib.FLDoc doc) =>
      cblite.FLDoc_GetSharedKeys(doc).toNullable();
}

// === Value ===================================================================

enum FLValueType {
  undefined(cblite_lib.FLValueType.kFLUndefined),
  null$(cblite_lib.FLValueType.kFLNull),
  boolean(cblite_lib.FLValueType.kFLBoolean),
  number(cblite_lib.FLValueType.kFLNumber),
  string(cblite_lib.FLValueType.kFLString),
  data(cblite_lib.FLValueType.kFLData),
  array(cblite_lib.FLValueType.kFLArray),
  dict(cblite_lib.FLValueType.kFLDict);

  const FLValueType(this.value);

  static FLValueType fromValue(int value) => switch (value) {
    cblite_lib.FLValueType.kFLUndefined => undefined,
    cblite_lib.FLValueType.kFLNull => null$,
    cblite_lib.FLValueType.kFLBoolean => boolean,
    cblite_lib.FLValueType.kFLNumber => number,
    cblite_lib.FLValueType.kFLString => string,
    cblite_lib.FLValueType.kFLData => data,
    cblite_lib.FLValueType.kFLArray => array,
    cblite_lib.FLValueType.kFLDict => dict,
    _ => throw ArgumentError('Unknown value for FLValueType: $value'),
  };

  final int value;
}

final class ValueBindings extends Bindings {
  ValueBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblite.addresses.FLValue_Release.cast(),
  );

  void bindToDartObject(
    Finalizable object, {
    required cblite_lib.FLValue value,
    required bool retain,
  }) {
    if (retain) {
      cblite.FLValue_Retain(value);
    }
    _finalizer.attach(object, value.cast());
  }

  cblite_lib.FLValue? fromData(SliceResult data, FLTrust trust) =>
      cblite.FLValue_FromData(data.makeGlobal().ref, trust.value).toNullable();

  cblite_lib.FLDoc? findDoc(cblite_lib.FLValue value) =>
      cblite.FLValue_FindDoc(value).toNullable();

  FLValueType getType(cblite_lib.FLValue value) =>
      FLValueType.fromValue(cblite.FLValue_GetType(value));

  bool isInteger(cblite_lib.FLValue value) => cblite.FLValue_IsInteger(value);

  bool isDouble(cblite_lib.FLValue value) => cblite.FLValue_IsDouble(value);

  bool asBool(cblite_lib.FLValue value) => cblite.FLValue_AsBool(value);

  int asInt(cblite_lib.FLValue value) => cblite.FLValue_AsInt(value);

  double asDouble(cblite_lib.FLValue value) => cblite.FLValue_AsDouble(value);

  String? asString(cblite_lib.FLValue value) =>
      cblite.FLValue_AsString(value).toDartString();

  Data? asData(cblite_lib.FLValue value) =>
      cblite.FLValue_AsData(value).toData();

  String? scalarToString(cblite_lib.FLValue value) =>
      cblite.FLValue_ToString(value).toDartStringAndRelease();

  bool isEqual(cblite_lib.FLValue a, cblite_lib.FLValue b) =>
      cblite.FLValue_IsEqual(a, b);

  void retain(cblite_lib.FLValue value) => cblite.FLValue_Retain(value);

  void release(cblite_lib.FLValue value) => cblite.FLValue_Release(value);

  String toJSONX(
    cblite_lib.FLValue value, {
    required bool json5,
    required bool canonical,
  }) =>
      cblite.FLValue_ToJSONX(value, json5, canonical).toDartStringAndRelease()!;
}

// === Array ===================================================================

final class ArrayBindings extends Bindings {
  ArrayBindings(super.libraries);

  int count(cblite_lib.FLArray array) => cblite.FLArray_Count(array);

  bool isEmpty(cblite_lib.FLArray array) => cblite.FLArray_IsEmpty(array);

  cblite_lib.FLMutableArray? asMutable(cblite_lib.FLArray array) =>
      cblite.FLArray_AsMutable(array).toNullable();

  cblite_lib.FLValue get(cblite_lib.FLArray array, int index) =>
      cblite.FLArray_Get(array, index);
}

// === MutableArray ============================================================

enum FLCopyFlags {
  defaultCopy(cblite_lib.FLCopyFlags.kFLDefaultCopy),
  deepCopy(cblite_lib.FLCopyFlags.kFLDeepCopy),
  copyImmutables(cblite_lib.FLCopyFlags.kFLCopyImmutables),
  deepCopyImmutables(cblite_lib.FLCopyFlags.kFLDeepCopyImmutables);

  const FLCopyFlags(this.value);

  static FLCopyFlags fromValue(int value) => switch (value) {
    cblite_lib.FLCopyFlags.kFLDefaultCopy => defaultCopy,
    cblite_lib.FLCopyFlags.kFLDeepCopy => deepCopy,
    cblite_lib.FLCopyFlags.kFLCopyImmutables => copyImmutables,
    cblite_lib.FLCopyFlags.kFLDeepCopyImmutables => deepCopyImmutables,
    _ => throw ArgumentError('Unknown value for FLCopyFlags: $value'),
  };

  final int value;
}

final class MutableArrayBindings extends Bindings {
  MutableArrayBindings(super.libraries);

  cblite_lib.FLMutableArray mutableCopy(
    cblite_lib.FLArray array,
    FLCopyFlags flags,
  ) => cblite.FLArray_MutableCopy(array, flags.value);

  cblite_lib.FLMutableArray create() => cblite.FLMutableArray_New();

  cblite_lib.FLArray? getSource(cblite_lib.FLMutableArray array) =>
      cblite.FLMutableArray_GetSource(array).toNullable();

  bool isChanged(cblite_lib.FLMutableArray array) =>
      cblite.FLMutableArray_IsChanged(array);

  cblite_lib.FLSlot set(cblite_lib.FLMutableArray array, int index) =>
      cblite.FLMutableArray_Set(array, index);

  cblite_lib.FLSlot append(cblite_lib.FLMutableArray array) =>
      cblite.FLMutableArray_Append(array);

  void insert(cblite_lib.FLMutableArray array, int index, int count) =>
      cblite.FLMutableArray_Insert(array, index, count);

  void remove(cblite_lib.FLMutableArray array, int firstIndex, int count) =>
      cblite.FLMutableArray_Remove(array, firstIndex, count);

  void resize(cblite_lib.FLMutableArray array, int size) =>
      cblite.FLMutableArray_Resize(array, size);

  cblite_lib.FLMutableArray? getMutableArray(
    cblite_lib.FLMutableArray array,
    int index,
  ) => cblite.FLMutableArray_GetMutableArray(array, index).toNullable();

  cblite_lib.FLMutableDict? getMutableDict(
    cblite_lib.FLMutableArray array,
    int index,
  ) => cblite.FLMutableArray_GetMutableDict(array, index).toNullable();
}

// === Dict ====================================================================

final class DictBindings extends Bindings {
  DictBindings(super.libraries);

  cblite_lib.FLValue? get(cblite_lib.FLDict dict, String key) =>
      runWithSingleFLString(
        key,
        (flKey) => cblite.FLDict_Get(dict, flKey),
      ).toNullable();

  cblite_lib.FLValue? getWithFLString(
    cblite_lib.FLDict dict,
    cblite_lib.FLString key,
  ) => cblite.FLDict_Get(dict, key).toNullable();

  int count(cblite_lib.FLDict dict) => cblite.FLDict_Count(dict);

  bool isEmpty(cblite_lib.FLDict dict) => cblite.FLDict_IsEmpty(dict);

  cblite_lib.FLMutableDict? asMutable(cblite_lib.FLDict dict) =>
      cblite.FLDict_AsMutable(dict).toNullable();
}

final class DictKeyBindings extends Bindings {
  DictKeyBindings(super.libraries);

  void init(cblite_lib.FLDictKey dictKey, cblite_lib.FLString key) {
    final state = cblite.FLDictKey_Init(key);
    dictKey
      ..private1 = state.private1
      ..private2 = state.private2
      ..private3 = state.private3
      ..private4 = state.private4
      ..private5 = state.private5;
  }

  cblite_lib.FLValue? getWithKey(
    cblite_lib.FLDict dict,
    Pointer<cblite_lib.FLDictKey> key,
  ) => cblite.FLDict_GetWithKey(dict, key).toNullable();
}

// === MutableDict =============================================================

final class MutableDictBindings extends Bindings {
  MutableDictBindings(super.libraries);

  cblite_lib.FLMutableDict mutableCopy(
    cblite_lib.FLDict source,
    FLCopyFlags flags,
  ) => cblite.FLDict_MutableCopy(source, flags.value);

  cblite_lib.FLMutableDict create() => cblite.FLMutableDict_New();

  cblite_lib.FLDict? getSource(cblite_lib.FLMutableDict dict) =>
      cblite.FLMutableDict_GetSource(dict).toNullable();

  bool isChanged(cblite_lib.FLMutableDict dict) =>
      cblite.FLMutableDict_IsChanged(dict);

  cblite_lib.FLSlot set(cblite_lib.FLMutableDict dict, String key) =>
      runWithSingleFLString(
        key,
        (flKey) => cblite.FLMutableDict_Set(dict, flKey),
      );

  void remove(cblite_lib.FLMutableDict dict, String key) {
    runWithSingleFLString(
      key,
      (flKey) => cblite.FLMutableDict_Remove(dict, flKey),
    );
  }

  void removeAll(cblite_lib.FLMutableDict dict) {
    cblite.FLMutableDict_RemoveAll(dict);
  }

  cblite_lib.FLMutableArray? getMutableArray(
    cblite_lib.FLMutableDict array,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.FLMutableDict_GetMutableArray(array, flKey).toNullable(),
  );

  cblite_lib.FLMutableDict? getMutableDict(
    cblite_lib.FLMutableDict array,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.FLMutableDict_GetMutableDict(array, flKey).toNullable(),
  );
}

// === Decoder =================================================================

@pragma('vm:prefer-inline')
String decodeFLString(Pointer<Void> buf, int size) =>
    utf8.decode(buf.cast<Uint8>().asTypedList(size));

// ignore: camel_case_extensions
extension CBLDart_LoadedFLValueExt on cblitedart_lib.CBLDart_LoadedFLValue {
  FLValueType get typeEnum => FLValueType.fromValue(type);
}

final class FleeceDecoderBindings extends Bindings {
  FleeceDecoderBindings(super.libraries);

  late final _knownSharedKeysFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_KnownSharedKeys_Delete.cast(),
  );
  late final _dictIteratorFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_FLDictIterator_Delete.cast(),
  );
  late final _arrayIteratorFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_FLArrayIterator_Delete.cast(),
  );

  String dumpData(Data data) => cblite.FLData_Dump(
    data.toSliceResult().makeGlobal().ref,
  ).toDartStringAndRelease()!;

  Pointer<cblitedart_lib.KnownSharedKeys> createKnownSharedKeys(
    Finalizable object,
  ) {
    final result = cblitedart.CBLDart_KnownSharedKeys_New();
    _knownSharedKeysFinalizer.attach(object, result.cast());
    return result;
  }

  void getLoadedValue(cblite_lib.FLValue value) {
    cblitedart.CBLDart_GetLoadedFLValue(value, globalLoadedFLValue);
  }

  void getLoadedValueFromArray(cblite_lib.FLArray array, int index) {
    cblitedart.CBLDart_FLArray_GetLoadedFLValue(
      array,
      index,
      globalLoadedFLValue,
    );
  }

  void getLoadedValueFromDict(cblite_lib.FLDict array, String key) {
    runWithSingleFLString(key, (flKey) {
      cblitedart.CBLDart_FLDict_GetLoadedFLValue(
        array,
        flKey,
        globalLoadedFLValue,
      );
    });
  }

  Pointer<cblitedart_lib.CBLDart_FLDictIterator> dictIteratorBegin(
    Finalizable? object,
    cblite_lib.FLDict dict,
    Pointer<cblitedart_lib.KnownSharedKeys> knownSharedKeys,
    Pointer<cblitedart_lib.CBLDart_LoadedDictKey> keyOut,
    Pointer<cblitedart_lib.CBLDart_LoadedFLValue> valueOut, {
    required bool preLoad,
  }) {
    final result = cblitedart.CBLDart_FLDictIterator_Begin(
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

  bool dictIteratorNext(
    Pointer<cblitedart_lib.CBLDart_FLDictIterator> iterator,
  ) => cblitedart.CBLDart_FLDictIterator_Next(iterator);

  Pointer<cblitedart_lib.CBLDart_FLArrayIterator> arrayIteratorBegin(
    Finalizable? object,
    cblite_lib.FLArray array,
    Pointer<cblitedart_lib.CBLDart_LoadedFLValue> valueOut,
  ) {
    final result = cblitedart.CBLDart_FLArrayIterator_Begin(
      array,
      valueOut,
      object == null,
    );

    if (object != null) {
      _arrayIteratorFinalizer.attach(object, result.cast());
    }

    return result;
  }

  bool arrayIteratorNext(
    Pointer<cblitedart_lib.CBLDart_FLArrayIterator> iterator,
  ) => cblitedart.CBLDart_FLArrayIterator_Next(iterator);
}

// === Encoder =================================================================

enum FLEncoderFormat {
  fleece(cblite_lib.FLEncoderFormat.kFLEncodeFleece),
  json(cblite_lib.FLEncoderFormat.kFLEncodeJSON),
  json5(cblite_lib.FLEncoderFormat.kFLEncodeJSON5);

  const FLEncoderFormat(this.value);

  static FLEncoderFormat fromValue(int value) => switch (value) {
    cblite_lib.FLEncoderFormat.kFLEncodeFleece => fleece,
    cblite_lib.FLEncoderFormat.kFLEncodeJSON => json,
    cblite_lib.FLEncoderFormat.kFLEncodeJSON5 => json5,
    _ => throw ArgumentError('Unknown value for FLEncoderFormat: $value'),
  };

  final int value;
}

final class FleeceEncoderBindings extends Bindings {
  FleeceEncoderBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblite.addresses.FLEncoder_Free.cast(),
  );

  void bindToDartObject(Finalizable object, cblite_lib.FLEncoder encoder) {
    _finalizer.attach(object, encoder.cast());
  }

  cblite_lib.FLEncoder create({
    required FLEncoderFormat format,
    required int reserveSize,
    required bool uniqueStrings,
  }) =>
      cblite.FLEncoder_NewWithOptions(format.value, reserveSize, uniqueStrings);

  void setSharedKeys(
    cblite_lib.FLEncoder encoder,
    cblite_lib.FLSharedKeys keys,
  ) {
    cblite.FLEncoder_SetSharedKeys(encoder, keys);
  }

  void reset(cblite_lib.FLEncoder encoder) {
    cblite.FLEncoder_Reset(encoder);
  }

  void writeArrayValue(
    cblite_lib.FLEncoder encoder,
    cblite_lib.FLArray array,
    int index,
  ) {
    _checkError(
      encoder,
      cblitedart.CBLDart_FLEncoder_WriteArrayValue(encoder, array, index),
    );
  }

  void writeValue(cblite_lib.FLEncoder encoder, cblite_lib.FLValue value) {
    if (value == nullptr) {
      throw ArgumentError.value(value, 'value', 'must not be `nullptr`');
    }

    _checkError(encoder, cblite.FLEncoder_WriteValue(encoder, value));
  }

  void writeNull(cblite_lib.FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_WriteNull(encoder));
  }

  // ignore: avoid_positional_boolean_parameters
  void writeBool(cblite_lib.FLEncoder encoder, bool value) {
    _checkError(encoder, cblite.FLEncoder_WriteBool(encoder, value));
  }

  void writeInt(cblite_lib.FLEncoder encoder, int value) {
    _checkError(encoder, cblite.FLEncoder_WriteInt(encoder, value));
  }

  void writeDouble(cblite_lib.FLEncoder encoder, double value) {
    _checkError(encoder, cblite.FLEncoder_WriteDouble(encoder, value));
  }

  void writeString(cblite_lib.FLEncoder encoder, String value) {
    runWithSingleFLString(value, (flValue) {
      _checkError(encoder, cblite.FLEncoder_WriteString(encoder, flValue));
    });
  }

  void writeData(cblite_lib.FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cblite.FLEncoder_WriteData(encoder, sliceResult.makeGlobal().ref),
    );
  }

  void writeJSON(cblite_lib.FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cblite.FLEncoder_ConvertJSON(
        encoder,
        sliceResult.makeGlobal().cast<cblite_lib.FLString>().ref,
      ),
    );
  }

  void beginArray(cblite_lib.FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cblite.FLEncoder_BeginArray(encoder, reserveCount));
  }

  void endArray(cblite_lib.FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_EndArray(encoder));
  }

  void beginDict(cblite_lib.FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cblite.FLEncoder_BeginDict(encoder, reserveCount));
  }

  void writeKey(cblite_lib.FLEncoder encoder, String key) {
    runWithSingleFLString(key, (flKey) {
      _checkError(encoder, cblite.FLEncoder_WriteKey(encoder, flKey));
    });
  }

  void writeKeyFLString(cblite_lib.FLEncoder encoder, cblite_lib.FLString key) {
    _checkError(encoder, cblite.FLEncoder_WriteKey(encoder, key));
  }

  void writeKeyValue(cblite_lib.FLEncoder encoder, cblite_lib.FLValue key) {
    _checkError(encoder, cblite.FLEncoder_WriteKeyValue(encoder, key));
  }

  void endDict(cblite_lib.FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_EndDict(encoder));
  }

  Data? finish(cblite_lib.FLEncoder encoder) => _checkError(
    encoder,
    cblite.FLEncoder_Finish(encoder, globalFLErrorCode),
  ).let(SliceResult.fromFLSliceResult)?.toData();

  FLError _getError(cblite_lib.FLEncoder encoder) =>
      FLError.fromValue(cblite.FLEncoder_GetError(encoder));

  String _getErrorMessage(cblite_lib.FLEncoder encoder) =>
      cblite.FLEncoder_GetErrorMessage(
        encoder,
      ).cast<Utf8>().toDartStringAndFree();

  T _checkError<T>(cblite_lib.FLEncoder encoder, T result) {
    final mayHaveError =
        (result is bool && !result) ||
        (result is cblite_lib.FLSliceResult && result.buf == nullptr);

    if (mayHaveError) {
      final errorCode = _getError(encoder);
      if (errorCode == FLError.noError) {
        return result;
      }

      throw createCouchbaseLiteException(
        domain: CBLErrorDomain.fleece,
        code: errorCode,
        message: _getErrorMessage(encoder),
      );
    }

    return result;
  }
}

// === FleeceBindings ==========================================================

final class FleeceBindings extends Bindings {
  FleeceBindings(super.libraries)
    : slice = SliceBindings(libraries),
      sharedKeys = SharedKeysBindings(libraries),
      slot = SlotBindings(libraries),
      doc = DocBindings(libraries),
      value = ValueBindings(libraries),
      array = ArrayBindings(libraries),
      mutableArray = MutableArrayBindings(libraries),
      dict = DictBindings(libraries),
      dictKey = DictKeyBindings(libraries),
      mutableDict = MutableDictBindings(libraries),
      decoder = FleeceDecoderBindings(libraries),
      encoder = FleeceEncoderBindings(libraries);

  final SliceBindings slice;
  final SharedKeysBindings sharedKeys;
  final SlotBindings slot;
  final DocBindings doc;
  final ValueBindings value;
  final ArrayBindings array;
  final MutableArrayBindings mutableArray;
  final DictBindings dict;
  final DictKeyBindings dictKey;
  final MutableDictBindings mutableDict;
  final FleeceDecoderBindings decoder;
  final FleeceEncoderBindings encoder;
}
