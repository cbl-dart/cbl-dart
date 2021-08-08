import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../support/ffi.dart';
import 'decoder.dart';

late final _encoderBinds = cblBindings.fleece.encoder;

/// An encoder, which generates encoded Fleece or JSON data.
///
/// It's sort of a structured output stream, with nesting. There are functions
/// for writing every type of scalar value, and for beginning and ending
/// collections. To write a collection you begin it, write its values, then end
/// it. (Of course a value in a collection can itself be another collection.)
/// When writing a dictionary, you have to call writeKey before writing each
/// value.
class FleeceEncoder {
  /// Creates an encoder, which generates encoded Fleece or JSON data.
  FleeceEncoder({
    this.format = FLEncoderFormat.fleece,
    this.reserveSize = 256,
    this.uniqueStrings = true,
  }) {
    _pointer = _encoderBinds.create(this, format, reserveSize, uniqueStrings);
  }

  late final Pointer<FLEncoder> _pointer;

  /// The output format to generate.
  ///
  /// The default is [FLEncoderFormat.fleece]
  final FLEncoderFormat format;

  /// The number of bytes to preallocate for the output.
  ///
  /// The default is 256.
  final int reserveSize;

  /// If true, string values that appear multiple times will be written
  /// as a single shared value. (Fleece only)
  ///
  /// This saves space but makes encoding slightly slower.
  /// You should only turn this off if you know you're going to be writing large
  /// numbers of non-repeated strings.
  ///
  /// The default is `true`.
  final bool uniqueStrings;

  /// Arbitrary information which needs to be available to code that is using
  /// this encoder.
  ///
  /// This is useful, for example, if an encoder is passed through an object
  /// hierarchies to let objects encode them self.
  Object? extraInfo;

  /// Converts the [json] string to [format] and returns the result.
  SliceResult convertJson(String json) {
    reset();
    writeJson(json);
    return finish();
  }

  /// Writes a Dart object to this encoder.
  ///
  /// [value] must be `null` or of type [bool], [int], [double], [String],
  /// [TypedData], [Iterable] or [Map]. The values of an [Iterable] or [Map]
  /// must satisfy this requirement as well. The keys of a [Map] must be
  /// [String]s.
  void writeDartObject(Object? value) {
    if (value == null) {
      writeNull();
    } else if (value is bool) {
      writeBool(value);
    } else if (value is int) {
      writeInt(value);
    } else if (value is double) {
      writeDouble(value);
    } else if (value is String) {
      writeString(value);
    } else if (value is TypedData) {
      writeData(value);
    } else if (value is Iterable) {
      final list = value.toList();
      beginArray(list.length);
      for (final element in list) {
        writeDartObject(element);
      }
      endArray();
    } else if (value is Map) {
      beginDict(value.length);
      for (final entry in value.entries) {
        writeKey(entry.key as String);
        writeDartObject(entry.value);
      }
      endDict();
    } else {
      throw ArgumentError.value(
        value,
        'value',
        'is not of a type which can be encoded by the FleeceEncoder',
      );
    }
  }

  /// Writes a loaded [value] to this encoder.
  void writeLoadedValue(LoadedFLValue value) {
    if (value is SimpleFLValue) {
      writeDartObject(value.value);
    } else if (value is SliceFLValue) {
      writeValue(value.value);
    } else if (value is CollectionFLValue) {
      writeValue(value.value);
    } else {
      throw UnimplementedError(
        'writing of value of this type is not implemented: $value',
      );
    }
  }

  /// Writes the value at [index] in [array] to this encoder.
  void writeArrayValue(Pointer<FLArray> array, int index) =>
      _encoderBinds.writeArrayValue(_pointer, array, index);

  /// Writes [value] this encoder.
  void writeValue(Pointer<FLValue> value) =>
      _encoderBinds.writeValue(_pointer, value);

  /// Writes `null` to this encoder.
  void writeNull() => _encoderBinds.writeNull(_pointer);

  /// Writes the [bool] [value] to this encoder.
  void writeBool(bool value) => _encoderBinds.writeBool(_pointer, value);

  /// Writes the [int] [value] to this encoder.
  void writeInt(int value) => _encoderBinds.writeInt(_pointer, value);

  /// Writes the [double] [value] to this encoder.
  void writeDouble(double value) => _encoderBinds.writeDouble(_pointer, value);

  /// Writes the [String] [value] to this encoder.
  void writeString(String value) => _encoderBinds.writeString(_pointer, value);

  /// Writes the [TypedData] [value] to this encoder.
  void writeData(TypedData value) =>
      _encoderBinds.writeData(_pointer, value.buffer);

  /// Writes the JSON string [value] to this encoder.
  void writeJson(String value) => _encoderBinds.writeJSON(_pointer, value);

  /// Begins an array and reserves space for [reserveLength] element.
  void beginArray(int reserveLength) =>
      _encoderBinds.beginArray(_pointer, reserveLength);

  /// Ends an array.
  void endArray() => _encoderBinds.endArray(_pointer);

  /// Begins a dict and reserves space for [reserveLength] entries.
  void beginDict(int reserveLength) =>
      _encoderBinds.beginDict(_pointer, reserveLength);

  /// Writes a [key] for the next entry in a dict.
  void writeKey(String key) => _encoderBinds.writeKey(_pointer, key);

  /// Ends a dict.
  void endDict() => _encoderBinds.endDict(_pointer);

  /// Resets this encoder and allows it to be used again.
  void reset() => _encoderBinds.reset(_pointer);

  /// Finishes encoding and returns the result.
  ///
  /// To begin a new piece of Fleece data call [reset].
  SliceResult finish() {
    final result =
        SliceResult.fromFLSliceResult(_encoderBinds.finish(_pointer));

    if (result == null) {
      throw StateError('Encoder did not encode anything');
    }

    return result;
  }
}
