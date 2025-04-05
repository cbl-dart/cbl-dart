import 'dart:convert';

import 'package:benchmark/utils.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/fleece/containers.dart' as fl;
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/dict_key.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/context.dart';
import 'package:cbl/src/fleece/integration/root.dart';

abstract class DecodingBenchmark extends BenchmarkBase {
  DecodingBenchmark(super.description);

  final jsonString = loadFixtureAsString('1000people');
}

class JsonDartDecodingBenchmark extends DecodingBenchmark {
  JsonDartDecodingBenchmark() : super('json_dart');

  late final utf8String = utf8.encode(jsonString);

  @override
  void run() {
    utf8.decoder.fuse(json.decoder).convert(utf8String);
  }
}

class FleeceRecursiveDecodingBenchmark extends DecodingBenchmark {
  FleeceRecursiveDecodingBenchmark() : super('fleece_recursive');

  final sharedKeys = fl.SharedKeys();
  final sharedKeysTable = SharedKeysTable();
  late final data =
      (FleeceEncoder()..setSharedKeys(sharedKeys)).convertJson(jsonString);

  @override
  void run() {
    // ignore: deprecated_member_use
    RecursiveFleeceDecoder(
      trust: FLTrust.trusted,
      sharedKeys: sharedKeys,
      sharedKeysTable: sharedKeysTable,
    ).convert(data);
  }
}

class FleeceListenerDecodingBenchmark extends DecodingBenchmark {
  FleeceListenerDecodingBenchmark() : super('fleece_listener');

  final sharedKeys = fl.SharedKeys();
  final sharedKeysTable = SharedKeysTable();
  late final data =
      (FleeceEncoder()..setSharedKeys(sharedKeys)).convertJson(jsonString);

  @override
  void run() {
    FleeceDecoder(
      trust: FLTrust.trusted,
      sharedKeys: sharedKeys,
      sharedKeysTable: sharedKeysTable,
    ).convert(data);
  }
}

class FleeceWrapperDecodingBenchmark extends DecodingBenchmark {
  FleeceWrapperDecodingBenchmark() : super('fleece_wrapper');

  final dictKeys = OptimizingDictKeys();
  final sharedKeys = fl.SharedKeys();
  final sharedKeysTable = SharedKeysTable();
  late final data =
      (FleeceEncoder()..setSharedKeys(sharedKeys)).convertJson(jsonString);

  @override
  void run() {
    final doc =
        fl.Doc.fromResultData(data, FLTrust.trusted, sharedKeys: sharedKeys);
    final root = MRoot.fromContext(
      MContext(
        data: doc,
        dictKeys: dictKeys,
        sharedKeysTable: sharedKeysTable,
        sharedStringsTable: SharedStringsTable(),
      ),
      isMutable: false,
    );
    (root.asNative! as Array).toPlainList();
  }
}

Future<void> main() async {
  await initCouchbaseLite();

  final benchmarks = [
    JsonDartDecodingBenchmark(),
    FleeceRecursiveDecodingBenchmark(),
    FleeceListenerDecodingBenchmark(),
    FleeceWrapperDecodingBenchmark(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
