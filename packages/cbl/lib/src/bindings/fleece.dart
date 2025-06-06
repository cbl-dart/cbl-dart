import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
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
  noError(cblite.FLError.kFLNoError),
  memoryError(cblite.FLError.kFLMemoryError),
  outOfRange(cblite.FLError.kFLOutOfRange),
  invalidData(cblite.FLError.kFLInvalidData),
  encodeError(cblite.FLError.kFLEncodeError),
  jsonError(cblite.FLError.kFLJSONError),
  unknownValue(cblite.FLError.kFLUnknownValue),
  internalError(cblite.FLError.kFLInternalError),
  notFound(cblite.FLError.kFLNotFound),
  sharedKeysStateError(cblite.FLError.kFLSharedKeysStateError),
  posixError(cblite.FLError.kFLPOSIXError),
  unsupported(cblite.FLError.kFLUnsupported);

  const FLError(this.value);

  static FLError fromValue(int value) => switch (value) {
    cblite.FLError.kFLNoError => noError,
    cblite.FLError.kFLMemoryError => memoryError,
    cblite.FLError.kFLOutOfRange => outOfRange,
    cblite.FLError.kFLInvalidData => invalidData,
    cblite.FLError.kFLEncodeError => encodeError,
    cblite.FLError.kFLJSONError => jsonError,
    cblite.FLError.kFLUnknownValue => unknownValue,
    cblite.FLError.kFLInternalError => internalError,
    cblite.FLError.kFLNotFound => notFound,
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
        self is cblite.FLSliceResult && self.buf == nullptr) {
      _checkFleeceError();
    }
    return this;
  }
}

// === Slice ===================================================================

extension FLSliceExt on cblite.FLSlice {
  bool get isNull => buf == nullptr;
  Data? toData() => SliceResult.fromFLSlice(this)?.toData();
}

extension FLResultSliceExt on cblite.FLSliceResult {
  bool get isNull => buf == nullptr;
  Data? toData({bool retain = false}) =>
      SliceResult.fromFLSliceResult(this, retain: retain)?.toData();
}

extension FLStringExt on cblite.FLString {
  bool get isNull => buf == nullptr;
  String? toDartString() =>
      isNull ? null : buf.cast<Utf8>().toDartString(length: size);
}

extension FLStringResultExt on cblite.FLStringResult {
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
    cblDart.addresses.CBLDart_FLSliceResult_ReleaseByBuf.cast(),
  );

  bool equal(cblite.FLSlice a, cblite.FLSlice b) => cbl.FLSlice_Equal(a, b);

  int compare(cblite.FLSlice a, cblite.FLSlice b) => cbl.FLSlice_Compare(a, b);

  cblite.FLSliceResult create(int size) => cbl.FLSliceResult_New(size);

  cblite.FLSliceResult copy(cblite.FLSlice slice) => cbl.FLSlice_Copy(slice);

  void bindToDartObject(
    Finalizable object, {
    required Pointer<Void> buf,
    required bool retain,
  }) {
    if (retain) {
      cblDart.CBLDart_FLSliceResult_RetainByBuf(buf);
    }

    _sliceResultFinalizer.attach(object, buf.cast());
  }

  void retainSliceResultByBuf(Pointer<Void> buf) {
    cblDart.CBLDart_FLSliceResult_RetainByBuf(buf);
  }

  void releaseSliceResultByBuf(Pointer<Void> buf) {
    cblDart.CBLDart_FLSliceResult_ReleaseByBuf(buf);
  }
}

// === SharedKeys ==============================================================

final class SharedKeysBindings extends Bindings {
  SharedKeysBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cbl.addresses.FLSharedKeys_Release.cast(),
  );

  cblite.FLSharedKeys create() => cbl.FLSharedKeys_New();

  void bindToDartObject(
    Finalizable object,
    cblite.FLSharedKeys sharedKeys, {
    required bool retain,
  }) {
    if (retain) {
      cbl.FLSharedKeys_Retain(sharedKeys);
    }

    _finalizer.attach(object, sharedKeys.cast());
  }

  int count(cblite.FLSharedKeys sharedKeys) =>
      cbl.FLSharedKeys_Count(sharedKeys);
}

