import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../ffi_utils.dart';
import '../fleece.dart';
import 'base.dart';
import 'bindings.dart';

// === Common ==================================================================

/// Error codes returned from some API calls.
enum FleeceErrorCode {
  noError,

  /// Out of memory, or allocation failed.
  memoryError,

  /// Array index or iterator out of range.
  outOfRange,

  /// Bad input data (NaN, non-string key, etc.).
  invalidData,

  /// Structural error encoding (missing value, too many ends, etc.).
  encodeError,

  /// Error parsing JSON.
  jsonError,

  /// Unparseable data in a Value (corrupt? Or from some distant future?).
  unknownValue,

  /// Something that shouldn't happen.
  internalError,

  /// Key not found.
  notFound,

  /// Misuse of shared keys (not in transaction, etc.)
  sharedKeysStateError,
  posixError,

  /// Operation is unsupported
  unsupported,
}

extension FleeceErrorCodeIntExt on int {
  FleeceErrorCode get toFleeceErrorCode {
    assert(this >= 0 && this <= 12);
    return FleeceErrorCode.values[this];
  }
}

/// Options for how values are copied.
///
/// See:
/// - [MutableArray.mutableCopy] for copying arrays.
/// - [MutableDict.mutableCopy] for copying dictionaries.
class CopyFlag extends Option {
  const CopyFlag._(String name, int bits) : super(name, bits);

  /// Make a deep copy instead of a shallow copy, by recursively copying values.
  static const deepCopy = CopyFlag._('deepCopy', 1);

  /// Copy immutables instead of referencing them.
  static const copyImmutables = CopyFlag._('copyImmutables', 2);
}

class FLSlice extends Struct {
  external Pointer<Uint8> buf;

  // TODO: use correct type
  // This is actually a size_t, but Dart FFI does not support it yet.
  // See https://github.com/dart-lang/sdk/issues/36140.
  // We work around this by translating between an actual FLSlice(Result)
  // and this fixed size struct.
  @Uint64()
  external int size;
}

extension FLSliceExt on FLSlice {
  String toDartString() => buf.cast<Utf8>().toDartString(length: size);
}

extension FLSlicePointerExt on Pointer<FLSlice> {
  String toDartStringAndFree() {
    final string = ref.toDartString();
    CBLBindings.instance.fleece.slice.release(this);
    return string;
  }
}

extension StringFLSliceExt on String {
  Pointer<FLSlice> get asSliceScoped {
    final slice = scoped(malloc<FLSlice>());
    final units = utf8.encode(this);
    final buf = scoped(malloc<Uint8>(units.length));

    buf.asTypedList(length).setAll(0, units);

    slice.ref.buf = buf;
    slice.ref.size = units.length;

    return slice;
  }
}

extension TypedDataFLSliceExt on TypedData {
  Pointer<FLSlice> toFLSliceScoped() {
    final buf = scoped(malloc<Uint8>(lengthInBytes));
    buf.asTypedList(lengthInBytes).setAll(0, buffer.asUint8List());
    final slice = scoped(malloc<FLSlice>());
    slice.ref.buf = buf;
    slice.ref.size = lengthInBytes;
    return slice;
  }
}

typedef CBLDart_FLSliceResult_Release_C = Void Function(Pointer<FLSlice>);
typedef CBLDart_FLSliceResult_Release = void Function(Pointer<FLSlice>);

class SliceBindings {
  SliceBindings(Libraries libs)
      : release = libs.cblDart.lookupFunction<CBLDart_FLSliceResult_Release_C,
            CBLDart_FLSliceResult_Release>(
          'CBLDart_FLSliceResult_Release',
        );

  CBLDart_FLSliceResult_Release release;
}

// TODO: Replace Void with FLSlot where appropriate
class FLSlot extends Opaque {}

typedef FLSlot_SetNull_C = Void Function(Pointer<FLSlot> slot);
typedef FLSlot_SetNull = void Function(Pointer<FLSlot> slot);

