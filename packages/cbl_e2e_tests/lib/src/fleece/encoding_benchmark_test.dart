import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/fleece/dict_key.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/integration.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/benchmark.dart';

abstract class EncodingBenchmark extends BenchmarkBase {
  EncodingBenchmark(String description) : super('Encoding: $description');

  final jsonValue = jsonDecode(largeJsonFixture) as List<Object?>;
}

class JsonInDartEncodingBenchmark extends EncodingBenchmark {
  JsonInDartEncodingBenchmark() : super('JSON (in Dart)');

  @override
  void run() {
    JsonUtf8Encoder().convert(jsonValue);
  }
}

class FleeceEncodingBenchmark extends EncodingBenchmark {
  FleeceEncodingBenchmark() : super('Fleece');

  @override
  void run() {
    (FleeceEncoder()..writeDartObject(jsonValue)).finish();
  }
}

class FleeceWrapperEncodingBenchmark extends EncodingBenchmark {
  FleeceWrapperEncodingBenchmark() : super('Fleece (wrapper)');

  final dictKeys = OptimizingDictKeys();
  late final context = MContext(
    dictKeys: dictKeys,
  );
  late final array = MutableArray(jsonValue);

  @override
  void run() {
    final root = MRoot.fromNative(
      array,
      context: context,
      isMutable: true,
    );
    final encoder = FleeceEncoder();
    root.encodeTo(encoder);
    encoder.finish();
  }
}

Future<void> main() async {
  setupTestBinding();

  test('Encoding Benchmark', () {
    runBenchmarks([
      JsonInDartEncodingBenchmark(),
      FleeceEncodingBenchmark(),
      FleeceWrapperEncodingBenchmark(),
    ]);
  });
}
