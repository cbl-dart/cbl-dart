import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
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
        CBLDart_FLArrayIterator,
        CBLDart_FLDictIterator,
        CBLDart_LoadedDictKey,
        CBLDart_LoadedFLValue,
        KnownSharedKeys;

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
    cblite.FLError.kFLSharedKeysStateError => sharedKeysStateError,
    cblite.FLError.kFLPOSIXError => posixError,
    cblite.FLError.kFLUnsupported => unsupported,
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

    SliceBindings.releaseSliceResultByBuf(buf);

    return result;
  }
}

final class SliceBindings {
  static final Pointer<NativeFinalizerFunction> sliceResultReleaseByBufPtr =
      cblitedart.addresses.CBLDart_FLSliceResult_ReleaseByBuf
          .cast<NativeFinalizerFunction>();

  static final _sliceResultFinalizer = NativeFinalizer(
    sliceResultReleaseByBufPtr,
  );

  static bool equal(cblite.FLSlice a, cblite.FLSlice b) =>
      cblite.FLSlice_Equal(a, b);

  static int compare(cblite.FLSlice a, cblite.FLSlice b) =>
      cblite.FLSlice_Compare(a, b);

  static cblite.FLSliceResult create(int size) =>
      cblite.FLSliceResult_New(size);

  static cblite.FLSliceResult copy(cblite.FLSlice slice) =>
      cblite.FLSlice_Copy(slice);

  static void bindToDartObject(
    Finalizable object, {
    required Pointer<Void> buf,
    required bool retain,
  }) {
    if (retain) {
      cblitedart.CBLDart_FLSliceResult_RetainByBuf(buf);
    }

    _sliceResultFinalizer.attach(object, buf.cast());
  }

  static void retainSliceResultByBuf(Pointer<Void> buf) {
    cblitedart.CBLDart_FLSliceResult_RetainByBuf(buf);
  }

  static void releaseSliceResultByBuf(Pointer<Void> buf) {
    cblitedart.CBLDart_FLSliceResult_ReleaseByBuf(buf);
  }
}

// === SharedKeys ==============================================================

final class SharedKeysBindings {
  static final _finalizer = NativeFinalizer(
    cblite.addresses.FLSharedKeys_Release.cast(),
  );

  static cblite.FLSharedKeys create() => cblite.FLSharedKeys_New();

  static void bindToDartObject(
    Finalizable object,
    cblite.FLSharedKeys sharedKeys, {
    required bool retain,
  }) {
    if (retain) {
      cblite.FLSharedKeys_Retain(sharedKeys);
    }

    _finalizer.attach(object, sharedKeys.cast());
  }

  static int count(cblite.FLSharedKeys sharedKeys) =>
      cblite.FLSharedKeys_Count(sharedKeys);
}

// === Slot ====================================================================

final class SlotBindings {
  static void setNull(cblite.FLSlot slot) {
    cblite.FLSlot_SetNull(slot);
  }

  // ignore: avoid_positional_boolean_parameters
  static void setBool(cblite.FLSlot slot, bool value) {
    cblite.FLSlot_SetBool(slot, value);
  }

  static void setInt(cblite.FLSlot slot, int value) {
    cblite.FLSlot_SetInt(slot, value);
  }

  static void setDouble(cblite.FLSlot slot, double value) {
    cblite.FLSlot_SetDouble(slot, value);
  }

  static void setString(cblite.FLSlot slot, String value) {
    runWithSingleFLString(value, (flValue) {
      cblite.FLSlot_SetString(slot, flValue);
    });
  }

  static void setData(cblite.FLSlot slot, Data value) {
    cblite.FLSlot_SetData(slot, value.toSliceResult().makeGlobal().ref);
  }