typedef FLSlot_SetBool_C = Void Function(Pointer<FLSlot> slot, Uint8 value);
typedef FLSlot_SetBool = void Function(Pointer<FLSlot> slot, int value);

typedef FLSlot_SetInt_C = Void Function(Pointer<FLSlot> slot, Int64 value);
typedef FLSlot_SetInt = void Function(Pointer<FLSlot> slot, int value);

typedef FLSlot_SetDouble_C = Void Function(Pointer<FLSlot> slot, Double value);
typedef FLSlot_SetDouble = void Function(Pointer<FLSlot> slot, double value);

typedef CBLDart_FLSlot_SetString_C = Void Function(
  Pointer<FLSlot> slot,
  Pointer<Utf8> value,
);
typedef CBLDart_FLSlot_SetString = void Function(
  Pointer<FLSlot> slot,
  Pointer<Utf8> value,
);

typedef FLSlot_SetValue_C = Void Function(
  Pointer<FLSlot> slot,
  Pointer<Void> value,
);
typedef FLSlot_SetValue = void Function(
  Pointer<FLSlot> slot,
  Pointer<Void> value,
);

class SlotBindings {
  SlotBindings(Libraries libs)
      : setNull = libs.cbl.lookupFunction<FLSlot_SetNull_C, FLSlot_SetNull>(
          'FLSlot_SetNull',
        ),
        setBool = libs.cbl.lookupFunction<FLSlot_SetBool_C, FLSlot_SetBool>(
          'FLSlot_SetBool',
        ),
        setInt = libs.cbl.lookupFunction<FLSlot_SetInt_C, FLSlot_SetInt>(
          'FLSlot_SetInt',
        ),
        setDouble =
            libs.cbl.lookupFunction<FLSlot_SetDouble_C, FLSlot_SetDouble>(
          'FLSlot_SetDouble',
        ),
        setString = libs.cblDart.lookupFunction<CBLDart_FLSlot_SetString_C,
            CBLDart_FLSlot_SetString>(
          'CBLDart_FLSlot_SetString',
        ),
        setValue = libs.cbl.lookupFunction<FLSlot_SetValue_C, FLSlot_SetValue>(
          'FLSlot_SetValue',
        );

  final FLSlot_SetNull setNull;
  final FLSlot_SetBool setBool;
  final FLSlot_SetInt setInt;
  final FLSlot_SetDouble setDouble;
  final CBLDart_FLSlot_SetString setString;
  final FLSlot_SetValue setValue;
}

// === Doc =====================================================================

typedef CBLDart_FLDoc_FromJSON = Pointer<Void> Function(
  Pointer<Utf8> json,
  Pointer<Uint8> error,
);

typedef CBLDart_FLDoc_BindToDartObject_C = Void Function(
  Handle dartDoc,
  Pointer<Void> doc,
);
typedef CBLDart_FLDoc_BindToDartObject = void Function(
  Object dartDoc,
  Pointer<Void> doc,
);

typedef FLDoc_GetRoot = Pointer<Void> Function(Pointer<Void> doc);

class DocBindings {
  DocBindings(Libraries libs)
      : fromJSON = libs.cblDart
            .lookupFunction<CBLDart_FLDoc_FromJSON, CBLDart_FLDoc_FromJSON>(
          'CBLDart_FLDoc_FromJSON',
        ),
        bindToDartObject = libs.cblDart.lookupFunction<
            CBLDart_FLDoc_BindToDartObject_C, CBLDart_FLDoc_BindToDartObject>(
          'CBLDart_FLDoc_BindToDartObject',
        ),
        getRoot = libs.cbl.lookupFunction<FLDoc_GetRoot, FLDoc_GetRoot>(
          'FLDoc_GetRoot',
        );

  final CBLDart_FLDoc_FromJSON fromJSON;
  final CBLDart_FLDoc_BindToDartObject bindToDartObject;
  final FLDoc_GetRoot getRoot;
}

// === Value ===================================================================

// TODO: Replace Void with FLValue where appropriate
class FLValue extends Opaque {}

