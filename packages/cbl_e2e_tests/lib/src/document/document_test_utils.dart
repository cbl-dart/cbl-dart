import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/document/dictionary.dart';
import 'package:cbl/src/fleece/containers.dart' show Doc;
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/dict_key.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/integration.dart';

MContext createTestMContext(Object data) => MContext(
  data: data,
  dictKeys: OptimizingDictKeys(),
  sharedKeysTable: SharedKeysTable(),
  sharedStringsTable: SharedStringsTable(),
);

Array immutableArray([List<Object?>? data]) {
  final array = MutableArray(data) as MutableArrayImpl;
  final encodedArray = FleeceEncoder.fleece.encodeWith(array.encodeTo);
  final root = MRoot.fromContext(
    createTestMContext(Doc.fromResultData(encodedArray, FLTrust.trusted)),
    isMutable: false,
  );
  // ignore: cast_nullable_to_non_nullable
  return root.asNative as Array;
}

Dictionary immutableDictionary([Map<String, Object?>? data]) {
  final dictionary = MutableDictionary(data) as MutableDictionaryImpl;
  final encodedDictionary = FleeceEncoder.fleece.encodeWith(
    dictionary.encodeTo,
  );
  final root = MRoot.fromContext(
    createTestMContext(Doc.fromResultData(encodedDictionary, FLTrust.trusted)),
    isMutable: false,
  );
  // ignore: cast_nullable_to_non_nullable
  return root.asNative as Dictionary;
}