// === Slot ====================================================================

final class SlotBindings extends Bindings {
  SlotBindings(super.libraries);

  void setNull(cblite.FLSlot slot) {
    cbl.FLSlot_SetNull(slot);
  }

  // ignore: avoid_positional_boolean_parameters
  void setBool(cblite.FLSlot slot, bool value) {
    cbl.FLSlot_SetBool(slot, value);
  }

  void setInt(cblite.FLSlot slot, int value) {
    cbl.FLSlot_SetInt(slot, value);
  }

  void setDouble(cblite.FLSlot slot, double value) {
    cbl.FLSlot_SetDouble(slot, value);
  }

  void setString(cblite.FLSlot slot, String value) {
    runWithSingleFLString(value, (flValue) {
      cbl.FLSlot_SetString(slot, flValue);
    });
  }

  void setData(cblite.FLSlot slot, Data value) {
    cbl.FLSlot_SetData(slot, value.toSliceResult().makeGlobal().ref);
  }

  void setValue(cblite.FLSlot slot, cblite.FLValue value) {
    cbl.FLSlot_SetValue(slot, value);
  }
}

// === Doc =====================================================================

enum FLTrust {
  untrusted(cblite.FLTrust.kFLUntrusted),
  trusted(cblite.FLTrust.kFLTrusted);

  const FLTrust(this.value);

  static FLTrust fromValue(int value) => switch (value) {
    cblite.FLTrust.kFLUntrusted => untrusted,
    cblite.FLTrust.kFLTrusted => trusted,
    _ => throw ArgumentError('Unknown value for FLTrust: $value'),
  };

  final int value;
}

final class DocBindings extends Bindings {
  DocBindings(super.libraries);

  late final _finalizer = NativeFinalizer(cbl.addresses.FLDoc_Release.cast());

  cblite.FLDoc fromResultData(
    Data data,
    FLTrust trust,
    cblite.FLSharedKeys? sharedKeys,
  ) {
    final sliceResult = data.toSliceResult();
    return cbl.FLDoc_FromResultData(
      sliceResult.makeGlobalResult().ref,
      trust.value,
      sharedKeys ?? nullptr,
      nullFLSlice.ref,
    );
  }

  cblite.FLDoc fromJson(String json) => runWithSingleFLString(
    json,
    (flJson) =>
        cbl.FLDoc_FromJSON(flJson, globalFLErrorCode).checkFleeceError(),
  );

  void bindToDartObject(Finalizable object, cblite.FLDoc doc) {
    _finalizer.attach(
      object,
      doc.cast(),
      externalSize: getAllocedData(doc)?.size,
    );
  }

  SliceResult? getAllocedData(cblite.FLDoc doc) =>
      SliceResult.fromFLSliceResult(cbl.FLDoc_GetAllocedData(doc));

  cblite.FLValue getRoot(cblite.FLDoc doc) => cbl.FLDoc_GetRoot(doc);

  cblite.FLSharedKeys? getSharedKeys(cblite.FLDoc doc) =>
      cbl.FLDoc_GetSharedKeys(doc).toNullable();
}

// === Value ===================================================================

enum FLValueType {
  undefined(cblite.FLValueType.kFLUndefined),
  null$(cblite.FLValueType.kFLNull),
  boolean(cblite.FLValueType.kFLBoolean),
  number(cblite.FLValueType.kFLNumber),
  string(cblite.FLValueType.kFLString),
  data(cblite.FLValueType.kFLData),
  array(cblite.FLValueType.kFLArray),
  dict(cblite.FLValueType.kFLDict);

  const FLValueType(this.value);

  static FLValueType fromValue(int value) => switch (value) {
    cblite.FLValueType.kFLUndefined => undefined,
    cblite.FLValueType.kFLNull => null$,
    cblite.FLValueType.kFLBoolean => boolean,
    cblite.FLValueType.kFLNumber => number,
    cblite.FLValueType.kFLString => string,
    cblite.FLValueType.kFLData => data,
    cblite.FLValueType.kFLArray => array,
    cblite.FLValueType.kFLDict => dict,
    _ => throw ArgumentError('Unknown value for FLValueType: $value'),
  };