/// Types of Fleece values. Basically JSON, with the addition of Data
/// (raw blob).
enum ValueType {
  /// Type of a null pointer, i.e. no such value, like JSON `undefined`.
  /// Also the type of a value created by FLEncoder_WriteUndefined().
  // TODO: update docs when encoder is implemented
  undefined,

  /// Equivalent to a JSON 'null'.
  Null,

  /// A `true` or `false` value.
  boolean,

  /// A numeric value, either integer or floating-point.
  number,

  /// A string.
  string,

  /// Binary data (no JSON equivalent).
  data,

  /// An array of values.
  array,

  /// A mapping of strings to values
  dict,
}

extension ValueTypeIntExt on int {
  ValueType get toFleeceValueType {
    assert(this >= -1 && this <= 6);
    return ValueType.values[this + 1];
  }
}

typedef CBLDart_FLValue_BindToDartObject_C = Void Function(
  Handle dartDoc,
  Pointer<Void> value,
  Uint8 retain,
);
typedef CBLDart_FLValue_BindToDartObject = void Function(
  Object dartDoc,
  Pointer<Void> value,
  int retain,
);

typedef FLValue_FindDoc = Pointer<Void> Function(Pointer<Void>);

typedef FLValue_GetType_C = Int8 Function(Pointer<Void> value);
typedef FLValue_GetType = int Function(Pointer<Void> value);

typedef FLValue_IsInteger_C = Uint8 Function(Pointer<Void> value);
typedef FLValue_IsInteger = int Function(Pointer<Void> value);

typedef FLValue_IsDouble_C = Uint8 Function(Pointer<Void> value);
typedef FLValue_IsDouble = int Function(Pointer<Void> value);

typedef FLValue_AsBool_C = Uint8 Function(Pointer<Void> value);
typedef FLValue_AsBool = int Function(Pointer<Void> value);

typedef FLValue_AsInt_C = Int8 Function(Pointer<Void> value);
typedef FLValue_AsInt = int Function(Pointer<Void> value);

typedef FLValue_AsDouble_C = Double Function(Pointer<Void> value);
typedef FLValue_AsDouble = double Function(Pointer<Void> value);

typedef FLValue_AsString_C = Void Function(
  Pointer<Void> value,
  Pointer<FLSlice> slice,
);
typedef FLValue_AsString = void Function(
  Pointer<Void> value,
  Pointer<FLSlice> slice,
);

typedef CBLDart_FLValue_ToString_C = Void Function(
  Pointer<Void> value,
  Pointer<FLSlice> slice,
);
typedef CBLDart_FLValue_ToString = void Function(
  Pointer<Void> value,
  Pointer<FLSlice> slice,
);

typedef FLValue_IsEqual_C = Uint8 Function(Pointer<Void> v1, Pointer<Void> v2);
typedef FLValue_IsEqual = int Function(Pointer<Void> v1, Pointer<Void> v2);

typedef CBLDart_FLValue_ToJSONX_C = Void Function(
  Pointer<Void> value,
  Uint8 json5,
  Uint8 canonicalForm,
  Pointer<FLSlice> result,
);
typedef CBLDart_FLValue_ToJSONX = void Function(
  Pointer<Void> value,
  int json5,
  int canonicalForm,
  Pointer<FLSlice> result,
);

