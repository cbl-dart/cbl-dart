// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../bindings.dart';
import '../support/errors.dart';
import '../support/ffi.dart';
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
class SharedKeys implements Finalizable {
  /// Creates new empty [SharedKeys].
  SharedKeys() : this.fromPointer(_bindings.create(), adopt: true);

  /// Creates [SharedKeys] from an exiting native instance.
  SharedKeys.fromPointer(this.pointer, {bool adopt = false}) {
    _bindings.bindToDartObject(this, pointer, retain: !adopt);
  }

  static final _bindings = cblBindings.fleece.sharedKeys;

  final Pointer<FLSharedKeys> pointer;

  /// The number of keys in the mapping.
  ///
  /// This number increases whenever the mapping is changed, and never
  /// decreases.
  int get count => _bindings.count(pointer);
}

// === Doc =====================================================================

/// A [Doc] points to (and often owns) Fleece-encoded data and provides access
/// to its Fleece values.
class Doc implements Finalizable {
  /// Creates a [Doc] by reading Fleece [data] as encoded by a [FleeceEncoder].
  factory Doc.fromResultData(
    Data data,
    FLTrust trust, {
    SharedKeys? sharedKeys,
  }) {
    final docPointer =
        _bindings.fromResultData(data, trust, sharedKeys?.pointer);
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
  Doc.fromPointer(this.pointer) {
    _bindings.bindToDartObject(this, pointer);
  }

  static final _bindings = cblBindings.fleece.doc;

  final Pointer<FLDoc> pointer;

  /// Returns the data owned by the document, if any, else `null`.
  SliceResult? get allocedData => _bindings.getAllocedData(pointer);

  /// Returns the root value in the [Doc], usually an [Dict].
  Value get root => Value.fromPointer(_bindings.getRoot(pointer));

  /// Returns the [SharedKeys] used by this [Doc], as specified when it was
  /// created.
  SharedKeys? get sharedKeys =>
      _bindings.getSharedKeys(pointer)?.let(SharedKeys.fromPointer);
}

// === Value ===================================================================

/// Types of Fleece values. Basically JSON, with the addition of Data (raw
/// blob).
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
class Value implements Finalizable {
  /// Creates a [Value] based on a [pointer] to the the native value.
  ///
  /// Accessing immutable values is only allowed, while the enclosing container
  /// ([Doc], [MutableArray], [MutableDict] and other objects, holding Fleece
  /// data) has not been garbage collected.
  ///
  /// [adopt] should be `true` when an existing reference to the native object
  /// is transferred to the created [Value] or the native object has just been
  /// created and the created [Value] is the initial reference holder.
  Value.fromPointer(
    this.pointer, {
    this.isRefCounted = true,
    bool adopt = false,
  }) : assert(
          !adopt || isRefCounted,
          'only an object which is ref counted can be adopted',
        ) {
    if (isRefCounted) {
      _bindings.bindToDartObject(this, value: pointer, retain: !adopt);
    }
  }

  static final _bindings = cblBindings.fleece.value;

  final Pointer<FLValue> pointer;

  /// Whether this object updates the ref count of the native object when it is
  /// created and garbage collected.
  final bool isRefCounted;

  /// Looks up the Doc containing the Value, or null if the Value was created
  /// without a Doc.
  Doc? get doc => _bindings.findDoc(pointer)?.let(Doc.fromPointer);

  /// Returns the data type of an arbitrary Value.
  ValueType get type => _bindings.getType(pointer).toValueType();

  /// Whether this value represents an `undefined` value.
  bool get isUndefined => type == ValueType.undefined;

  /// Whether this value represents null.
  bool get isNull => type == ValueType.null_;

  /// Returns true if the value is non-null and represents an integer.
  bool get isInteger => _bindings.isInteger(pointer);

  /// Returns true if the value is non-null and represents a 64-bit
  /// floating-point number.
  bool get isDouble => _bindings.isDouble(pointer);

  /// Returns a value coerced to boolean. This will be true unless the value is
  /// undefined, null, false, or zero.
  bool get asBool => _bindings.asBool(pointer);