  final int value;
}

final class ValueBindings extends Bindings {
  ValueBindings(super.libraries);

  late final _finalizer = NativeFinalizer(cbl.addresses.FLValue_Release.cast());

  void bindToDartObject(
    Finalizable object, {
    required cblite.FLValue value,
    required bool retain,
  }) {
    if (retain) {
      cbl.FLValue_Retain(value);
    }
    _finalizer.attach(object, value.cast());
  }

  cblite.FLValue? fromData(SliceResult data, FLTrust trust) =>
      cbl.FLValue_FromData(data.makeGlobal().ref, trust.value).toNullable();

  cblite.FLDoc? findDoc(cblite.FLValue value) =>
      cbl.FLValue_FindDoc(value).toNullable();

  FLValueType getType(cblite.FLValue value) =>
      FLValueType.fromValue(cbl.FLValue_GetType(value));

  bool isInteger(cblite.FLValue value) => cbl.FLValue_IsInteger(value);

  bool isDouble(cblite.FLValue value) => cbl.FLValue_IsDouble(value);

  bool asBool(cblite.FLValue value) => cbl.FLValue_AsBool(value);

  int asInt(cblite.FLValue value) => cbl.FLValue_AsInt(value);

  double asDouble(cblite.FLValue value) => cbl.FLValue_AsDouble(value);

  String? asString(cblite.FLValue value) =>
      cbl.FLValue_AsString(value).toDartString();

  Data? asData(cblite.FLValue value) => cbl.FLValue_AsData(value).toData();

  String? scalarToString(cblite.FLValue value) =>
      cbl.FLValue_ToString(value).toDartStringAndRelease();

  bool isEqual(cblite.FLValue a, cblite.FLValue b) => cbl.FLValue_IsEqual(a, b);

  void retain(cblite.FLValue value) => cbl.FLValue_Retain(value);

  void release(cblite.FLValue value) => cbl.FLValue_Release(value);

  String toJSONX(
    cblite.FLValue value, {
    required bool json5,
    required bool canonical,
  }) => cbl.FLValue_ToJSONX(value, json5, canonical).toDartStringAndRelease()!;
}

// === Array ===================================================================

final class ArrayBindings extends Bindings {
  ArrayBindings(super.libraries);

  int count(cblite.FLArray array) => cbl.FLArray_Count(array);

  bool isEmpty(cblite.FLArray array) => cbl.FLArray_IsEmpty(array);

  cblite.FLMutableArray? asMutable(cblite.FLArray array) =>
      cbl.FLArray_AsMutable(array).toNullable();

  cblite.FLValue get(cblite.FLArray array, int index) =>
      cbl.FLArray_Get(array, index);
}

// === MutableArray ============================================================

enum FLCopyFlags {
  defaultCopy(cblite.FLCopyFlags.kFLDefaultCopy),
  deepCopy(cblite.FLCopyFlags.kFLDeepCopy),
  copyImmutables(cblite.FLCopyFlags.kFLCopyImmutables),
  deepCopyImmutables(cblite.FLCopyFlags.kFLDeepCopyImmutables);

  const FLCopyFlags(this.value);

  static FLCopyFlags fromValue(int value) => switch (value) {
    cblite.FLCopyFlags.kFLDefaultCopy => defaultCopy,
    cblite.FLCopyFlags.kFLDeepCopy => deepCopy,
    cblite.FLCopyFlags.kFLCopyImmutables => copyImmutables,
    cblite.FLCopyFlags.kFLDeepCopyImmutables => deepCopyImmutables,
    _ => throw ArgumentError('Unknown value for FLCopyFlags: $value'),
  };

  final int value;
}

final class MutableArrayBindings extends Bindings {
  MutableArrayBindings(super.libraries);

  cblite.FLMutableArray mutableCopy(cblite.FLArray array, FLCopyFlags flags) =>
      cbl.FLArray_MutableCopy(array, flags.value);

  cblite.FLMutableArray create() => cbl.FLMutableArray_New();

  cblite.FLArray? getSource(cblite.FLMutableArray array) =>
      cbl.FLMutableArray_GetSource(array).toNullable();

  bool isChanged(cblite.FLMutableArray array) =>
      cbl.FLMutableArray_IsChanged(array);