class ValueBindings {
  ValueBindings(Libraries libs)
      : bindToDartObject = libs.cblDart.lookupFunction<
            CBLDart_FLValue_BindToDartObject_C,
            CBLDart_FLValue_BindToDartObject>(
          'CBLDart_FLValue_BindToDartObject',
        ),
        findDoc = libs.cbl.lookupFunction<FLValue_FindDoc, FLValue_FindDoc>(
          'FLValue_FindDoc',
        ),
        getType = libs.cbl.lookupFunction<FLValue_GetType_C, FLValue_GetType>(
          'FLValue_GetType',
        ),
        isInteger =
            libs.cbl.lookupFunction<FLValue_IsInteger_C, FLValue_IsInteger>(
          'FLValue_IsInteger',
        ),
        isDouble =
            libs.cbl.lookupFunction<FLValue_IsDouble_C, FLValue_IsDouble>(
          'FLValue_IsDouble',
        ),
        asBool = libs.cbl.lookupFunction<FLValue_AsBool_C, FLValue_AsBool>(
          'FLValue_AsBool',
        ),
        asInt = libs.cbl.lookupFunction<FLValue_AsInt_C, FLValue_AsInt>(
          'FLValue_AsInt',
        ),
        asDouble =
            libs.cbl.lookupFunction<FLValue_AsDouble_C, FLValue_AsDouble>(
          'FLValue_AsDouble',
        ),
        asString =
            libs.cblDart.lookupFunction<FLValue_AsString_C, FLValue_AsString>(
          'CBLDart_FLValue_AsString',
        ),
        scalarToString = libs.cblDart.lookupFunction<CBLDart_FLValue_ToString_C,
            CBLDart_FLValue_ToString>(
          'CBLDart_FLValue_ToString',
        ),
        isEqual = libs.cbl.lookupFunction<FLValue_IsEqual_C, FLValue_IsEqual>(
          'FLValue_IsEqual',
        ),
        toJson = libs.cblDart
            .lookupFunction<CBLDart_FLValue_ToJSONX_C, CBLDart_FLValue_ToJSONX>(
          'CBLDart_FLValue_ToJSONX',
        );

  final CBLDart_FLValue_BindToDartObject bindToDartObject;
  final FLValue_FindDoc findDoc;
  final FLValue_GetType getType;
  final FLValue_IsInteger isInteger;
  final FLValue_IsDouble isDouble;
  final FLValue_AsBool asBool;
  final FLValue_AsInt asInt;
  final FLValue_AsDouble asDouble;
  final FLValue_AsString asString;
  final CBLDart_FLValue_ToString scalarToString;
  final FLValue_IsEqual isEqual;
  final CBLDart_FLValue_ToJSONX toJson;
}

// === Array ===================================================================

// TODO: Replace Void with FLArray where appropriate
class FLArray extends Opaque {}

typedef FLArray_Count_C = Uint32 Function(Pointer<Void> array);
typedef FLArray_Count = int Function(Pointer<Void> array);

typedef FLArray_IsEmpty_C = Uint8 Function(Pointer<Void> array);
typedef FLArray_IsEmpty = int Function(Pointer<Void> array);

typedef FLArray_AsMutable = Pointer<Void> Function(Pointer<Void> array);

typedef FLArray_Get_C = Pointer<Void> Function(
    Pointer<Void> array, Uint32 index);
typedef FLArray_Get = Pointer<Void> Function(
  Pointer<Void> array,
  int index,
);

class ArrayBindings {
  ArrayBindings(Libraries libs)
      : count = libs.cbl.lookupFunction<FLArray_Count_C, FLArray_Count>(
          'FLArray_Count',
        ),
        isEmpty = libs.cbl.lookupFunction<FLArray_IsEmpty_C, FLArray_IsEmpty>(
          'FLArray_IsEmpty',
        ),
        asMutable =
            libs.cbl.lookupFunction<FLArray_AsMutable, FLArray_AsMutable>(
          'FLArray_AsMutable',
        ),
        get = libs.cbl.lookupFunction<FLArray_Get_C, FLArray_Get>(
          'FLArray_Get',
        );

  final FLArray_Count count;
  final FLArray_IsEmpty isEmpty;
  final FLArray_AsMutable asMutable;
  final FLArray_Get get;
}

// endregion

// region MutableArray

typedef FLArray_MutableCopy_C = Pointer<Void> Function(
  Pointer<Void> array,
  Uint32 flags,
);
typedef FLArray_MutableCopy = Pointer<Void> Function(
  Pointer<Void> array,
  int flags,
);

typedef FLMutableArray_New = Pointer<Void> Function();

