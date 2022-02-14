import 'dart:convert';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../fleece/fleece.dart';
import 'native_object.dart';

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
        final doc = Doc.fromResultData(data, FLTrust.trusted);
        final encoder = FleeceEncoder();
        doc.root.native.call(encoder.writeValue);
        return encoder.finish();
    }
  }

  Data toJson() {
    switch (format) {
      case EncodingFormat.fleece:
        return (FleeceEncoder(format: FLEncoderFormat.json)..writeJson(data))
            .finish();
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