  cblite.FLSlot set(cblite.FLMutableArray array, int index) =>
      cbl.FLMutableArray_Set(array, index);

  cblite.FLSlot append(cblite.FLMutableArray array) =>
      cbl.FLMutableArray_Append(array);

  void insert(cblite.FLMutableArray array, int index, int count) =>
      cbl.FLMutableArray_Insert(array, index, count);

  void remove(cblite.FLMutableArray array, int firstIndex, int count) =>
      cbl.FLMutableArray_Remove(array, firstIndex, count);

  void resize(cblite.FLMutableArray array, int size) =>
      cbl.FLMutableArray_Resize(array, size);

  cblite.FLMutableArray? getMutableArray(
    cblite.FLMutableArray array,
    int index,
  ) => cbl.FLMutableArray_GetMutableArray(array, index).toNullable();

  cblite.FLMutableDict? getMutableDict(
    cblite.FLMutableArray array,
    int index,
  ) => cbl.FLMutableArray_GetMutableDict(array, index).toNullable();
}

// === Dict ====================================================================

final class DictBindings extends Bindings {
  DictBindings(super.libraries);

  cblite.FLValue? get(cblite.FLDict dict, String key) => runWithSingleFLString(
    key,
    (flKey) => cbl.FLDict_Get(dict, flKey),
  ).toNullable();

  cblite.FLValue? getWithFLString(cblite.FLDict dict, cblite.FLString key) =>
      cbl.FLDict_Get(dict, key).toNullable();

  int count(cblite.FLDict dict) => cbl.FLDict_Count(dict);

  bool isEmpty(cblite.FLDict dict) => cbl.FLDict_IsEmpty(dict);

  cblite.FLMutableDict? asMutable(cblite.FLDict dict) =>
      cbl.FLDict_AsMutable(dict).toNullable();
}

final class DictKeyBindings extends Bindings {
  DictKeyBindings(super.libraries);

  void init(cblite.FLDictKey dictKey, cblite.FLString key) {
    final state = cbl.FLDictKey_Init(key);
    dictKey
      ..private1 = state.private1
      ..private2 = state.private2
      ..private3 = state.private3
      ..private4 = state.private4
      ..private5 = state.private5;
  }

  cblite.FLValue? getWithKey(
    cblite.FLDict dict,
    Pointer<cblite.FLDictKey> key,
  ) => cbl.FLDict_GetWithKey(dict, key).toNullable();
}

// === MutableDict =============================================================

final class MutableDictBindings extends Bindings {
  MutableDictBindings(super.libraries);

  cblite.FLMutableDict mutableCopy(cblite.FLDict source, FLCopyFlags flags) =>
      cbl.FLDict_MutableCopy(source, flags.value);

  cblite.FLMutableDict create() => cbl.FLMutableDict_New();

  cblite.FLDict? getSource(cblite.FLMutableDict dict) =>
      cbl.FLMutableDict_GetSource(dict).toNullable();

  bool isChanged(cblite.FLMutableDict dict) =>
      cbl.FLMutableDict_IsChanged(dict);

  cblite.FLSlot set(cblite.FLMutableDict dict, String key) =>
      runWithSingleFLString(key, (flKey) => cbl.FLMutableDict_Set(dict, flKey));

  void remove(cblite.FLMutableDict dict, String key) {
    runWithSingleFLString(
      key,
      (flKey) => cbl.FLMutableDict_Remove(dict, flKey),
    );
  }

  void removeAll(cblite.FLMutableDict dict) {
    cbl.FLMutableDict_RemoveAll(dict);
  }

  cblite.FLMutableArray? getMutableArray(
    cblite.FLMutableDict array,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cbl.FLMutableDict_GetMutableArray(array, flKey).toNullable(),
  );

  cblite.FLMutableDict? getMutableDict(
    cblite.FLMutableDict array,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cbl.FLMutableDict_GetMutableDict(array, flKey).toNullable(),
  );
}

// === Decoder =================================================================

@pragma('vm:prefer-inline')
String decodeFLString(Pointer<Void> buf, int size) =>
    utf8.decode(buf.cast<Uint8>().asTypedList(size));

