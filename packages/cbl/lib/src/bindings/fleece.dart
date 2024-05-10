// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_positional_boolean_parameters, avoid_private_typedef_functions, camel_case_types

import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'global.dart';
import 'utils.dart';

const _sliceBindings = SliceBindings();

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

typedef FLSlice = cblite.FLSlice;

extension FLSliceExt on FLSlice {
  bool get isNull => buf == nullptr;

  Data? toData() => SliceResult.fromFLSlice(this)?.toData();
}

typedef FLSliceResult = cblite.FLSliceResult;

extension FLResultSliceExt on FLSliceResult {
  bool get isNull => buf == nullptr;

  Data? toData({bool retain = false}) =>
      SliceResult.fromFLSliceResult(this, retain: retain)?.toData();
}

typedef FLString = cblite.FLString;

extension FLStringExt on FLString {
  bool get isNull => buf == nullptr;

  String? toDartString() =>
      isNull ? null : buf.cast<Utf8>().toDartString(length: size);
}

typedef FLStringResult = cblite.FLStringResult;

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

    _sliceBindings.releaseSliceResultByBuf(buf);

    return result;
  }
}

final class SliceBindings {
  const SliceBindings();

  static final _sliceResultFinalizer = NativeFinalizer(Native.addressOf<
              NativeFunction<
                  cblitedart.NativeCBLDart_FLSliceResult_ReleaseByBuf>>(
          cblitedart.CBLDart_FLSliceResult_ReleaseByBuf)
      .cast());

  bool equal(FLSlice a, FLSlice b) => cblite.FLSlice_Equal(a, b);

  int compare(FLSlice a, FLSlice b) => cblite.FLSlice_Compare(a, b);

  FLSliceResult create(int size) => cblite.FLSliceResult_New(size);

  FLSliceResult copy(FLSlice slice) => cblite.FLSlice_Copy(slice);

