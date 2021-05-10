import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'slice.dart';

late final _decoderBinds = CBLBindings.instance.fleece.decoder;

/// A cache for strings which are encoded as unique shared strings in Fleece
/// data.
class SharedStrings {
  // These are the metrics which the Fleece encoder uses when considering
  // strings for sharing. Strings which are not shared must not be stored in
  // this cache.
  //
  // https://github.com/couchbaselabs/fleece/blob/f8923b7916e88551ee17727f56e599cae4dabe52/Fleece/Core/Internal.hh#L78-L79
  static const minSharedStringSize = 2;
  static const maxSharedStringSize = 15;

  final _addressToDartString = <int, String?>{};

  String? sliceToDartString(Slice slice) {
    if (slice.size < minSharedStringSize || slice.size > maxSharedStringSize) {
      return slice.toDartString();
    }

    return _addressToDartString[slice.buf.address] ??= slice.toDartString();
  }

  String? flSliceToDartString(FLSlice slice) {
    if (slice.size < minSharedStringSize || slice.size > maxSharedStringSize) {
      return slice.toDartString();
    }

    return _addressToDartString[slice.buf.address] ??= slice.toDartString();
  }

  bool hasString(String string) {
    return _addressToDartString.values.contains(string);
  }
}

// === LoadedFLValue ============================================================

/// A representation of an [FLValue] which can be loaded efficiently.
///
/// Subclasses represent different types of values and include data which
/// is used to efficiently read their content.
///
/// Values wich correspond to [FLValueType.undefined] are represented as `null`
/// in Dart.
abstract class LoadedFLValue {}

/// A [LoadedFLValue] for `null`, `boolean` and `number` values.
class SimpleFLValue extends LoadedFLValue {
  SimpleFLValue(this.value)
      : assert(value == null || value is bool || value is num);

  /// The Dart representation of the [FLValue].
  final Object? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleFLValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SimpleFLValue($value)';
}

/// A base class for [LoadedFLValue]s which contain a [Pointer] to the
/// loaded [FLValue].
abstract class ComplexFLValue extends LoadedFLValue {
  ComplexFLValue(this.value) : assert(value != nullptr);

  /// Pointer to the loaded [FLValue].
  final Pointer<FLValue> value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplexFLValue &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A [LoadedFLValue] for `string` and `data` values.
class SliceFLValue extends ComplexFLValue {
  SliceFLValue({
    required this.isString,
    required this.slice,
    required Pointer<FLValue> value,
  }) : super(value);

  /// Whether this value represents a `string` or `data`.
  final bool isString;

  /// The [Slice] which holds the data of this value.
  final Slice slice;

  @override
  String toString() => 'SliceFLValue('
      '${isString ? 'string' : 'data'}, '
      'length: ${slice.size}, '
      'value: $value'
      ')';
}

/// A [LoadedFLValue] for `array` and `dict` values.
class CollectionFLValue extends ComplexFLValue {
  CollectionFLValue({
    required this.isArray,
    required this.length,
    required Pointer<FLValue> value,
  })  : assert(length >= 0),
        super(value);

  /// Whether this value represents an `array` or a `dict`.
  final bool isArray;

  /// The length of the collection.
  final int length;

  @override
  String toString() => 'CollectionFLValue('
      '${isArray ? 'array' : 'dict'}, '
      'length: $length, '
      'value: $value'
      ')';
}

extension on CBLDart_LoadedFLValue {
  LoadedFLValue? toLoadedFLValue() {
    switch (type) {
      case FLValueType.undefined:
        return null;
      case FLValueType.Null:
        return SimpleFLValue(null);
      case FLValueType.boolean:
        return SimpleFLValue(asBool);
      case FLValueType.number:
        return SimpleFLValue(isInteger ? asInt : asDouble);
      case FLValueType.string:
      case FLValueType.data:
        return SliceFLValue(
          slice: Slice.fromFLSlice(asSlice)!,
          value: asValue,
          isString: type == FLValueType.string,
        );
      case FLValueType.array:
      case FLValueType.dict:
        return CollectionFLValue(
          value: asValue,
          length: collectionSize,
          isArray: type == FLValueType.array,
        );
    }
  }
}

LoadedFLValue? _globalLoadedValueObject() =>
    globalLoadedFLValue.ref.toLoadedFLValue();

// === FleeceDecoder ===========================================================

/// A decoder for efficiently reading Fleece data from Dart.
///
/// You should create a new [FleeceDecoder] with a new instance of
/// [SharedStrings] for each piece of Fleece data. Unless an instance of
/// [SharedStrings] is provided when creating a [FleeceDecoder], a new one will
/// be created.
class FleeceDecoder {
  /// Creates a decoder for efficiently reading Fleece data from Dart.
  FleeceDecoder({SharedStrings? sharedStrings})
      : sharedStrings = sharedStrings ?? SharedStrings();

