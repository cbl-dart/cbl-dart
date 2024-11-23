import 'dart:convert';

import '../bindings.dart';
import '../fleece/containers.dart';
import '../fleece/decoder.dart';
import '../fleece/encoder.dart';

enum EncodingFormat {
  fleece,
  json,
}

extension EncodingFormatExt on EncodingFormat {
  FLEncoderFormat toFLEncoderFormat() {
    switch (this) {
      case EncodingFormat.fleece:
        return FLEncoderFormat.fleece;
      case EncodingFormat.json:
        return FLEncoderFormat.json;
    }
  }
}

class EncodedData {
  EncodedData(this.format, this.data);

  EncodedData.fleece(this.data) : format = EncodingFormat.fleece;

  EncodedData.json(this.data) : format = EncodingFormat.json;

  static final _jsonDecoder = const Utf8Decoder().fuse(const JsonDecoder());
  static const _fleeceDecoder = FleeceDecoder(trust: FLTrust.trusted);

  final EncodingFormat format;

  final Data data;

  Data toFleece() {
    switch (format) {
      case EncodingFormat.fleece:
        return data;
      case EncodingFormat.json:
        return (FleeceEncoder()..writeJson(data)).finish();
    }
  }

  Data toJson() {
    switch (format) {
      case EncodingFormat.fleece:
        final encoder = FleeceEncoder(format: FLEncoderFormat.json);
        final doc = Doc.fromResultData(data, FLTrust.trusted);
        final root = doc.root;
        encoder.writeValue(root.pointer);
        return encoder.finish();
      case EncodingFormat.json:
        return data;
    }
  }

  Object? toPlainObject() {
    switch (format) {
      case EncodingFormat.fleece:
        return _fleeceDecoder.convert(data);
      case EncodingFormat.json:
        return _jsonDecoder.convert(data.toTypedList());
    }
  }
}
