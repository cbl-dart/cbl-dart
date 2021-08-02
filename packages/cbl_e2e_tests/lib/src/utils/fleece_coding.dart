import 'package:cbl/src/fleece/fleece.dart';

// === Fleece De/Encoding Utils ================================================

final fleeceEncoder = FleeceEncoder();

SliceResult fleeceEncodeJson(String json) => fleeceEncoder.convertJson(json);

SliceResult fleeceEncode(Object? value) {
  fleeceEncoder.reset();
  fleeceEncoder.writeDartObject(value);
  return fleeceEncoder.finish();
}

Object? fleeceDecode(Slice data) => FleeceDecoder().dataToDartObject(data);
