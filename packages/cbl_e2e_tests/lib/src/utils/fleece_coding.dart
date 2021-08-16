import 'package:cbl/src/fleece/fleece.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

// === Fleece De/Encoding Utils ================================================

final fleeceEncoder = FleeceEncoder();

Data fleeceEncodeJson(String json) => fleeceEncoder.convertJson(json);

Data fleeceEncode(Object? value) {
  fleeceEncoder
    ..reset()
    ..writeDartObject(value);
  return fleeceEncoder.finish();
}

Object? fleeceDecode(Data data) => FleeceDecoder().dataToDartObject(data);
