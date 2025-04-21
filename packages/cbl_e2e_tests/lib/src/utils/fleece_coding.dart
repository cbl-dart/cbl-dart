import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/encoder.dart';

// === Fleece De/Encoding Utils ================================================

Data fleeceEncodeJson(String json) => FleeceEncoder.fleece.convertJson(json);

Data fleeceEncode(Object? value) =>
    FleeceEncoder.fleece.convertDartObject(value);

Object? fleeceDecode(Data data) => testFleeceDecoder().convert(data);

FleeceDecoder testFleeceDecoder({FLTrust trust = FLTrust.untrusted}) =>
    FleeceDecoder(trust: trust);
