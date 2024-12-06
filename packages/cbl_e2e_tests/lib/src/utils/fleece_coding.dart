import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/encoder.dart';

// === Fleece De/Encoding Utils ================================================

final fleeceEncoder = FleeceEncoder();

Data fleeceEncodeJson(String json) => fleeceEncoder.convertJson(json);

Data fleeceEncode(Object? value) {
  fleeceEncoder
    ..reset()
    ..writeDartObject(value);
  return fleeceEncoder.finish();
}

Object? fleeceDecode(Data data) => testFleeceDecoder().convert(data);

FleeceDecoder testFleeceDecoder({FLTrust trust = FLTrust.untrusted}) =>
    FleeceDecoder(trust: trust);