typedef FLMutableArray_GetSource = Pointer<Void> Function(Pointer<Void> array);

typedef FLMutableArray_IsChanged_C = Uint8 Function(Pointer<Void> array);
typedef FLMutableArray_IsChanged = int Function(Pointer<Void> array);

typedef FLMutableArray_Set_C = Pointer<FLSlot> Function(
  Pointer<Void> array,
  Uint32 index,
);
typedef FLMutableArray_Set = Pointer<FLSlot> Function(
  Pointer<Void> array,
  int index,
);

typedef FLMutableArray_Append = Pointer<FLSlot> Function(Pointer<Void> array);

typedef FLMutableArray_Insert_C = Void Function(
  Pointer<Void> array,
  Uint32 firstIndex,
  Uint32 count,
);
typedef FLMutableArray_Insert = void Function(
  Pointer<Void> array,
  int firstIndex,
  int count,
);

typedef FLMutableArray_Remove_C = Void Function(
  Pointer<Void> array,
  Uint32 firstIndex,
  Uint32 count,
);
typedef FLMutableArray_Remove = void Function(
  Pointer<Void> array,
  int firstIndex,
  int count,
);

typedef FLMutableArray_Resize_C = Void Function(
  Pointer<Void> array,
  Uint32 size,
);
typedef FLMutableArray_Resize = void Function(
  Pointer<Void> array,
  int size,
);

typedef FLMutableArray_GetMutableArray_C = Pointer<Void> Function(
  Pointer<Void> array,
  Uint32 index,
);
typedef FLMutableArray_GetMutableArray = Pointer<Void> Function(
  Pointer<Void> array,
  int index,
);

typedef FLMutableArray_GetMutableDict_C = Pointer<Void> Function(
  Pointer<Void> array,
  Uint32 index,
);
typedef FLMutableArray_GetMutableDict = Pointer<Void> Function(
  Pointer<Void> array,
  int index,
);

class MutableArrayBindings {
  MutableArrayBindings(Libraries libs)
      : mutableCopy =
            libs.cbl.lookupFunction<FLArray_MutableCopy_C, FLArray_MutableCopy>(
          'FLArray_MutableCopy',
        ),
        makeNew =
            libs.cbl.lookupFunction<FLMutableArray_New, FLMutableArray_New>(
          'FLMutableArray_New',
        ),
        getSource = libs.cbl
            .lookupFunction<FLMutableArray_GetSource, FLMutableArray_GetSource>(
          'FLMutableArray_GetSource',
        ),
        isChanged = libs.cbl.lookupFunction<FLMutableArray_IsChanged_C,
            FLMutableArray_IsChanged>(
          'FLMutableArray_IsChanged',
        ),
        set = libs.cbl.lookupFunction<FLMutableArray_Set_C, FLMutableArray_Set>(
          'FLMutableArray_Set',
        ),
        append = libs.cbl
            .lookupFunction<FLMutableArray_Append, FLMutableArray_Append>(
          'FLMutableArray_Append',
        ),
        insert = libs.cbl
            .lookupFunction<FLMutableArray_Insert_C, FLMutableArray_Insert>(
          'FLMutableArray_Insert',
        ),
        remove = libs.cbl
            .lookupFunction<FLMutableArray_Remove_C, FLMutableArray_Remove>(
          'FLMutableArray_Remove',
        ),
        resize = libs.cbl
            .lookupFunction<FLMutableArray_Resize_C, FLMutableArray_Resize>(
          'FLMutableArray_Resize',
        ),
        getMutableArray = libs.cbl.lookupFunction<
            FLMutableArray_GetMutableArray_C, FLMutableArray_GetMutableArray>(
          'FLMutableArray_GetMutableArray',
        ),
        getMutableDict = libs.cbl.lookupFunction<
            FLMutableArray_GetMutableDict_C, FLMutableArray_GetMutableDict>(
          'FLMutableArray_GetMutableDict',
        );

