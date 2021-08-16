import 'dart:typed_data';

import 'package:cbl/src/fleece/fleece.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

// === Fleece De/Encoding Utils ================================================

final fleeceEncoder = FleeceEncoder();

SliceResult fleeceEncodeJson(String json) => fleeceEncoder.convertJson(json);

SliceResult fleeceEncode(Object? value) {
  fleeceEncoder
    ..reset()
    ..writeDartObject(value);
  return fleeceEncoder.finish();
}

Object? fleeceDecode(Uint8List data) => FleeceDecoder().dataToDartObject(data);
