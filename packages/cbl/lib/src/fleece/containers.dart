// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:collection/collection.dart';

import '../support/errors.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/utils.dart';
import 'decoder.dart';
import 'encoder.dart';

/// Options for how values are copied.
enum CopyFlag {
  /// Make a deep copy instead of a shallow copy, by recursively copying values.
  deepCopy,

  /// Copy immutables instead of referencing them.
  copyImmutables,
}

extension on CopyFlag {
  FLCopyFlag toFLCopyFlag() => FLCopyFlag.values[index];
}

extension on Iterable<CopyFlag> {
  Set<FLCopyFlag> toFLCopyFlags() => map((flag) => flag.toFLCopyFlag()).toSet();
}

// === SharedKeys ==============================================================

/// FLSharedKeys represents a mapping from short strings to small integers in
/// the range [0...2047]
class SharedKeys extends FleeceSharedKeysObject {
  /// Creates new empty [SharedKeys].
  SharedKeys() : this.fromPointer(_bindings.create());

  /// Creates [SharedKeys] from an exiting native instance.
  SharedKeys.fromPointer(Pointer<FLSharedKeys> pointer, {bool adopt = true})
      : super(pointer, adopt: adopt);

  static late final _bindings = cblBindings.fleece.sharedKeys;

  /// The number of keys in the mapping.
  ///
  /// This number increases whenever the mapping is changed, and never
  /// decreases.
  int get count {
    final result = _bindings.count(pointer);
    cblReachabilityFence(this);
    return result;
  }
}

// === Doc =====================================================================

/// A [Doc] points to (and often owns) Fleece-encoded data and provides access
/// to its Fleece values.
class Doc extends FleeceDocObject {
  /// Creates a [Doc] by reading Fleece [data] as encoded by a [FleeceEncoder].
  factory Doc.fromResultData(
    Data data,
    FLTrust trust, {
    SharedKeys? sharedKeys,
  }) {
    final docPointer =
        _bindings.fromResultData(data, trust, sharedKeys?.pointer);
    cblReachabilityFence(sharedKeys);
    return Doc.fromPointer(docPointer);
  }

  /// Creates a [Doc] from JSON-encoded data.
  ///
  /// The data is first encoded into Fleece, and the Fleece data is kept by the
  /// doc.
  factory Doc.fromJson(String json) =>
      runWithErrorTranslation(() => Doc.fromPointer(_bindings.fromJson(json)));

  /// Creates an [Doc] based on a [pointer] to the the native value.
  ///
  /// Note: Does not retain the native doc.
  Doc.fromPointer(Pointer<FLDoc> pointer) : super(pointer);

  static late final _bindings = cblBindings.fleece.doc;

  /// Returns the data owned by the document, if any, else `null`.
  SliceResult? get allocedData {
    final result =
        SliceResult.fromFLSliceResult(_bindings.getAllocedData(pointer));
    cblReachabilityFence(this);
    return result;
  }

  /// Returns the root value in the [Doc], usually an [Dict].
  Value get root {
    final result = Value.fromPointer(_bindings.getRoot(pointer));
    cblReachabilityFence(this);
    return result;
  }

  /// Returns the [SharedKeys] used by this [Doc], as specified when it was
  /// created.
  SharedKeys? get sharedKeys {
    final sharedKeysPointer = _bindings.getSharedKeys(pointer);
    final result = sharedKeysPointer
        ?.let((it) => SharedKeys.fromPointer(it, adopt: false));
    cblReachabilityFence(this);
    return result;
  }
}

// === Value ===================================================================

/// Types of Fleece values. Basically JSON, with the addition of Data
/// (raw blob).
enum ValueType {
  /// Type of a null pointer, i.e. no such value, like JSON `undefined`.
  undefined,

