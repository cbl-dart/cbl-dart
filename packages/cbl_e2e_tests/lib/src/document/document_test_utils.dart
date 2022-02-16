import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/document/dictionary.dart';
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/dict_key.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/integration.dart';

MContext createTestMContext() => MContext(
      dictKeys: OptimizingDictKeys(),
      sharedKeysTable: SharedKeysTable(),
      sharedStringsTable: SharedStringsTable(),
    );

Array immutableArray([List<Object?>? data]) {
  final array = MutableArray(data) as MutableArrayImpl;
  final encoder = FleeceEncoder();
  array.encodeTo(encoder);
  final fleeceData = encoder.finish();
  final root = MRoot.fromData(
    fleeceData,
    context: createTestMContext(),
    isMutable: false,
  );
  // ignore: cast_nullable_to_non_nullable
  return root.asNative as Array;
}

Dictionary immutableDictionary([Map<String, Object?>? data]) {
  final array = MutableDictionary(data) as MutableDictionaryImpl;
  final encoder = FleeceEncoder();
  array.encodeTo(encoder);
  final fleeceData = encoder.finish();
  final root = MRoot.fromData(
    fleeceData,
    context: createTestMContext(),
    isMutable: false,
  );
  // ignore: cast_nullable_to_non_nullable
  return root.asNative as Dictionary;
}