  /// The [SharedStrings] this decoder is using to read strings from Fleece
  /// data.
  ///
  /// An instance of [SharedStrings] should only be used for decoding a single
  /// piece of Fleece data.
  final SharedStrings sharedStrings;

  /// Returns a string which shows how values are encoded in the Fleece [data].
  ///
  /// This method exists for debugging and learning purposes.
  String dumpData(Slice data) {
    final flSlice = _decoderBinds.dumpData(data.makeGlobal().ref);
    return SliceResult.fromFLSliceResult(flSlice)!.toDartString();
  }

  // === LoadedFLValue ==========================================================

  /// Loads the root value from [data] as a [LoadedFLValue].
  ///
  /// Specify whether you [trust] the source of the [data] to ensure it is valid
  /// Fleece data. If [data] is not valid, `null` is returned.
  LoadedFLValue? loadValueFromData(
    Slice data, {
    FLTrust trust = FLTrust.untrusted,
  }) {
    if (!_decoderBinds.getLoadedFLValueFromData(data.makeGlobal().ref, trust)) {
      return null;
    }
    return _globalLoadedValueObject();
  }

  /// Loads [value] as a [LoadedFLValue] or returns `null` if it is
  /// [FLValueType.undefined].
  LoadedFLValue? loadValue(Pointer<FLValue> value) {
    _decoderBinds.getLoadedValue(value);
    return _globalLoadedValueObject();
  }

  /// Loads the value at [index] from [array] as a [LoadedFLValue] or returns
  /// `null` if [index] is out of bounds.
  LoadedFLValue? loadValueFromArray(Pointer<FLArray> array, int index) {
    _decoderBinds.getLoadedValueFromArray(array, index);
    return _globalLoadedValueObject();
  }

  /// Loads the value for [key] from [dict] as a [LoadedFLValue] or returns
  /// `null` there is no entry for [key].
  LoadedFLValue? loadValueFromDict(Pointer<FLDict> dict, String key) {
    _decoderBinds.getLoadedValueFromDict(dict, key);
    return _globalLoadedValueObject();
  }

  // === Conversion to Dart ====================================================

  /// Returns a Dart representation of [data]. Collections are recursively
  /// converted to Dart objects.
  ///
  /// Specify whether you [trust] the source of the [data] to ensure it is valid
  /// Fleece data. If [data] is not valid, `null` is returned.
  Object? dataToDartObject(
    Slice data, {
    FLTrust trust = FLTrust.untrusted,
  }) {
    final root = loadValueFromData(data, trust: trust);
    if (root == null) {
      return null;
    }
    return loadedValueToDartObject(root);
  }

  /// Returns a Dart representation of [value]. Collections are recursively
  /// converted to Dart objects.
  Object? loadedValueToDartObject(LoadedFLValue value) {
    if (value is SimpleFLValue) {
      return value.value;
    } else if (value is SliceFLValue) {
      return value.isString
          ? sharedStrings.sliceToDartString(value.slice)!
          : Uint8List.fromList(value.slice.asBytes());
    } else if (value is CollectionFLValue) {
      if (value.isArray) {
        final array = value.value.cast<FLArray>();
        return List<dynamic>.generate(value.length, (index) {
          _decoderBinds.getLoadedValueFromArray(array, index);
          return _globalLoadedValueToDartObject();
        });
      } else {
        final result = <String, dynamic>{};
        final iterator = DictIterator(
          value.value.cast(),
          keyOut: globalFLSlice,
          valueOut: globalLoadedFLValue,
        );
        while (iterator.moveNext()) {
          final key = sharedStrings.flSliceToDartString(globalFLSlice.ref)!;
          result[key] = _globalLoadedValueToDartObject();
        }
        return result;
      }
    } else {
      throw UnimplementedError('Value of unknown type: $value');
    }
  }