// ignore: camel_case_extensions
extension CBLDart_LoadedFLValueExt on cblitedart.CBLDart_LoadedFLValue {
  FLValueType get typeEnum => FLValueType.fromValue(type);
}

final class FleeceDecoderBindings extends Bindings {
  FleeceDecoderBindings(super.libraries);

  late final _knownSharedKeysFinalizer = NativeFinalizer(
    cblDart.addresses.CBLDart_KnownSharedKeys_Delete.cast(),
  );
  late final _dictIteratorFinalizer = NativeFinalizer(
    cblDart.addresses.CBLDart_FLDictIterator_Delete.cast(),
  );
  late final _arrayIteratorFinalizer = NativeFinalizer(
    cblDart.addresses.CBLDart_FLArrayIterator_Delete.cast(),
  );

  String dumpData(Data data) => cbl.FLData_Dump(
    data.toSliceResult().makeGlobal().ref,
  ).toDartStringAndRelease()!;

  Pointer<cblitedart.KnownSharedKeys> createKnownSharedKeys(
    Finalizable object,
  ) {
    final result = cblDart.CBLDart_KnownSharedKeys_New();
    _knownSharedKeysFinalizer.attach(object, result.cast());
    return result;
  }

  void getLoadedValue(cblite.FLValue value) {
    cblDart.CBLDart_GetLoadedFLValue(value, globalLoadedFLValue);
  }

  void getLoadedValueFromArray(cblite.FLArray array, int index) {
    cblDart.CBLDart_FLArray_GetLoadedFLValue(array, index, globalLoadedFLValue);
  }

  void getLoadedValueFromDict(cblite.FLDict array, String key) {
    runWithSingleFLString(key, (flKey) {
      cblDart.CBLDart_FLDict_GetLoadedFLValue(
        array,
        flKey,
        globalLoadedFLValue,
      );
    });
  }

