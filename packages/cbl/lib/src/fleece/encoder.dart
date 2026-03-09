import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import '../bindings.dart';
import 'containers.dart';

/// An encoder, which generates encoded Fleece or JSON data.
///
/// It's sort of a structured output stream, with nesting. There are functions
/// for writing every type of scalar value, and for beginning and ending
/// collections. To write a collection you begin it, write its values, then end
/// it. (Of course a value in a collection can itself be another collection.)
/// When writing a dictionary, you have to call writeKey before writing each
/// value.
final class FleeceEncoder implements Finalizable {
  /// Creates an encoder, which generates encoded Fleece or JSON data.
  FleeceEncoder({
    this.format = FLEncoderFormat.fleece,
    this.reserveSize = 256,
    this.uniqueStrings = true,
  }) : _pointer = FleeceEncoderBindings.create(
         format: format,
         reserveSize: reserveSize,
         uniqueStrings: uniqueStrings,
       ) {
    FleeceEncoderBindings.bindToDartObject(this, _pointer);
  }

  static final fleece = FleeceEncoder(format: FLEncoderFormat.fleece);
  static final json = FleeceEncoder(format: FLEncoderFormat.json);

  final FLEncoder _pointer;

  var _hasSharedKeys = false;

  /// The output format to generate.
  ///
  /// The default is [FLEncoderFormat.fleece]
  final FLEncoderFormat format;

  /// The number of bytes to preallocate for the output.
  ///
  /// The default is 256.
  final int reserveSize;

  /// If true, string values that appear multiple times will be written as a
  /// single shared value. (Fleece only)
  ///
  /// This saves space but makes encoding slightly slower. You should only turn
  /// this off if you know you're going to be writing large numbers of
  /// non-repeated strings.
  ///
  /// The default is `true`.
  final bool uniqueStrings;

  /// Tells the encoder to use a shared-keys mapping when encoding dictionary
  /// keys.
  void setSharedKeys(SharedKeys? sharedKeys) {
    FleeceEncoderBindings.setSharedKeys(
      _pointer,
      sharedKeys?.pointer ?? nullptr,
    );
    _hasSharedKeys = sharedKeys != null;
  }

  /// Arbitrary information which needs to be available to code that is using
  /// this encoder.
  ///
  /// This is useful, for example, if an encoder is passed through an object
  /// hierarchies to let objects encode them self.
  Object? extraInfo;

  /// Calls the given function with this encoder as the argument and returns the
  /// result.
  ///
  /// Before calling [encode], the encoder is [reset], [extraInfo] is set to
  /// `null` and if the encoder has shared keys, they are removed.
  Data encodeWith(void Function(FleeceEncoder encoder) encode) {
    if (_hasSharedKeys) {
      setSharedKeys(null);
    }
    extraInfo = null;
    reset();
    encode(this);
    return finish();
  }

  /// Converts the [json] string to [format] and returns the result.
  Data convertJson(String json) => encodeWith((encoder) {
    encoder.writeJson(Data.fromTypedList(utf8.encode(json)));
  });

  /// Converts the Dart [value] to [format] and returns the result.
  Data convertDartObject(Object? value) => encodeWith((encoder) {
    encoder.writeDartObject(value);
  });

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
    } else if (value is Uint8List) {
      writeData(value.toData());
    } else if (value is Iterable) {
      final list = value.toList();
      beginArray(list.length);
      list.forEach(writeDartObject);
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

  /// Writes the value at [index] in [array] to this encoder.
  void writeArrayValue(FLArray array, int index) =>
      FleeceEncoderBindings.writeArrayValue(_pointer, array, index);

  /// Writes [value] this encoder.
  void writeValue(FLValue value) =>
      FleeceEncoderBindings.writeValue(_pointer, value);

  /// Writes `null` to this encoder.
  void writeNull() => FleeceEncoderBindings.writeNull(_pointer);

  /// Writes the [bool] [value] to this encoder.
  // ignore: avoid_positional_boolean_parameters
  void writeBool(bool value) =>
      FleeceEncoderBindings.writeBool(_pointer, value);

  /// Writes the [int] [value] to this encoder.
  void writeInt(int value) => FleeceEncoderBindings.writeInt(_pointer, value);

  /// Writes the [double] [value] to this encoder.
  void writeDouble(double value) =>
      FleeceEncoderBindings.writeDouble(_pointer, value);

  /// Writes the [String] [value] to this encoder.
  void writeString(String value) =>
      FleeceEncoderBindings.writeString(_pointer, value);

  /// Writes the [TypedData] [value] to this encoder.
  void writeData(Data value) =>
      FleeceEncoderBindings.writeData(_pointer, value);

  /// Writes the UTF-8 encoded JSON string [value] to this encoder.
  void writeJson(Data value) =>
      FleeceEncoderBindings.writeJSON(_pointer, value);

  /// Begins an array and reserves space for [reserveLength] element.
  void beginArray(int reserveLength) =>
      FleeceEncoderBindings.beginArray(_pointer, reserveLength);

  /// Ends an array.
  void endArray() => FleeceEncoderBindings.endArray(_pointer);

  /// Begins a dict and reserves space for [reserveLength] entries.
  void beginDict(int reserveLength) =>
      FleeceEncoderBindings.beginDict(_pointer, reserveLength);

  /// Writes a [key] for the next entry in a dict.
  void writeKey(String key) => FleeceEncoderBindings.writeKey(_pointer, key);

  /// Writes a [key] for the next entry in a dict, from a [FLString].
  void writeKeyFLString(FLString key) =>
      FleeceEncoderBindings.writeKeyFLString(_pointer, key);

  /// Writes a [key] for the next entry in a dict, from a [FLValue].
  void writeKeyValue(FLValue key) =>
      FleeceEncoderBindings.writeKeyValue(_pointer, key);

  /// Ends a dict.
  void endDict() => FleeceEncoderBindings.endDict(_pointer);

  /// Resets this encoder and allows it to be used again.
  void reset() => FleeceEncoderBindings.reset(_pointer);

  /// Finishes encoding and returns the result.
  ///
  /// To begin a new piece of Fleece data call [reset].
  Data finish() {
    final result = FleeceEncoderBindings.finish(_pointer);

    if (result == null) {
      throw StateError('Encoder did not encode anything.');
    }

    return result;
  }
}
