import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/encoder.dart';
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

Object? fleeceDecode(Data data) => testFleeceDecoder().convert(data);

FleeceDecoder testFleeceDecoder({FLTrust trust = FLTrust.untrusted}) =>
    // TODO(blaugold): investigate why using const constructor won't compile
    // There seems to be a bug in the Dart VM that causes the following line to
    // throw an compile error when running tests and using the const
    // constructor.
    // ignore: prefer_const_constructors
    FleeceDecoder(trust: trust);