  static void setValue(cblite.FLSlot slot, cblite.FLValue value) {
    cblite.FLSlot_SetValue(slot, value);
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

final class DocBindings {
  static final _finalizer = NativeFinalizer(
    cblite.addresses.FLDoc_Release.cast(),
  );

  static cblite.FLDoc fromResultData(
    Data data,
    FLTrust trust,
    cblite.FLSharedKeys? sharedKeys,
  ) {
    final sliceResult = data.toSliceResult();
    return cblite.FLDoc_FromResultData(
      sliceResult.makeGlobalResult().ref,
      trust.value,
      sharedKeys ?? nullptr,
      nullFLSlice.ref,
    );
  }

  static cblite.FLDoc fromJson(String json) => runWithSingleFLString(
    json,
    (flJson) =>
        cblite.FLDoc_FromJSON(flJson, globalFLErrorCode).checkFleeceError(),
  );

  static void bindToDartObject(Finalizable object, cblite.FLDoc doc) {
    _finalizer.attach(
      object,
      doc.cast(),
      externalSize: getAllocedData(doc)?.size,
    );
  }

  static SliceResult? getAllocedData(cblite.FLDoc doc) =>
      SliceResult.fromFLSliceResult(cblite.FLDoc_GetAllocedData(doc));

  static cblite.FLValue getRoot(cblite.FLDoc doc) => cblite.FLDoc_GetRoot(doc);

  static cblite.FLSharedKeys? getSharedKeys(cblite.FLDoc doc) =>
      cblite.FLDoc_GetSharedKeys(doc).toNullable();
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

final class ValueBindings {
  static final _finalizer = NativeFinalizer(
    cblite.addresses.FLValue_Release.cast(),
  );

  static void bindToDartObject(
    Finalizable object, {
    required cblite.FLValue value,
    required bool retain,
  }) {
    if (retain) {
      cblite.FLValue_Retain(value);
    }
    _finalizer.attach(object, value.cast());
  }

  static cblite.FLValue? fromData(SliceResult data, FLTrust trust) =>
      cblite.FLValue_FromData(data.makeGlobal().ref, trust.value).toNullable();

  static cblite.FLDoc? findDoc(cblite.FLValue value) =>
      cblite.FLValue_FindDoc(value).toNullable();

  static FLValueType getType(cblite.FLValue value) =>
      FLValueType.fromValue(cblite.FLValue_GetType(value));

  static bool isInteger(cblite.FLValue value) =>
      cblite.FLValue_IsInteger(value);

  static bool isDouble(cblite.FLValue value) => cblite.FLValue_IsDouble(value);

  static bool asBool(cblite.FLValue value) => cblite.FLValue_AsBool(value);

  static int asInt(cblite.FLValue value) => cblite.FLValue_AsInt(value);

  static double asDouble(cblite.FLValue value) =>
      cblite.FLValue_AsDouble(value);

  static String? asString(cblite.FLValue value) =>
      cblite.FLValue_AsString(value).toDartString();

  static Data? asData(cblite.FLValue value) =>
      cblite.FLValue_AsData(value).toData();

  static String? scalarToString(cblite.FLValue value) =>
      cblite.FLValue_ToString(value).toDartStringAndRelease();

  static bool isEqual(cblite.FLValue a, cblite.FLValue b) =>
      cblite.FLValue_IsEqual(a, b);

  static void retain(cblite.FLValue value) => cblite.FLValue_Retain(value);

  static void release(cblite.FLValue value) => cblite.FLValue_Release(value);

  static String toJSONX(
    cblite.FLValue value, {
    required bool json5,
    required bool canonical,
  }) =>
      cblite.FLValue_ToJSONX(value, json5, canonical).toDartStringAndRelease()!;
}

// === Array ===================================================================

final class ArrayBindings {
  static int count(cblite.FLArray array) => cblite.FLArray_Count(array);

  static bool isEmpty(cblite.FLArray array) => cblite.FLArray_IsEmpty(array);

  static cblite.FLMutableArray? asMutable(cblite.FLArray array) =>
      cblite.FLArray_AsMutable(array).toNullable();

  static cblite.FLValue get(cblite.FLArray array, int index) =>
      cblite.FLArray_Get(array, index);
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

final class MutableArrayBindings {
  static cblite.FLMutableArray mutableCopy(
    cblite.FLArray array,
    FLCopyFlags flags,
  ) => cblite.FLArray_MutableCopy(array, flags.value);

  static cblite.FLMutableArray create() => cblite.FLMutableArray_New();

  static cblite.FLArray? getSource(cblite.FLMutableArray array) =>
      cblite.FLMutableArray_GetSource(array).toNullable();

  static bool isChanged(cblite.FLMutableArray array) =>
      cblite.FLMutableArray_IsChanged(array);

  static cblite.FLSlot set(cblite.FLMutableArray array, int index) =>
      cblite.FLMutableArray_Set(array, index);

  static cblite.FLSlot append(cblite.FLMutableArray array) =>
      cblite.FLMutableArray_Append(array);

  static void insert(cblite.FLMutableArray array, int index, int count) =>
      cblite.FLMutableArray_Insert(array, index, count);

  static void remove(cblite.FLMutableArray array, int firstIndex, int count) =>
      cblite.FLMutableArray_Remove(array, firstIndex, count);

  static void resize(cblite.FLMutableArray array, int size) =>
      cblite.FLMutableArray_Resize(array, size);

  static cblite.FLMutableArray? getMutableArray(
    cblite.FLMutableArray array,
    int index,
  ) => cblite.FLMutableArray_GetMutableArray(array, index).toNullable();

  static cblite.FLMutableDict? getMutableDict(
    cblite.FLMutableArray array,
    int index,
  ) => cblite.FLMutableArray_GetMutableDict(array, index).toNullable();
}

// === Dict ====================================================================

final class DictBindings {
  static cblite.FLValue? get(cblite.FLDict dict, String key) =>
      runWithSingleFLString(
        key,
        (flKey) => cblite.FLDict_Get(dict, flKey),
      ).toNullable();

  static cblite.FLValue? getWithFLString(
    cblite.FLDict dict,
    cblite.FLString key,
  ) => cblite.FLDict_Get(dict, key).toNullable();

  static int count(cblite.FLDict dict) => cblite.FLDict_Count(dict);

  static bool isEmpty(cblite.FLDict dict) => cblite.FLDict_IsEmpty(dict);

  static cblite.FLMutableDict? asMutable(cblite.FLDict dict) =>
      cblite.FLDict_AsMutable(dict).toNullable();
}

final class DictKeyBindings {
  static void init(cblite.FLDictKey dictKey, cblite.FLString key) {
    final state = cblite.FLDictKey_Init(key);
    dictKey
      ..private1 = state.private1
      ..private2 = state.private2
      ..private3 = state.private3
      ..private4 = state.private4
      ..private5 = state.private5;
  }

  static cblite.FLValue? getWithKey(
    cblite.FLDict dict,
    Pointer<cblite.FLDictKey> key,
  ) => cblite.FLDict_GetWithKey(dict, key).toNullable();
}

// === MutableDict =============================================================

final class MutableDictBindings {
  static cblite.FLMutableDict mutableCopy(
    cblite.FLDict source,
    FLCopyFlags flags,
  ) => cblite.FLDict_MutableCopy(source, flags.value);

  static cblite.FLMutableDict create() => cblite.FLMutableDict_New();

  static cblite.FLDict? getSource(cblite.FLMutableDict dict) =>
      cblite.FLMutableDict_GetSource(dict).toNullable();

  static bool isChanged(cblite.FLMutableDict dict) =>
      cblite.FLMutableDict_IsChanged(dict);

  static cblite.FLSlot set(cblite.FLMutableDict dict, String key) =>
      runWithSingleFLString(
        key,
        (flKey) => cblite.FLMutableDict_Set(dict, flKey),
      );

  static void remove(cblite.FLMutableDict dict, String key) {
    runWithSingleFLString(
      key,
      (flKey) => cblite.FLMutableDict_Remove(dict, flKey),
    );
  }

  static void removeAll(cblite.FLMutableDict dict) {
    cblite.FLMutableDict_RemoveAll(dict);
  }

  static cblite.FLMutableArray? getMutableArray(
    cblite.FLMutableDict array,
    String key,
  ) => runWithSingleFLString(
    key,
    (flKey) => cblite.FLMutableDict_GetMutableArray(array, flKey).toNullable(),
  );

  static cblite.FLMutableDict? getMutableDict(
    cblite.FLMutableDict array,
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
extension CBLDart_LoadedFLValueExt on cblitedart.CBLDart_LoadedFLValue {
  FLValueType get typeEnum => FLValueType.fromValue(type);
}

final class FleeceDecoderBindings {
  static final _knownSharedKeysFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_KnownSharedKeys_Delete.cast(),
  );
  static final _dictIteratorFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_FLDictIterator_Delete.cast(),
  );
  static final _arrayIteratorFinalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_FLArrayIterator_Delete.cast(),
  );

  static String dumpData(Data data) => cblite.FLData_Dump(
    data.toSliceResult().makeGlobal().ref,
  ).toDartStringAndRelease()!;

  static Pointer<cblitedart.KnownSharedKeys> createKnownSharedKeys(
    Finalizable object,
  ) {
    final result = cblitedart.CBLDart_KnownSharedKeys_New();
    _knownSharedKeysFinalizer.attach(object, result.cast());
    return result;
  }

  static void getLoadedValue(cblite.FLValue value) {
    cblitedart.CBLDart_GetLoadedFLValue(value, globalLoadedFLValue);
  }

  static void getLoadedValueFromArray(cblite.FLArray array, int index) {
    cblitedart.CBLDart_FLArray_GetLoadedFLValue(
      array,
      index,
      globalLoadedFLValue,
    );
  }

  static void getLoadedValueFromDict(cblite.FLDict array, String key) {
    runWithSingleFLString(key, (flKey) {
      cblitedart.CBLDart_FLDict_GetLoadedFLValue(
        array,
        flKey,
        globalLoadedFLValue,
      );
    });
  }

  static Pointer<cblitedart.CBLDart_FLDictIterator> dictIteratorBegin(
    Finalizable? object,
    cblite.FLDict dict,
    Pointer<cblitedart.KnownSharedKeys> knownSharedKeys,
    Pointer<cblitedart.CBLDart_LoadedDictKey> keyOut,
    Pointer<cblitedart.CBLDart_LoadedFLValue> valueOut, {
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

  static bool dictIteratorNext(
    Pointer<cblitedart.CBLDart_FLDictIterator> iterator,
  ) => cblitedart.CBLDart_FLDictIterator_Next(iterator);

  static Pointer<cblitedart.CBLDart_FLArrayIterator> arrayIteratorBegin(
    Finalizable? object,
    cblite.FLArray array,
    Pointer<cblitedart.CBLDart_LoadedFLValue> valueOut,
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

  static bool arrayIteratorNext(
    Pointer<cblitedart.CBLDart_FLArrayIterator> iterator,
  ) => cblitedart.CBLDart_FLArrayIterator_Next(iterator);
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

final class FleeceEncoderBindings {
  static final _finalizer = NativeFinalizer(
    cblite.addresses.FLEncoder_Free.cast(),
  );

  static void bindToDartObject(Finalizable object, cblite.FLEncoder encoder) {
    _finalizer.attach(object, encoder.cast());
  }

  static cblite.FLEncoder create({
    required FLEncoderFormat format,
    required int reserveSize,
    required bool uniqueStrings,
  }) =>
      cblite.FLEncoder_NewWithOptions(format.value, reserveSize, uniqueStrings);

  static void setSharedKeys(
    cblite.FLEncoder encoder,
    cblite.FLSharedKeys keys,
  ) {
    cblite.FLEncoder_SetSharedKeys(encoder, keys);
  }

  static void reset(cblite.FLEncoder encoder) {
    cblite.FLEncoder_Reset(encoder);
  }

  static void writeArrayValue(
    cblite.FLEncoder encoder,
    cblite.FLArray array,
    int index,
  ) {
    _checkError(
      encoder,
      cblitedart.CBLDart_FLEncoder_WriteArrayValue(encoder, array, index),
    );
  }

  static void writeValue(cblite.FLEncoder encoder, cblite.FLValue value) {
    if (value == nullptr) {
      throw ArgumentError.value(value, 'value', 'must not be `nullptr`');
    }

    _checkError(encoder, cblite.FLEncoder_WriteValue(encoder, value));
  }

  static void writeNull(cblite.FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_WriteNull(encoder));
  }

  // ignore: avoid_positional_boolean_parameters
  static void writeBool(cblite.FLEncoder encoder, bool value) {
    _checkError(encoder, cblite.FLEncoder_WriteBool(encoder, value));
  }

  static void writeInt(cblite.FLEncoder encoder, int value) {
    _checkError(encoder, cblite.FLEncoder_WriteInt(encoder, value));
  }

  static void writeDouble(cblite.FLEncoder encoder, double value) {
    _checkError(encoder, cblite.FLEncoder_WriteDouble(encoder, value));
  }

  static void writeString(cblite.FLEncoder encoder, String value) {
    runWithSingleFLString(value, (flValue) {
      _checkError(encoder, cblite.FLEncoder_WriteString(encoder, flValue));
    });
  }

  static void writeData(cblite.FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cblite.FLEncoder_WriteData(encoder, sliceResult.makeGlobal().ref),
    );
  }

  static void writeJSON(cblite.FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cblite.FLEncoder_ConvertJSON(
        encoder,
        sliceResult.makeGlobal().cast<cblite.FLString>().ref,
      ),
    );
  }

  static void beginArray(cblite.FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cblite.FLEncoder_BeginArray(encoder, reserveCount));
  }

  static void endArray(cblite.FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_EndArray(encoder));
  }

  static void beginDict(cblite.FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cblite.FLEncoder_BeginDict(encoder, reserveCount));
  }

  static void writeKey(cblite.FLEncoder encoder, String key) {
    runWithSingleFLString(key, (flKey) {
      _checkError(encoder, cblite.FLEncoder_WriteKey(encoder, flKey));
    });
  }

  static void writeKeyFLString(cblite.FLEncoder encoder, cblite.FLString key) {
    _checkError(encoder, cblite.FLEncoder_WriteKey(encoder, key));
  }

  static void writeKeyValue(cblite.FLEncoder encoder, cblite.FLValue key) {
    _checkError(encoder, cblite.FLEncoder_WriteKeyValue(encoder, key));
  }

  static void endDict(cblite.FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_EndDict(encoder));
  }

  static Data? finish(cblite.FLEncoder encoder) => _checkError(
    encoder,
    cblite.FLEncoder_Finish(encoder, globalFLErrorCode),
  ).let(SliceResult.fromFLSliceResult)?.toData();

  static FLError _getError(cblite.FLEncoder encoder) =>
      FLError.fromValue(cblite.FLEncoder_GetError(encoder));

  static String _getErrorMessage(cblite.FLEncoder encoder) =>
      cblite.FLEncoder_GetErrorMessage(
        encoder,
      ).cast<Utf8>().toDartStringAndFree();

  static T _checkError<T>(cblite.FLEncoder encoder, T result) {
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