  /// Returns a value coerced to an integer. True and false are returned as 1
  /// and 0, and floating-point numbers are rounded. All other types are
  /// returned as 0.
  int get asInt => _bindings.asInt(pointer);

  /// Returns a value coerced to a 64-bit floating point number. True and false
  /// are returned as 1.0 and 0.0, and integers are converted to float. All
  /// other types are returned as 0.0.
  double get asDouble => _bindings.asDouble(pointer);

  /// Returns the exact contents of a string value, or null for all other types.
  String? get asString => _bindings.asString(pointer);

  /// Returns the exact contents of a data value, or null for all other types.
  Uint8List? get asData => _bindings.asData(pointer)?.toTypedList();

  /// If a Value represents an array, returns it as a [Array], else null.
  Array? get asArray =>
      type == ValueType.array ? Array.fromPointer(pointer.cast()) : null;

  /// If a Value represents a dictionary, returns it as a [Dict], else null.
  Dict? get asDict =>
      type == ValueType.dict ? Dict.fromPointer(pointer.cast()) : null;

  /// Returns a string representation of any scalar value. Data values are
  /// returned in raw form. Arrays and dictionaries don't have a representation
  /// and will return null.
  String? get scalarToString => _bindings.scalarToString(pointer);

  /// Encodes a Fleece value as JSON (or a JSON fragment.) Any Data values will
  /// become base64-encoded JSON strings.
  String toJson({bool json5 = false, bool canonical = true}) =>
      _bindings.toJSONX(pointer, json5: json5, canonical: canonical);

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Value && _bindings.isEqual(pointer, other.pointer);

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
    super.isRefCounted,
    super.adopt,
  }) : super.fromPointer(pointer.cast());

  static final _bindings = cblBindings.fleece.array;

  @override
  int get length => _bindings.count(pointer.cast());

  @override
  set length(int length) => throw _immutableValueException();

  @override
  bool get isEmpty => _bindings.isEmpty(pointer.cast());

  @override
  Value get first => this[0];

  @override
  Value get last => this[length - 1];

  /// If the array is mutable, returns it cast to [MutableArray], else null.
  MutableArray? get asMutable =>
      _bindings.asMutable(pointer.cast())?.let(MutableArray.fromPointer);

  @override
  List<Object?> toObject() => map((element) => element.toObject()).toList();

  @override
  Value operator [](int index) => Value.fromPointer(
        _bindings.get(pointer.cast(), index),
        isRefCounted: false,
      );

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
  MutableArray.fromPointer(Pointer<FLMutableArray> pointer, {super.adopt})
      : super.fromPointer(pointer.cast(), isRefCounted: true);

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
  }) =>
      MutableArray.fromPointer(
        _bindings.mutableCopy(source.pointer.cast(), flags.toFLCopyFlags()),
        adopt: true,
      );

  static final _bindings = cblBindings.fleece.mutableArray;

  /// If the Array was created by [MutableArray.mutableCopy], returns the
  /// original source Array.
  Array? get source =>
      _bindings.getSource(pointer.cast())?.let(Array.fromPointer);

  /// Returns true if the [Array] has been changed from the source it was copied
  /// from.
  bool get isChanged => _bindings.isChanged(pointer.cast());

  @override
  set length(int length) => _bindings.resize(pointer.cast(), length);

  @override
  set first(Object? value) => this[0] = value;

  @override
  set last(Object? value) => this[length - 1] = value;

  @override
  void operator []=(int index, Object? value) {
    RangeError.checkValidIndex(index, this);
    _setSlotValue(_bindings.set(pointer.cast(), index), value);
  }

  @override
  void add(Object? element) =>
      _setSlotValue(_bindings.append(pointer.cast()), element);

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
  }

  /// Inserts a contiguous range of JSON `null` values into the array.
  ///
  /// [start] is the zero-based index of the first value to be inserted. [count]
  /// is the number of items to insert.
  void insertNulls(int start, int count) {
    RangeError.checkValidIndex(start, this, 'start');
    _bindings.insert(pointer.cast(), start, count);
  }

  /// Convenience function for getting an dict-valued property in mutable form.
  ///
  /// - If the value for the [index] is not a dict, returns null.
  /// - If the value is a mutable dict, returns it.
  /// - If the value is an immutable dict, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableDict? mutableDict(int index) => _bindings
      .getMutableDict(pointer.cast(), index)
      ?.let(MutableDict.fromPointer);

  /// Convenience function for getting a array-valued property in mutable form.
  ///
  /// - If the value for the [index] is not an array, returns null.
  /// - If the value is a mutable array, returns it.
  /// - If the value is an immutable array, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableArray? mutableArray(int index) => _bindings
      .getMutableArray(pointer.cast(), index)
      ?.let(MutableArray.fromPointer);
}

