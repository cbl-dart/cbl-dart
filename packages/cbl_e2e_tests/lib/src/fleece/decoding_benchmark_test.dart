import 'dart:convert';
import 'dart:developer';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/fleece/containers.dart' as fl;
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/dict_key.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/context.dart';
import 'package:cbl/src/fleece/integration/root.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/benchmark.dart';

abstract class DecodingBenchmark extends BenchmarkBase {
  DecodingBenchmark(String description) : super('Decoding: $description');

  final jsonString = largeJsonFixture;
}

class JsonInDartDecodingBenchmark extends DecodingBenchmark {
  JsonInDartDecodingBenchmark() : super('JSON (in Dart)');

  late final utf8String = utf8.encode(jsonString);

  @override
  void run() {
    utf8.decoder.fuse(json.decoder).convert(utf8String);
  }
}

class FleeceRecursiveDecodingBenchmark extends DecodingBenchmark {
  FleeceRecursiveDecodingBenchmark() : super('Fleece (recursive)');

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
  FleeceListenerDecodingBenchmark() : super('Fleece (listener)');

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
  FleeceWrapperDecodingBenchmark() : super('Fleece (wrapper)');

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
  setupTestBinding();

  void run() {
    runBenchmarks([
      JsonInDartDecodingBenchmark(),
      FleeceRecursiveDecodingBenchmark(),
      FleeceListenerDecodingBenchmark(),
      FleeceWrapperDecodingBenchmark(),
    ]);
  }

  // ignore: unused_element
  void profile() {
    debugger();
    runBenchmarks([
      JsonInDartDecodingBenchmark(),
      FleeceRecursiveDecodingBenchmark(),
      FleeceListenerDecodingBenchmark(),
      FleeceWrapperDecodingBenchmark(),
    ]);
    debugger();
  }

  test('Decoding Benchmark', run);
}