  void bindToDartObject(
    Finalizable object, {
    required Pointer<Void> buf,
    required bool retain,
  }) {
    if (retain) {
      retainSliceResultByBuf(buf);
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

typedef FLSharedKeys = cblite.FLSharedKeys;

final class SharedKeysBindings {
  const SharedKeysBindings();

  static final _finalizer = NativeFinalizer(
      Native.addressOf<NativeFunction<cblite.NativeFLSharedKeys_Release>>(
              cblite.FLSharedKeys_Release)
          .cast());

  FLSharedKeys create() => cblite.FLSharedKeys_New();

  void bindToDartObject(
    Finalizable object,
    FLSharedKeys sharedKeys, {
    required bool retain,
  }) {
    if (retain) {
      cblite.FLSharedKeys_Retain(sharedKeys);
    }

    _finalizer.attach(object, sharedKeys.cast());
  }

  int count(FLSharedKeys sharedKeys) => cblite.FLSharedKeys_Count(sharedKeys);
}

// === Slot ====================================================================

typedef FLSlot = cblite.FLSlot;

final class SlotBindings {
  const SlotBindings();

  void setNull(FLSlot slot) {
    cblite.FLSlot_SetNull(slot);
  }

  void setBool(FLSlot slot, bool value) {
    cblite.FLSlot_SetBool(slot, value);
  }

  void setInt(FLSlot slot, int value) {
    cblite.FLSlot_SetInt(slot, value);
  }

  void setDouble(FLSlot slot, double value) {
    cblite.FLSlot_SetDouble(slot, value);
  }

  void setString(FLSlot slot, String value) {
    runWithSingleFLString(value, (flValue) {
      cblite.FLSlot_SetString(slot, flValue);
    });
  }

  void setData(FLSlot slot, Data value) {
    cblite.FLSlot_SetData(slot, value.toSliceResult().makeGlobal().ref);
  }

  void setValue(FLSlot slot, FLValue value) {
    cblite.FLSlot_SetValue(slot, value);
  }
}

// === Doc =====================================================================

typedef FLDoc = cblite.FLDoc;

final class DocBindings {
  const DocBindings();

  static final _finalizer = NativeFinalizer(
      Native.addressOf<NativeFunction<cblite.NativeFLDoc_Release>>(
              cblite.FLDoc_Release)
          .cast());

  FLDoc fromResultData(
    Data data,
    FLTrust trust,
    FLSharedKeys? sharedKeys,
  ) {
    final sliceResult = data.toSliceResult();
    return cblite.FLDoc_FromResultData(
      sliceResult.makeGlobalResult().ref,
      trust.toInt(),
      sharedKeys ?? nullptr,
      nullFLSlice.ref,
    );
  }

  FLDoc fromJson(String json) => runWithSingleFLString(
        json,
        (flJson) =>
            cblite.FLDoc_FromJSON(flJson, globalFLErrorCode).checkFleeceError(),
      );

  void bindToDartObject(Finalizable object, FLDoc doc) {
    _finalizer.attach(
      object,
      doc.cast(),
      externalSize: getAllocedData(doc)?.size,
    );
  }

  SliceResult? getAllocedData(FLDoc doc) =>
      SliceResult.fromFLSliceResult(cblite.FLDoc_GetAllocedData(doc));

  FLValue getRoot(FLDoc doc) => cblite.FLDoc_GetRoot(doc);

  FLSharedKeys? getSharedKeys(FLDoc doc) =>
      cblite.FLDoc_GetSharedKeys(doc).toNullable();
}

// === Value ===================================================================

typedef FLValue = cblite.FLValue;

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

final class ValueBindings {
  const ValueBindings();

  static final _finalizer = NativeFinalizer(
      Native.addressOf<NativeFunction<cblite.NativeFLValue_Release>>(
              cblite.FLValue_Release)
          .cast());

  void bindToDartObject(
    Finalizable object, {
    required FLValue value,
    required bool retain,
  }) {
    if (retain) {
      this.retain(value);
    }
    _finalizer.attach(object, value.cast());
  }

  FLValue? fromData(SliceResult data, FLTrust trust) =>
      cblite.FLValue_FromData(data.makeGlobal().ref, trust.toInt())
          .toNullable();

  FLDoc? findDoc(FLValue value) => cblite.FLValue_FindDoc(value).toNullable();

  FLValueType getType(FLValue value) =>
      cblite.FLValue_GetType(value).toFLValueType();

  bool isInteger(FLValue value) => cblite.FLValue_IsInteger(value);

  bool isDouble(FLValue value) => cblite.FLValue_IsDouble(value);

  bool asBool(FLValue value) => cblite.FLValue_AsBool(value);

  int asInt(FLValue value) => cblite.FLValue_AsInt(value);

  double asDouble(FLValue value) => cblite.FLValue_AsDouble(value);

  String? asString(FLValue value) =>
      cblite.FLValue_AsString(value).toDartString();

  Data? asData(FLValue value) => cblite.FLValue_AsData(value).toData();

  String? scalarToString(FLValue value) =>
      cblite.FLValue_ToString(value).toDartStringAndRelease();

  bool isEqual(FLValue a, FLValue b) => cblite.FLValue_IsEqual(a, b);

  void retain(FLValue value) => cblite.FLValue_Retain(value);

  void release(FLValue value) => cblite.FLValue_Release(value);

  String toJSONX(
    FLValue value, {
    required bool json5,
    required bool canonical,
  }) =>
      cblite.FLValue_ToJSONX(value, json5, canonical).toDartStringAndRelease()!;
}

// === Array ===================================================================

typedef FLArray = cblite.FLArray;

final class ArrayBindings {
  const ArrayBindings();

  int count(FLArray array) => cblite.FLArray_Count(array);

  bool isEmpty(FLArray array) => cblite.FLArray_IsEmpty(array);

  FLMutableArray? asMutable(FLArray array) =>
      cblite.FLArray_AsMutable(array).toNullable();

  FLValue get(FLArray array, int index) => cblite.FLArray_Get(array, index);
}

// === MutableArray ============================================================

typedef FLMutableArray = cblite.FLMutableArray;

final class MutableArrayBindings {
  const MutableArrayBindings();

  FLMutableArray mutableCopy(
    FLArray array,
    Set<FLCopyFlag> flags,
  ) =>
      cblite.FLArray_MutableCopy(array, flags.toCFlags());

  FLMutableArray create() => cblite.FLMutableArray_New();

  FLArray? getSource(FLMutableArray array) =>
      cblite.FLMutableArray_GetSource(array).toNullable();

  bool isChanged(FLMutableArray array) =>
      cblite.FLMutableArray_IsChanged(array);

  FLSlot set(FLMutableArray array, int index) =>
      cblite.FLMutableArray_Set(array, index);

  FLSlot append(FLMutableArray array) => cblite.FLMutableArray_Append(array);

  void insert(FLMutableArray array, int index, int count) =>
      cblite.FLMutableArray_Insert(array, index, count);

  void remove(FLMutableArray array, int firstIndex, int count) =>
      cblite.FLMutableArray_Remove(array, firstIndex, count);

  void resize(FLMutableArray array, int size) =>
      cblite.FLMutableArray_Resize(array, size);

  FLMutableArray? getMutableArray(
    FLMutableArray array,
    int index,
  ) =>
      cblite.FLMutableArray_GetMutableArray(array, index).toNullable();

  FLMutableDict? getMutableDict(
    FLMutableArray array,
    int index,
  ) =>
      cblite.FLMutableArray_GetMutableDict(array, index).toNullable();
}

// === Dict ====================================================================

typedef FLDict = cblite.FLDict;

final class DictBindings {
  const DictBindings();

  FLValue? get(FLDict dict, String key) =>
      runWithSingleFLString(key, (flKey) => cblite.FLDict_Get(dict, flKey))
          .toNullable();

  FLValue? getWithFLString(FLDict dict, FLString key) =>
      cblite.FLDict_Get(dict, key).toNullable();

  int count(FLDict dict) => cblite.FLDict_Count(dict);

  bool isEmpty(FLDict dict) => cblite.FLDict_IsEmpty(dict);

  FLMutableDict? asMutable(FLDict dict) =>
      cblite.FLDict_AsMutable(dict).toNullable();
}

typedef FLDictKey = cblite.FLDictKey;

final class DictKeyBindings {
  const DictKeyBindings();

  FLDictKey init(FLString key) => cblite.FLDictKey_Init(key);

  FLValue? getWithKey(FLDict dict, Pointer<FLDictKey> key) =>
      cblite.FLDict_GetWithKey(dict, key).toNullable();
}

// === MutableDict =============================================================

typedef FLMutableDict = cblite.FLMutableDict;

final class MutableDictBindings {
  const MutableDictBindings();

  FLMutableDict mutableCopy(
    FLDict source,
    Set<FLCopyFlag> flags,
  ) =>
      cblite.FLDict_MutableCopy(source, flags.toCFlags());

  FLMutableDict create() => cblite.FLMutableDict_New();

  FLDict? getSource(FLMutableDict dict) =>
      cblite.FLMutableDict_GetSource(dict).toNullable();

  bool isChanged(FLMutableDict dict) => cblite.FLMutableDict_IsChanged(dict);

  FLSlot set(FLMutableDict dict, String key) => runWithSingleFLString(
        key,
        (flKey) => cblite.FLMutableDict_Set(dict, flKey),
      );

  void remove(FLMutableDict dict, String key) {
    runWithSingleFLString(
      key,
      (flKey) => cblite.FLMutableDict_Remove(dict, flKey),
    );
  }

  void removeAll(FLMutableDict dict) {
    cblite.FLMutableDict_RemoveAll(dict);
  }

  FLMutableArray? getMutableArray(
    FLMutableDict array,
    String key,
  ) =>
      runWithSingleFLString(
        key,
        (flKey) =>
            cblite.FLMutableDict_GetMutableArray(array, flKey).toNullable(),
      );

  FLMutableDict? getMutableDict(
    FLMutableDict array,
    String key,
  ) =>
      runWithSingleFLString(
        key,
        (flKey) =>
            cblite.FLMutableDict_GetMutableDict(array, flKey).toNullable(),
      );
}

// === Decoder =================================================================

@pragma('vm:prefer-inline')
String decodeFLString(Pointer<void> buf, int size) =>
    utf8.decode(buf.cast<Uint8>().asTypedList(size));

enum FLTrust {
  untrusted,
  trusted,
}

extension on FLTrust {
  int toInt() => index;
}

typedef KnownSharedKeys = cblitedart.KnownSharedKeys;

typedef CBLDart_LoadedDictKey = cblitedart.CBLDart_LoadedDictKey;

typedef CBLDart_LoadedFLValue = cblitedart.CBLDart_LoadedFLValue;

// ignore: camel_case_extensions
extension CBLDart_LoadedFLValueExt on CBLDart_LoadedFLValue {
  FLValueType get dartType => type.toFLValueType();
}

typedef CBLDart_FLDictIterator = cblitedart.CBLDart_FLDictIterator;

typedef CBLDart_FLArrayIterator = cblitedart.CBLDart_FLArrayIterator;

final class FleeceDecoderBindings {
  const FleeceDecoderBindings();

  static final _knownSharedKeysFinalizer = NativeFinalizer(Native.addressOf<
              NativeFunction<cblitedart.NativeCBLDart_KnownSharedKeys_Delete>>(
          cblitedart.CBLDart_KnownSharedKeys_Delete)
      .cast());
  static final _dictIteratorFinalizer = NativeFinalizer(Native.addressOf<
              NativeFunction<cblitedart.NativeCBLDart_FLDictIterator_Delete>>(
          cblitedart.CBLDart_FLDictIterator_Delete)
      .cast());
  static final _arrayIteratorFinalizer = NativeFinalizer(Native.addressOf<
              NativeFunction<cblitedart.NativeCBLDart_FLArrayIterator_Delete>>(
          cblitedart.CBLDart_FLArrayIterator_Delete)
      .cast());

  String dumpData(Data data) =>
      cblite.FLData_Dump(data.toSliceResult().makeGlobal().ref)
          .toDartStringAndRelease()!;

  Pointer<KnownSharedKeys> createKnownSharedKeys(Finalizable object) {
    final result = cblitedart.CBLDart_KnownSharedKeys_New();
    _knownSharedKeysFinalizer.attach(object, result.cast());
    return result;
  }

  void getLoadedValue(FLValue value) {
    cblitedart.CBLDart_GetLoadedFLValue(value, globalLoadedFLValue);
  }

  void getLoadedValueFromArray(
    FLArray array,
    int index,
  ) {
    cblitedart.CBLDart_FLArray_GetLoadedFLValue(
      array,
      index,
      globalLoadedFLValue,
    );
  }

  void getLoadedValueFromDict(
    FLDict array,
    String key,
  ) {
    runWithSingleFLString(key, (flKey) {
      cblitedart.CBLDart_FLDict_GetLoadedFLValue(
        array,
        flKey,
        globalLoadedFLValue,
      );
    });
  }

  Pointer<CBLDart_FLDictIterator> dictIteratorBegin(
    Finalizable? object,
    FLDict dict,
    Pointer<KnownSharedKeys> knownSharedKeys,
    Pointer<CBLDart_LoadedDictKey> keyOut,
    Pointer<CBLDart_LoadedFLValue> valueOut, {
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

  bool dictIteratorNext(Pointer<CBLDart_FLDictIterator> iterator) =>
      cblitedart.CBLDart_FLDictIterator_Next(iterator);

  Pointer<CBLDart_FLArrayIterator> arrayIteratorBegin(
    Finalizable? object,
    FLArray array,
    Pointer<CBLDart_LoadedFLValue> valueOut,
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

  bool arrayIteratorNext(Pointer<CBLDart_FLArrayIterator> iterator) =>
      cblitedart.CBLDart_FLArrayIterator_Next(iterator);
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

typedef FLEncoder = cblite.FLEncoder;

final class FleeceEncoderBindings {
  const FleeceEncoderBindings();

  static final _finalizer = NativeFinalizer(
      Native.addressOf<NativeFunction<cblite.NativeFLEncoder_Free>>(
              cblite.FLEncoder_Free)
          .cast());

  void bindToDartObject(Finalizable object, FLEncoder encoder) {
    _finalizer.attach(object, encoder.cast());
  }

  FLEncoder create({
    required FLEncoderFormat format,
    required int reserveSize,
    required bool uniqueStrings,
  }) =>
      cblite.FLEncoder_NewWithOptions(
        format.toInt(),
        reserveSize,
        uniqueStrings,
      );

  void setSharedKeys(FLEncoder encoder, FLSharedKeys keys) {
    cblite.FLEncoder_SetSharedKeys(encoder, keys);
  }

  void reset(FLEncoder encoder) {
    cblite.FLEncoder_Reset(encoder);
  }

  void writeArrayValue(
    FLEncoder encoder,
    FLArray array,
    int index,
  ) {
    _checkError(
      encoder,
      cblitedart.CBLDart_FLEncoder_WriteArrayValue(encoder, array, index),
    );
  }

  void writeValue(FLEncoder encoder, FLValue value) {
    if (value == nullptr) {
      throw ArgumentError.value(value, 'value', 'must not be `nullptr`');
    }

    _checkError(encoder, cblite.FLEncoder_WriteValue(encoder, value));
  }

  void writeNull(FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_WriteNull(encoder));
  }

  void writeBool(FLEncoder encoder, bool value) {
    _checkError(encoder, cblite.FLEncoder_WriteBool(encoder, value));
  }

  void writeInt(FLEncoder encoder, int value) {
    _checkError(encoder, cblite.FLEncoder_WriteInt(encoder, value));
  }

  void writeDouble(FLEncoder encoder, double value) {
    _checkError(encoder, cblite.FLEncoder_WriteDouble(encoder, value));
  }

  void writeString(FLEncoder encoder, String value) {
    runWithSingleFLString(value, (flValue) {
      _checkError(encoder, cblite.FLEncoder_WriteString(encoder, flValue));
    });
  }

  void writeData(FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cblite.FLEncoder_WriteData(encoder, sliceResult.makeGlobal().ref),
    );
  }

  void writeJSON(FLEncoder encoder, Data value) {
    final sliceResult = value.toSliceResult();
    _checkError(
      encoder,
      cblite.FLEncoder_ConvertJSON(
        encoder,
        sliceResult.makeGlobal().cast<FLString>().ref,
      ),
    );
  }

  void beginArray(FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cblite.FLEncoder_BeginArray(encoder, reserveCount));
  }

  void endArray(FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_EndArray(encoder));
  }

  void beginDict(FLEncoder encoder, int reserveCount) {
    _checkError(encoder, cblite.FLEncoder_BeginDict(encoder, reserveCount));
  }

  void writeKey(FLEncoder encoder, String key) {
    runWithSingleFLString(key, (flKey) {
      _checkError(encoder, cblite.FLEncoder_WriteKey(encoder, flKey));
    });
  }

  void writeKeyFLString(FLEncoder encoder, FLString key) {
    _checkError(encoder, cblite.FLEncoder_WriteKey(encoder, key));
  }

  void writeKeyValue(FLEncoder encoder, FLValue key) {
    _checkError(encoder, cblite.FLEncoder_WriteKeyValue(encoder, key));
  }

  void endDict(FLEncoder encoder) {
    _checkError(encoder, cblite.FLEncoder_EndDict(encoder));
  }

  Data? finish(FLEncoder encoder) =>
      _checkError(encoder, cblite.FLEncoder_Finish(encoder, globalFLErrorCode))
          .let(SliceResult.fromFLSliceResult)
          ?.toData();

  FLErrorCode _getError(FLEncoder encoder) =>
      cblite.FLEncoder_GetError(encoder).toFleeceErrorCode();

  String _getErrorMessage(FLEncoder encoder) =>
      cblite.FLEncoder_GetErrorMessage(encoder)
          .cast<Utf8>()
          .toDartStringAndFree();

  T _checkError<T>(FLEncoder encoder, T result) {
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