// === Dict ====================================================================

/// A Fleece dictionary.
class Dict extends Value with MapMixin<String, Value> {
  /// Creates a [Dict] based on a [pointer] to the the native value.
  Dict.fromPointer(
    Pointer<FLDict> pointer, {
    super.isRefCounted,
    super.adopt,
  }) : super.fromPointer(pointer.cast());

  static final _bindings = cblBindings.fleece.dict;

  /// Returns the number of items in a dictionary.
  @override
  int get length => _bindings.count(pointer.cast());

  /// Returns true if a dictionary is empty. Depending on the dictionary's
  /// representation, this can be faster than `count == 0`.
  @override
  bool get isEmpty => _bindings.isEmpty(pointer.cast());

  @override
  bool get isNotEmpty => !isEmpty;

  /// If the dictionary is mutable, returns it cast to [MutableDict], else null.
  MutableDict? get asMutable =>
      _bindings.asMutable(pointer.cast())?.let(MutableDict.fromPointer);

  @override
  late final Iterable<String> keys = _DictKeyIterable(this);

  @override
  Value operator [](Object? key) => Value.fromPointer(
        _bindings.get(pointer.cast(), assertKey(key)) ?? nullptr,
        isRefCounted: false,
      );

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
class _DictKeyIterator implements Iterator<String> {
  _DictKeyIterator(this.dict);

  final Dict dict;

  late final DictIterator iterator =
      DictIterator(dict.pointer.cast(), keyOut: globalLoadedDictKey);

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
    super.isRefCounted,
    super.adopt,
  }) : super.fromPointer(pointer.cast());

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
  }) =>
      MutableDict.fromPointer(
        _bindings.mutableCopy(source.pointer.cast(), flags.toFLCopyFlags()),
        adopt: true,
      );

  static final _bindings = cblBindings.fleece.mutableDict;

  /// If the Dict was created by [MutableDict.mutableCopy], returns the original
  /// source Dict.
  Dict? get source =>
      _bindings.getSource(pointer.cast())?.let(Dict.fromPointer);

  /// Returns true if the Dict has been changed from the source it was copied
  /// from.
  bool get isChanged => _bindings.isChanged(pointer.cast());

  @override
  void operator []=(String key, Object? value) =>
      _setSlotValue(_bindings.set(pointer.cast(), key), value);

  @override
  void addAll(Map<String, Object?> other) {
    for (final key in other.keys) {
      this[key] = other[key];
    }
  }

  @override
  void clear() => _bindings.removeAll(pointer.cast());

  @override
  Value? remove(Object? key) {
    final stringKey = assertKey(key);

    final value = this[stringKey];

    _bindings.remove(pointer.cast(), stringKey);

    return value;
  }

  /// Convenience function for getting an dict-valued property in mutable form.
  ///
  /// - If the value for the key is not an dict, returns null.
  /// - If the value is a mutable dict, returns it.
  /// - If the value is an immutable dict, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableDict? mutableDict(String key) => _bindings
      .getMutableDict(pointer.cast(), key)
      ?.let(MutableDict.fromPointer);

  /// Convenience function for getting a array-valued property in mutable form.
  ///
  /// - If the value for the key is not a array, returns null.
  /// - If the value is a mutable array, returns it.
  /// - If the value is an immutable array, this function makes a mutable copy,
  ///   assigns the copy as the property value, and returns the copy.
  MutableArray? mutableArray(String key) => _bindings
      .getMutableArray(pointer.cast(), key)
      ?.let(MutableArray.fromPointer);
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