  final FLArray_MutableCopy mutableCopy;
  final FLMutableArray_New makeNew;
  final FLMutableArray_GetSource getSource;
  final FLMutableArray_IsChanged isChanged;
  final FLMutableArray_Set set;
  final FLMutableArray_Append append;
  final FLMutableArray_Insert insert;
  final FLMutableArray_Remove remove;
  final FLMutableArray_Resize resize;
  final FLMutableArray_GetMutableArray getMutableArray;
  final FLMutableArray_GetMutableDict getMutableDict;
}

// === Dict ====================================================================

// TODO: Replace Void with FLDict where appropriate
class FLDict extends Opaque {}

typedef FLDict_Count_C = Uint32 Function(Pointer<Void> dict);
typedef FLDict_Count = int Function(Pointer<Void> dict);

typedef FLDict_IsEmpty_C = Uint8 Function(Pointer<Void> dict);
typedef FLDict_IsEmpty = int Function(Pointer<Void> dict);

typedef FLDict_AsMutable = Pointer<Void> Function(Pointer<Void>);

typedef FLDict_Get = Pointer<Void> Function(
  Pointer<Void> dict,
  Pointer<Utf8> key,
);

class DictBindings {
  DictBindings(Libraries libs)
      : get = libs.cblDart
            .lookupFunction<FLDict_Get, FLDict_Get>('CBLDart_FLDict_Get'),
        count = libs.cbl
            .lookupFunction<FLDict_Count_C, FLDict_Count>('FLDict_Count'),
        isEmpty = libs.cbl.lookupFunction<FLDict_IsEmpty_C, FLDict_IsEmpty>(
          'FLDict_IsEmpty',
        ),
        asMutable = libs.cbl.lookupFunction<FLDict_AsMutable, FLDict_AsMutable>(
          'FLDict_AsMutable',
        );

  final FLDict_Get get;
  final FLDict_Count count;
  final FLDict_IsEmpty isEmpty;
  final FLDict_AsMutable asMutable;
}

class DictIterator extends Struct {
  external Pointer<Void> get iterator;
  external FLSlice get keyString;
  @Uint8()
  external int get done;
}

typedef CBLDart_FLDictIterator_Begin_C = Pointer<DictIterator> Function(
  Handle handle,
  Pointer<FLDict> dict,
);

typedef CBLDart_FLDictIterator_Begin = Pointer<DictIterator> Function(
  Object handle,
  Pointer<FLDict> dict,
);

typedef CBLDart_FLDictIterator_Next_C = Void Function(
  Pointer<DictIterator> iterator,
);
typedef CBLDart_FLDictIterator_Next = void Function(
  Pointer<DictIterator> iterator,
);

class DictIteratorBindings {
  DictIteratorBindings(Libraries libs)
      : begin = libs.cblDart.lookupFunction<CBLDart_FLDictIterator_Begin_C,
            CBLDart_FLDictIterator_Begin>(
          'CBLDart_FLDictIterator_Begin',
        ),
        next = libs.cblDart.lookupFunction<CBLDart_FLDictIterator_Next_C,
            CBLDart_FLDictIterator_Next>(
          'CBLDart_FLDictIterator_Next',
        );

  final CBLDart_FLDictIterator_Begin begin;
  final CBLDart_FLDictIterator_Next next;
}

// endregion

// region MutableDict

typedef FLDict_MutableCopy_C = Pointer<Void> Function(
  Pointer<Void> source,
  Uint32 flags,
);
typedef FLDict_MutableCopy = Pointer<Void> Function(
  Pointer<Void> source,
  int flags,
);

typedef FLMutableDict_New = Pointer<Void> Function();

typedef FLMutableDict_GetSource = Pointer<Void> Function(Pointer<Void>);

typedef FLMutableDict_IsChanged_C = Uint8 Function(Pointer<Void> dict);
typedef FLMutableDict_IsChanged = int Function(Pointer<Void> dict);

typedef CBLDart_FLMutableDict_Set = Pointer<FLSlot> Function(
  Pointer<Void> dict,
  Pointer<Utf8> key,
);