  /// Equivalent to a JSON 'null'.
  // ignore: constant_identifier_names
  null_,

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

extension on FLValueType {
  ValueType toValueType() => ValueType.values[index];
}

/// The core Fleece data type is Value: a reference to a value in Fleece-encoded
/// data. A Value can represent any JSON type (plus binary data).
///
/// - Scalar data types -- numbers, booleans, null, strings, data -- can be
///   accessed using individual functions of the form `as...`; these return the
///   scalar value, or a default zero/false/null value if the value is not of
///   that type.
/// - Collections -- arrays and dictionaries -- have their own subclasses: Array
///   and Dict. To coerce an Value to a collection type, call [asArray] or
///   [asDict]. If the value is not of that type, null is returned. (Array and
///   Dict are documented fully in their own sections.)
class Value extends FleeceValueObject<FLValue> {
  /// Creates a [Value] based on a [pointer] to the the native value.
  ///
  /// Accessing immutable values is only allowed, while the enclosing container
  /// ([Doc], [MutableArray], [MutableDict] and other objects, holding Fleece
  /// data) has not been garbage collected.
  Value.fromPointer(
    Pointer<FLValue> pointer, {
    bool isRefCounted = true,
    bool adopt = false,
  }) : super(
          pointer.cast(),
          isRefCounted: isRefCounted,
          adopt: adopt,
        );

  static late final _bindings = cblBindings.fleece.value;

