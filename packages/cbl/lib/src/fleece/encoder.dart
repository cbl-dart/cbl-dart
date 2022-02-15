import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../support/ffi.dart';
import '../support/native_object.dart';

late final _encoderBinds = cblBindings.fleece.encoder;

/// An encoder, which generates encoded Fleece or JSON data.
///
/// It's sort of a structured output stream, with nesting. There are functions
/// for writing every type of scalar value, and for beginning and ending
/// collections. To write a collection you begin it, write its values, then end
/// it. (Of course a value in a collection can itself be another collection.)
/// When writing a dictionary, you have to call writeKey before writing each
/// value.
class FleeceEncoder extends FleeceEncoderObject {
  /// Creates an encoder, which generates encoded Fleece or JSON data.
  FleeceEncoder({
    this.format = FLEncoderFormat.fleece,
    this.reserveSize = 256,
    this.uniqueStrings = true,
  }) : super(_encoderBinds.create(
          format: format,
          reserveSize: reserveSize,
          uniqueStrings: uniqueStrings,
        ));

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
  Data convertJson(String json) {
    reset();
    writeJson(Data.fromTypedList(utf8.encode(json) as Uint8List));
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
  void writeArrayValue(Pointer<FLArray> array, int index) =>
      call((pointer) => _encoderBinds.writeArrayValue(pointer, array, index));

  /// Writes [value] this encoder.
  void writeValue(Pointer<FLValue> value) =>
      call((pointer) => _encoderBinds.writeValue(pointer, value));

  /// Writes `null` to this encoder.
  void writeNull() => call(_encoderBinds.writeNull);

  /// Writes the [bool] [value] to this encoder.
  // ignore: avoid_positional_boolean_parameters
  void writeBool(bool value) =>
      call((pointer) => _encoderBinds.writeBool(pointer, value));

  /// Writes the [int] [value] to this encoder.
  void writeInt(int value) =>
      call((pointer) => _encoderBinds.writeInt(pointer, value));

  /// Writes the [double] [value] to this encoder.
  void writeDouble(double value) =>
      call((pointer) => _encoderBinds.writeDouble(pointer, value));

  /// Writes the [String] [value] to this encoder.
  void writeString(String value) =>
      call((pointer) => _encoderBinds.writeString(pointer, value));

  /// Writes the [TypedData] [value] to this encoder.
  void writeData(Data value) =>
      call((pointer) => _encoderBinds.writeData(pointer, value));

  /// Writes the UTF-8 encoded JSON string [value] to this encoder.
  void writeJson(Data value) =>
      call((pointer) => _encoderBinds.writeJSON(pointer, value));

  /// Begins an array and reserves space for [reserveLength] element.
  void beginArray(int reserveLength) =>
      call((pointer) => _encoderBinds.beginArray(pointer, reserveLength));

  /// Ends an array.
  void endArray() => call(_encoderBinds.endArray);

  /// Begins a dict and reserves space for [reserveLength] entries.
  void beginDict(int reserveLength) =>
      call((pointer) => _encoderBinds.beginDict(pointer, reserveLength));

  /// Writes a [key] for the next entry in a dict.
  void writeKey(String key) =>
      call((pointer) => _encoderBinds.writeKey(pointer, key));

  /// Writes a [key] for the next entry in a dict, from a [FLString].
  void writeFLStringKey(FLString key) =>
      call((pointer) => _encoderBinds.writeFLStringKey(pointer, key));

  /// Ends a dict.
  void endDict() => call(_encoderBinds.endDict);

  /// Resets this encoder and allows it to be used again.
  void reset() => call(_encoderBinds.reset);

  /// Finishes encoding and returns the result.
  ///
  /// To begin a new piece of Fleece data call [reset].
  Data finish() {
    final result = call(_encoderBinds.finish);

    if (result == null) {
      throw StateError('Encoder did not encode anything.');
    }

    return result;
  }
}