typedef CBLDart_FLMutableDict_Remove_C = Void Function(
  Pointer<Void> dict,
  Pointer<Utf8> key,
);
typedef CBLDart_FLMutableDict_Remove = void Function(
  Pointer<Void> dict,
  Pointer<Utf8> key,
);

typedef FLMutableDict_RemoveAll_C = Void Function(Pointer<Void> dict);
typedef FLMutableDict_RemoveAll = void Function(Pointer<Void> dict);

typedef CBLDart_FLMutableDict_GetMutableArray = Pointer<Void> Function(
  Pointer<Void> dict,
  Pointer<Utf8> key,
);

typedef CBLDart_FLMutableDict_GetMutableDict = Pointer<Void> Function(
  Pointer<Void> dict,
  Pointer<Utf8> key,
);

class MutableDictBindings {
  MutableDictBindings(Libraries libs)
      : mutableCopy =
            libs.cbl.lookupFunction<FLDict_MutableCopy_C, FLDict_MutableCopy>(
          'FLDict_MutableCopy',
        ),
        makeNew = libs.cbl.lookupFunction<FLMutableDict_New, FLMutableDict_New>(
          'FLMutableDict_New',
        ),
        getSource = libs.cbl
            .lookupFunction<FLMutableDict_GetSource, FLMutableDict_GetSource>(
          'FLMutableDict_GetSource',
        ),
        isChanged = libs.cbl
            .lookupFunction<FLMutableDict_IsChanged_C, FLMutableDict_IsChanged>(
          'FLMutableDict_IsChanged',
        ),
        set = libs.cblDart.lookupFunction<CBLDart_FLMutableDict_Set,
            CBLDart_FLMutableDict_Set>(
          'CBLDart_FLMutableDict_Set',
        ),
        remove = libs.cblDart.lookupFunction<CBLDart_FLMutableDict_Remove_C,
            CBLDart_FLMutableDict_Remove>(
          'CBLDart_FLMutableDict_Remove',
        ),
        removeAll = libs.cbl
            .lookupFunction<FLMutableDict_RemoveAll_C, FLMutableDict_RemoveAll>(
          'FLMutableDict_RemoveAll',
        ),
        getMutableArray = libs.cblDart.lookupFunction<
            CBLDart_FLMutableDict_GetMutableArray,
            CBLDart_FLMutableDict_GetMutableArray>(
          'CBLDart_FLMutableDict_GetMutableArray',
        ),
        getMutableDict = libs.cblDart.lookupFunction<
            CBLDart_FLMutableDict_GetMutableDict,
            CBLDart_FLMutableDict_GetMutableDict>(
          'CBLDart_FLMutableDict_GetMutableDict',
        );

  final FLDict_MutableCopy mutableCopy;
  final FLMutableDict_New makeNew;
  final FLMutableDict_GetSource getSource;
  final FLMutableDict_IsChanged isChanged;
  final CBLDart_FLMutableDict_Set set;
  final CBLDart_FLMutableDict_Remove remove;
  final FLMutableDict_RemoveAll removeAll;
  final CBLDart_FLMutableDict_GetMutableArray getMutableArray;
  final CBLDart_FLMutableDict_GetMutableDict getMutableDict;
}

// === FleeceBindings ==========================================================

class FleeceBindings {
  FleeceBindings(Libraries libs)
      : slice = SliceBindings(libs),
        slot = SlotBindings(libs),
        doc = DocBindings(libs),
        value = ValueBindings(libs),
        array = ArrayBindings(libs),
        mutableArray = MutableArrayBindings(libs),
        dict = DictBindings(libs),
        dictIterator = DictIteratorBindings(libs),
        mutableDict = MutableDictBindings(libs);

  final SliceBindings slice;
  final SlotBindings slot;
  final DocBindings doc;
  final ValueBindings value;
  final ArrayBindings array;
  final MutableArrayBindings mutableArray;
  final DictBindings dict;
  final DictIteratorBindings dictIterator;
  final MutableDictBindings mutableDict;
}