  /// Looks up the Doc containing the Value, or null if the Value was created
  /// without a Doc.
  Doc? get doc {
    final docPointer = _bindings.findDoc(pointer);
    final result = docPointer?.let(Doc.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns the data type of an arbitrary Value.
  ValueType get type {
    final result = _bindings.getType(pointer).toValueType();
    cblReachabilityFence(this);
    return result;
  }

  /// Whether this value represents an `undefined` value.
  bool get isUndefined => type == ValueType.undefined;

  /// Whether this value represents null.
  bool get isNull => type == ValueType.null_;

  /// Returns true if the value is non-null and represents an integer.
  bool get isInteger {
    final result = _bindings.isInteger(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns true if the value is non-null and represents a 64-bit
  /// floating-point number.
  bool get isDouble {
    final result = _bindings.isDouble(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns a value coerced to boolean. This will be true unless the value is
  /// undefined, null, false, or zero.
  bool get asBool {
    final result = _bindings.asBool(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns a value coerced to an integer. True and false are returned as 1
  /// and 0, and floating-point numbers are rounded. All other types are
  /// returned as 0.
  int get asInt {
    final result = _bindings.asInt(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns a value coerced to a 64-bit floating point number. True and false
  /// are returned as 1.0 and 0.0, and integers are converted to float. All
  /// other types are returned as 0.0.
  double get asDouble {
    final result = _bindings.asDouble(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns the exact contents of a string value, or null for all other types.
  String? get asString {
    final result = _bindings.asString(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns the exact contents of a data value, or null for all other types.
  Uint8List? get asData {
    final result = _bindings.asData(pointer)?.toTypedList();
    cblReachabilityFence(this);
    return result;
  }

  /// If a Value represents an array, returns it as a [Array], else null.
  Array? get asArray {
    final result =
        type == ValueType.array ? Array.fromPointer(pointer.cast()) : null;
    cblReachabilityFence(this);
    return result;
  }

  /// If a Value represents a dictionary, returns it as a [Dict], else null.
  Dict? get asDict {
    final result =
        type == ValueType.dict ? Dict.fromPointer(pointer.cast()) : null;
    cblReachabilityFence(this);
    return result;
  }

  /// Returns a string representation of any scalar value. Data values are
  /// returned in raw form. Arrays and dictionaries don't have a representation
  /// and will return null.
  String? get scalarToString {
    final result = _bindings.scalarToString(pointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Encodes a Fleece value as JSON (or a JSON fragment.) Any Data values will
  /// become base64-encoded JSON strings.
  String toJson({
    bool json5 = false,
    bool canonical = true,
  }) {
    final result =
        _bindings.toJSONX(pointer, json5: json5, canonical: canonical);
    cblReachabilityFence(this);
    return result;
  }

  Object? toObject() {
    switch (type) {
      case ValueType.undefined:
        throw UnsupportedError(
          'ValueType.undefined has no equivalent Dart type',
        );
      case ValueType.null_:
        return null;
      case ValueType.boolean:
        return asBool;
      case ValueType.number:
        return isInteger ? asInt : asDouble;
      case ValueType.string:
        return asString;
      case ValueType.array:
        return asArray!.toObject();
      case ValueType.dict:
        return asDict!.toObject();
      case ValueType.data:
        return asData;
    }
  }

  @override
  bool operator ==(Object other) {
    final result = identical(this, other) ||
        other is Value && _bindings.isEqual(pointer, other.pointer);
    cblReachabilityFence(this);
    cblReachabilityFence(other);
    return result;
  }

  @override
  int get hashCode {
    switch (type) {
      case ValueType.undefined:
      case ValueType.null_:
        return 0;
      case ValueType.boolean:
        return asBool.hashCode;
      case ValueType.number:
        return asInt.hashCode;
      case ValueType.string:
        return asString.hashCode;
      case ValueType.data:
        return asData.hashCode;
      case ValueType.array:
        return asArray.hashCode;
      case ValueType.dict:
        return asDict.hashCode;
    }
  }

  @override
  String toString() {
    switch (type) {
      case ValueType.undefined:
        return 'undefined';
      case ValueType.null_:
      case ValueType.boolean:
      case ValueType.number:
        return scalarToString!;
      case ValueType.string:
        return '"${asString!}"';
      case ValueType.array:
        return asArray.toString();
      case ValueType.dict:
        return asDict.toString();
      case ValueType.data:
        return '<DATA>';
    }
  }
}

// === Array ===================================================================

/// A Fleece array.
class Array extends Value with ListMixin<Value> {
  /// Creates an [Array] based on a [pointer] to the the native value.
  Array.fromPointer(
    Pointer<FLArray> pointer, {
    bool isRefCounted = true,
    bool adopt = false,
  }) : super.fromPointer(
          pointer.cast(),
          isRefCounted: isRefCounted,
          adopt: adopt,
        );

  static late final _bindings = cblBindings.fleece.array;

  @override
  int get length {
    final result = _bindings.count(pointer.cast());
    cblReachabilityFence(this);
    return result;
  }

  @override
  set length(int length) => throw _immutableValueException();

  @override
  bool get isEmpty {
    final result = _bindings.isEmpty(pointer.cast());
    cblReachabilityFence(this);
    return result;
  }

  @override
  Value get first => this[0];

  @override
  Value get last => this[length - 1];

  /// If the array is mutable, returns it cast to [MutableArray], else null.
  MutableArray? get asMutable {
    final mutableArrayPointer = _bindings.asMutable(pointer.cast());
    final result = mutableArrayPointer?.let(MutableArray.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  @override
  List<Object?> toObject() => map((element) => element.toObject()).toList();

  @override
  Value operator [](int index) {
    final result = Value.fromPointer(
      _bindings.get(pointer.cast(), index),
      isRefCounted: false,
    );
    cblReachabilityFence(this);
    return result;
  }

  @override
  void operator []=(int index, Object? value) =>
      throw _immutableValueException();

  @override
  // ignore: hash_and_equals
  int get hashCode => fold(0, (hashCode, value) => hashCode ^ value.hashCode);
}

class MutableArray extends Array {
  /// Creates a new empty [MutableArray].
  factory MutableArray([Iterable<Object?>? from]) {
    final result = MutableArray.fromPointer(
      _bindings.create(),
      adopt: true,
    );

    if (from != null) {
      result.addAll(from);
    }

    return result;
  }

  /// Creates a [MutableArray] based on a [pointer] to the the native value.
  MutableArray.fromPointer(
    Pointer<FLMutableArray> pointer, {
    bool adopt = false,
  }) : super.fromPointer(pointer.cast(), isRefCounted: true, adopt: adopt);

  /// Creates a new [MutableArray] that's a copy of the source [Array].
  ///
  /// Copying an immutable Array is very cheap (only one small allocation)
  /// unless the [CopyFlag.copyImmutables] is set.
  ///
  /// Copying a mutable Array is cheap if it's a shallow copy, but if
  /// [CopyFlag.deepCopy] is true, nested mutable Arrays and [Dict]s are also
  /// copied, recursively; if [CopyFlag.copyImmutables] is also set, immutable
  /// values are also copied.
  factory MutableArray.mutableCopy(
    Array source, {
    Set<CopyFlag> flags = const {},
  }) {
    final result = MutableArray.fromPointer(
      _bindings.mutableCopy(source.pointer.cast(), flags.toFLCopyFlags()),
      adopt: true,
    );
    cblReachabilityFence(source);
    return result;
  }

  static late final _bindings = cblBindings.fleece.mutableArray;

  /// If the Array was created by [MutableArray.mutableCopy], returns the
  /// original source Array.
  Array? get source {
    final sourcePointer = _bindings.getSource(pointer.cast());
    final result = sourcePointer?.let(Array.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns true if the [Array] has been changed from the source it was copied
  /// from.
  bool get isChanged {
    final result = _bindings.isChanged(pointer.cast());
    cblReachabilityFence(this);
    return result;
  }

  @override
  set length(int length) {
    _bindings.resize(pointer.cast(), length);
    cblReachabilityFence(this);
  }

  @override
  set first(Object? value) {
    this[0] = value;
  }

  @override
  set last(Object? value) {
    this[length - 1] = value;
  }

  @override
  void operator []=(int index, Object? value) {
    RangeError.checkValidIndex(index, this);
    final slot = _bindings.set(pointer.cast(), index);
    _setSlotValue(slot, value);
    cblReachabilityFence(this);
  }

  @override
  void add(Object? element) {
    final slot = _bindings.append(pointer.cast());
    _setSlotValue(slot, element);
    cblReachabilityFence(this);
  }

  @override
  void addAll(Iterable<Object?> iterable) {
    var i = length;
    for (final element in iterable) {
      assert(length == i || (throw ConcurrentModificationError(this)));
      add(element);
      i++;
    }
  }

  @override
  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    _bindings.remove(pointer.cast(), start, end - start);
    cblReachabilityFence(this);
  }

  /// Inserts a contiguous range of JSON `null` values into the array.
  ///
  /// [start] is the zero-based index of the first value to be inserted.
  /// [count] is the number of items to insert.
  void insertNulls(int start, int count) {
    RangeError.checkValidIndex(start, this, 'start');
    _bindings.insert(pointer.cast(), start, count);
    cblReachabilityFence(this);
  }

  /// Convenience function for getting an dict-valued property in mutable form.
  ///
  /// - If the value for the [index] is not a dict, returns null.
  /// - If the value is a mutable dict, returns it.
  /// - If the value is an immutable dict, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableDict? mutableDict(int index) {
    final mutableDictPointer = _bindings.getMutableDict(pointer.cast(), index);
    final result = mutableDictPointer?.let(MutableDict.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Convenience function for getting a array-valued property in mutable form.
  ///
  /// - If the value for the [index] is not an array, returns null.
  /// - If the value is a mutable array, returns it.
  /// - If the value is an immutable array, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableArray? mutableArray(int index) {
    final mutableArrayPointer =
        _bindings.getMutableArray(pointer.cast(), index);
    final result = mutableArrayPointer?.let(MutableArray.fromPointer);
    cblReachabilityFence(this);
    return result;
  }
}

// === Dict ====================================================================

/// A Fleece dictionary.
class Dict extends Value with MapMixin<String, Value> {
  /// Creates a [Dict] based on a [pointer] to the the native value.
  Dict.fromPointer(
    Pointer<FLDict> pointer, {
    bool isRefCounted = true,
    bool adopt = false,
  }) : super.fromPointer(
          pointer.cast(),
          isRefCounted: isRefCounted,
          adopt: adopt,
        );

  static late final _bindings = cblBindings.fleece.dict;

  /// Returns the number of items in a dictionary.
  @override
  int get length {
    final result = _bindings.count(pointer.cast());
    cblReachabilityFence(this);
    return result;
  }

  /// Returns true if a dictionary is empty. Depending on the dictionary's
  /// representation, this can be faster than `count == 0`.
  @override
  bool get isEmpty {
    final result = _bindings.isEmpty(pointer.cast());
    cblReachabilityFence(this);
    return result;
  }

  @override
  bool get isNotEmpty => !isEmpty;

  /// If the dictionary is mutable, returns it cast to [MutableDict], else null.
  MutableDict? get asMutable {
    final mutablePointer = _bindings.asMutable(pointer.cast());
    final result = mutablePointer?.let(MutableDict.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  @override
  late final Iterable<String> keys = _DictKeyIterable(this);

  @override
  Value operator [](Object? key) {
    final result = Value.fromPointer(
      _bindings.get(pointer.cast(), assertKey(key)) ?? nullptr,
      isRefCounted: false,
    );
    cblReachabilityFence(this);
    return result;
  }

  @override
  void operator []=(String key, Object? value) =>
      throw _immutableValueException();

  @override
  void clear() => throw _immutableValueException();

  @override
  Value? remove(Object? key) => throw _immutableValueException();

  @override
  // ignore: hash_and_equals
  int get hashCode => entries.fold(
      0,
      (hashCode, entry) =>
          hashCode ^ entry.key.hashCode ^ entry.value.hashCode);

  @override
  Map<String, Object?> toObject() =>
      Map.fromEntries(entries.map((e) => MapEntry(e.key, e.value.toObject())));
}

/// Iterable which iterates over the keys of a [Dict].
class _DictKeyIterable extends Iterable<String> {
  _DictKeyIterable(this.dict);

  final Dict dict;

  @override
  Iterator<String> get iterator => _DictKeyIterator(dict);
}

/// Iterator which iterates over the keys of a [Dict].
class _DictKeyIterator extends Iterator<String> {
  _DictKeyIterator(this.dict);

  final Dict dict;

  late final DictIterator iterator = () {
    final result =
        DictIterator(dict.pointer.cast(), keyOut: globalLoadedDictKey);
    cblReachabilityFence(dict);
    return result;
  }();

  @override
  late String current;

  @override
  bool moveNext() {
    if (iterator.moveNext()) {
      final key = globalLoadedDictKey.ref;
      current = decodeFLString(key.stringBuf, key.stringSize);
      return true;
    } else {
      return false;
    }
  }
}

/// A mutable Fleece [Dict].
class MutableDict extends Dict {
  /// Creates a new empty [MutableDict].
  factory MutableDict([Map<String, Object?>? from]) {
    final result = MutableDict.fromPointer(
      _bindings.create(),
      adopt: true,
    );

    if (from != null) {
      result.addAll(from);
    }

    return result;
  }

  /// Creates a [MutableDict] based on a [pointer] to the the native value.
  MutableDict.fromPointer(
    Pointer<FLMutableDict> pointer, {
    bool isRefCounted = true,
    bool adopt = false,
  }) : super.fromPointer(
          pointer.cast(),
          isRefCounted: isRefCounted,
          adopt: adopt,
        );

  /// Creates a new [MutableDict] that's a copy of the source [Dict].
  ///
  /// Copying an immutable [Dict] is very cheap (only one small allocation.) The
  /// [CopyFlag.deepCopy] is ignored.
  ///
  /// Copying a [MutableDict] is cheap if it's a shallow copy, but if [flags]
  /// contains [CopyFlag.deepCopy], nested mutable Dicts and [Array]s are also
  /// copied, recursively.
  factory MutableDict.mutableCopy(
    Dict source, {
    Set<CopyFlag> flags = const {},
  }) {
    final result = MutableDict.fromPointer(
      _bindings.mutableCopy(source.pointer.cast(), flags.toFLCopyFlags()),
      adopt: true,
    );
    cblReachabilityFence(source);
    return result;
  }

  static late final _bindings = cblBindings.fleece.mutableDict;

  /// If the Dict was created by [MutableDict.mutableCopy], returns the original
  /// source Dict.
  Dict? get source {
    final sourcePointer = _bindings.getSource(pointer.cast());
    final result = sourcePointer?.let(Dict.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Returns true if the Dict has been changed from the source it was copied
  /// from.
  bool get isChanged {
    final result = _bindings.isChanged(pointer.cast());
    cblReachabilityFence(this);
    return result;
  }

  @override
  void operator []=(String key, Object? value) {
    _setSlotValue(_bindings.set(pointer.cast(), key), value);
    cblReachabilityFence(this);
  }

  @override
  void addAll(Map<String, Object?> other) {
    for (final key in other.keys) {
      this[key] = other[key];
    }
  }

  @override
  void clear() {
    _bindings.removeAll(pointer.cast());
    cblReachabilityFence(this);
  }

  @override
  Value? remove(Object? key) {
    final _key = assertKey(key);

    final value = this[_key];

    _bindings.remove(pointer.cast(), _key);
    cblReachabilityFence(this);

    return value;
  }

  /// Convenience function for getting an dict-valued property in mutable form.
  ///
  /// - If the value for the key is not an dict, returns null.
  /// - If the value is a mutable dict, returns it.
  /// - If the value is an immutable dict, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableDict? mutableDict(String key) {
    final mutableDictPointer = _bindings.getMutableDict(pointer.cast(), key);
    final result = mutableDictPointer?.let(MutableDict.fromPointer);
    cblReachabilityFence(this);
    return result;
  }

  /// Convenience function for getting a array-valued property in mutable form.
  ///
  /// - If the value for the key is not a array, returns null.
  /// - If the value is a mutable array, returns it.
  /// - If the value is an immutable array, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableArray? mutableArray(String key) {
    final mutableArrayPointer = _bindings.getMutableArray(pointer.cast(), key);
    final result = mutableArrayPointer?.let(MutableArray.fromPointer);
    cblReachabilityFence(this);
    return result;
  }
}

// === SlotSetter ==============================================================

abstract class SlotSetter {
  static final _instances = <SlotSetter>[_DefaultSlotSetter()];

  static void register(SlotSetter setter) {
    if (!_instances.contains(setter)) {
      _instances.add(setter);
    }
  }

  static SlotSetter _findForValue(Object? value) {
    final setter = _instances.firstWhereOrNull((it) => it.canSetValue(value));

    if (setter == null) {
      throw ArgumentError.value(
        value,
        'value',
        'value is not compatible with Fleece',
      );
    }

    return setter;
  }

  bool canSetValue(Object? value);

  void setSlotValue(Pointer<FLSlot> slot, Object? value);
}

class _DefaultSlotSetter implements SlotSetter {
  late final _slotBindings = cblBindings.fleece.slot;

  @override
  bool canSetValue(Object? value) =>
      value == null ||
      value is bool ||
      value is int ||
      value is double ||
      value is String ||
      value is Uint8List ||
      value is Iterable<Object?> ||
      value is Map<String, Object?> ||
      value is Value;

  @override
  void setSlotValue(Pointer<FLSlot> slot, Object? value) {
    // ignore: parameter_assignments
    value = _recursivelyConvertCollectionsToFleece(value);

    if (value == null) {
      _slotBindings.setNull(slot);
    } else if (value is bool) {
      _slotBindings.setBool(slot, value);
    } else if (value is int) {
      _slotBindings.setInt(slot, value);
    } else if (value is double) {
      _slotBindings.setDouble(slot, value);
    } else if (value is String) {
      _slotBindings.setString(slot, value);
    } else if (value is Uint8List) {
      _slotBindings.setData(slot, value.toData());
    } else if (value is Value) {
      _slotBindings.setValue(slot, value.pointer);
      cblReachabilityFence(value);
    }
  }

  static Object? _recursivelyConvertCollectionsToFleece(Object? value) {
    // These collection types can be set directly though the `set...` methods of
    // FLSLot.
    if (value is Value || value is Uint8List) {
      return value;
    }

    if (value is Map) {
      return MutableDict()..addAll(value.cast());
    } else if (value is Iterable) {
      return MutableArray()..addAll(value);
    } else {
      // value is a primitive.
      return value;
    }
  }
}

void _setSlotValue(Pointer<FLSlot> slot, Object? value) {
  SlotSetter._findForValue(value).setSlotValue(slot, value);
}

// === Misc ====================================================================

Error _immutableValueException() =>
    UnsupportedError('You cannot mutate an immutable Value.');