  Pointer<cblitedart.CBLDart_FLDictIterator> dictIteratorBegin(
    Finalizable? object,
    cblite.FLDict dict,
    Pointer<cblitedart.KnownSharedKeys> knownSharedKeys,
    Pointer<cblitedart.CBLDart_LoadedDictKey> keyOut,
    Pointer<cblitedart.CBLDart_LoadedFLValue> valueOut, {
    required bool preLoad,
  }) {
    final result = cblDart.CBLDart_FLDictIterator_Begin(
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

  bool dictIteratorNext(Pointer<cblitedart.CBLDart_FLDictIterator> iterator) =>
      cblDart.CBLDart_FLDictIterator_Next(iterator);

  Pointer<cblitedart.CBLDart_FLArrayIterator> arrayIteratorBegin(
    Finalizable? object,
    cblite.FLArray array,
    Pointer<cblitedart.CBLDart_LoadedFLValue> valueOut,
  ) {
    final result = cblDart.CBLDart_FLArrayIterator_Begin(
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
    Pointer<cblitedart.CBLDart_FLArrayIterator> iterator,
  ) => cblDart.CBLDart_FLArrayIterator_Next(iterator);
}

// === Encoder =================================================================

enum FLEncoderFormat {
  fleece(cblite.FLEncoderFormat.kFLEncodeFleece),
  json(cblite.FLEncoderFormat.kFLEncodeJSON),
  json5(cblite.FLEncoderFormat.kFLEncodeJSON5);

  const FLEncoderFormat(this.value);

  static FLEncoderFormat fromValue(int value) => switch (value) {
    cblite.FLEncoderFormat.kFLEncodeFleece => fleece,
    cblite.FLEncoderFormat.kFLEncodeJSON => json,
    cblite.FLEncoderFormat.kFLEncodeJSON5 => json5,
    _ => throw ArgumentError('Unknown value for FLEncoderFormat: $value'),
  };

  final int value;
}

final class FleeceEncoderBindings extends Bindings {
  FleeceEncoderBindings(super.libraries);

  late final _finalizer = NativeFinalizer(cbl.addresses.FLEncoder_Free.cast());

  void bindToDartObject(Finalizable object, cblite.FLEncoder encoder) {
    _finalizer.attach(object, encoder.cast());
  }

  cblite.FLEncoder create({
    required FLEncoderFormat format,
    required int reserveSize,
    required bool uniqueStrings,
  }) => cbl.FLEncoder_NewWithOptions(format.value, reserveSize, uniqueStrings);

  void setSharedKeys(cblite.FLEncoder encoder, cblite.FLSharedKeys keys) {
    cbl.FLEncoder_SetSharedKeys(encoder, keys);
  }

  void reset(cblite.FLEncoder encoder) {
    cbl.FLEncoder_Reset(encoder);
  }

  void writeArrayValue(
    cblite.FLEncoder encoder,
    cblite.FLArray array,
    int index,
  ) {
    _checkError(
      encoder,
      cblDart.CBLDart_FLEncoder_WriteArrayValue(encoder, array, index),
    );
  }

  void writeValue(cblite.FLEncoder encoder, cblite.FLValue value) {
    if (value == nullptr) {
      throw ArgumentError.value(value, 'value', 'must not be `nullptr`');
    }

    _checkError(encoder, cbl.FLEncoder_WriteValue(encoder, value));
  }

  void writeNull(cblite.FLEncoder encoder) {
    _checkError(encoder, cbl.FLEncoder_WriteNull(encoder));
  }

  // ignore: avoid_positional_boolean_parameters
  void writeBool(cblite.FLEncoder encoder, bool value) {
    _checkError(encoder, cbl.FLEncoder_WriteBool(encoder, value));
  }

  void writeInt(cblite.FLEncoder encoder, int value) {
    _checkError(encoder, cbl.FLEncoder_WriteInt(encoder, value));
  }

  void writeDouble(cblite.FLEncoder encoder, double value) {
    _checkError(encoder, cbl.FLEncoder_WriteDouble(encoder, value));
  }

  void writeString(cblite.FLEncoder encoder, String value) {
    runWithSingleFLString(value, (flValue) {
      _checkError(encoder, cbl.FLEncoder_WriteString(encoder, flValue));
    });
  }

  void writeData(cblite.FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cbl.FLEncoder_WriteData(encoder, sliceResult.makeGlobal().ref),
    );
  }

  void writeJSON(cblite.FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cbl.FLEncoder_ConvertJSON(
        encoder,
        sliceResult.makeGlobal().cast<cblite.FLString>().ref,
      ),
    );
  }

  void beginArray(cblite.FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cbl.FLEncoder_BeginArray(encoder, reserveCount));
  }

  void endArray(cblite.FLEncoder encoder) {
    _checkError(encoder, cbl.FLEncoder_EndArray(encoder));
  }

  void beginDict(cblite.FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cbl.FLEncoder_BeginDict(encoder, reserveCount));
  }

  void writeKey(cblite.FLEncoder encoder, String key) {
    runWithSingleFLString(key, (flKey) {
      _checkError(encoder, cbl.FLEncoder_WriteKey(encoder, flKey));
    });
  }

  void writeKeyFLString(cblite.FLEncoder encoder, cblite.FLString key) {
    _checkError(encoder, cbl.FLEncoder_WriteKey(encoder, key));
  }

  void writeKeyValue(cblite.FLEncoder encoder, cblite.FLValue key) {
    _checkError(encoder, cbl.FLEncoder_WriteKeyValue(encoder, key));
  }

  void endDict(cblite.FLEncoder encoder) {
    _checkError(encoder, cbl.FLEncoder_EndDict(encoder));
  }

  Data? finish(cblite.FLEncoder encoder) => _checkError(
    encoder,
    cbl.FLEncoder_Finish(encoder, globalFLErrorCode),
  ).let(SliceResult.fromFLSliceResult)?.toData();

  FLError _getError(cblite.FLEncoder encoder) =>
      FLError.fromValue(cbl.FLEncoder_GetError(encoder));

  String _getErrorMessage(cblite.FLEncoder encoder) =>
      cbl.FLEncoder_GetErrorMessage(encoder).cast<Utf8>().toDartStringAndFree();

  T _checkError<T>(cblite.FLEncoder encoder, T result) {
    final mayHaveError =
        (result is bool && !result) ||
        (result is cblite.FLSliceResult && result.buf == nullptr);

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