  // === Dict Iterable =========================================================

  /// Returns an [Iterable] which iterates over the entries of [dict].
  Iterable<MapEntry<String, LoadedFLValue>> dictIterable(
    Pointer<FLDict> dict,
  ) =>
      DictIterable(
        dict,
        keyOut: globalFLSlice,
        valueOut: globalLoadedFLValue,
      ).map((_) => MapEntry(
            sharedStrings.flSliceToDartString(globalFLSlice.ref)!,
            _globalLoadedValueObject()!,
          ));

  /// Returns an [Iterable] which iterates over the keys of [dict].
  Iterable<String> dictKeyIterable(Pointer<FLDict> dict) =>
      DictIterable(dict, keyOut: globalFLSlice)
          .map((it) => sharedStrings.flSliceToDartString(globalFLSlice.ref)!);

  // === Impl ==================================================================

  Object? _globalLoadedValueToDartObject() {
    final value = globalLoadedFLValue.ref;
    switch (value.type) {
      case FLValueType.undefined:
        throw UnsupportedError(
          'undefined cannot be represented as Dart value',
        );
      case FLValueType.Null:
        return null;
      case FLValueType.boolean:
        return value.asBool;
      case FLValueType.number:
        return value.isInteger ? value.asInt : value.asDouble;
      case FLValueType.string:
        return sharedStrings.flSliceToDartString(value.asSlice);
      case FLValueType.data:
        return value.asSlice.toUint8List();
      case FLValueType.array:
        final array = value.asValue.cast<FLArray>();
        return List<dynamic>.generate(value.collectionSize, (index) {
          _decoderBinds.getLoadedValueFromArray(array, index);
          return _globalLoadedValueToDartObject();
        });
      case FLValueType.dict:
        final result = <String, dynamic>{};
        final iterator = DictIterator(
          value.asValue.cast(),
          keyOut: globalFLSlice,
          valueOut: globalLoadedFLValue,
        );
        while (iterator.moveNext()) {
          final key = sharedStrings.flSliceToDartString(globalFLSlice.ref)!;
          result[key] = _globalLoadedValueToDartObject();
        }
        return result;
    }
  }
}

// === DictIterable ============================================================

/// An [Iterable] wich iterates of the entries of [dict].
///
/// The iterable does not actually provide a value on each iteration. Instead
/// it loads the key and value into [keyOut] and [valueOut] respectively.
///
/// Both [keyOut] and [valueOut] are optional and their contents are only loaded
/// if a destination has been provided.
class DictIterable with IterableMixin<void> {
  DictIterable(this.dict, {this.keyOut, this.valueOut});

  final Pointer<FLDict> dict;
  final Pointer<FLSlice>? keyOut;
  final Pointer<CBLDart_LoadedFLValue>? valueOut;

  @override
  Iterator<void> get iterator =>
      DictIterator(dict, keyOut: keyOut, valueOut: valueOut);
}

/// An [Iterator] wich iterates of the entries of a [FLDict].
class DictIterator implements Iterator<void> {
  /// Creates an [Iterator] wich iterates of the entries of a [FLDict].
  ///
  /// The iterator does not actually provide a value in [current]. Instead
  /// it loads the key and value into [keyOut] and [valueOut] respectively, when
  /// [moveNext] is called.
  ///
  /// Both [keyOut] and [valueOut] are optional and their contents are only
  /// loaded if a destination has been provided.
  DictIterator(
    Pointer<FLDict> dict, {
    Pointer<FLSlice>? keyOut,
    Pointer<CBLDart_LoadedFLValue>? valueOut,
  }) {
    _iterator = _decoderBinds.dictIteratorBegin(
      this,
      dict,
      keyOut ?? nullptr,
      valueOut ?? nullptr,
    );
  }

  late final Pointer<CBLDart_FLDictIterator2> _iterator;

  @override
  void get current => null;

  @override
  bool moveNext() {
    _decoderBinds.dictIteratorNext(_iterator);
    return !_iterator.ref.isDone;
  }
}
