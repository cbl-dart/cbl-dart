import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/src/fleece/encoder.dart';

import '../../test_binding_impl.dart';
import '../fixtures/large_json_doc.dart';
import '../test_binding.dart';
import '../utils/benchmark.dart';

abstract class EncodingBenchmark extends BenchmarkBase {
  EncodingBenchmark(String description) : super('Encoding: $description');

  final jsonValue = jsonDecode(largeJsonDoc) as List<Object?>;
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

Future<void> main() async {
  setupTestBinding();

  test('Encoding Benchmark', () {
    runBenchmarks([
      JsonInDartEncodingBenchmark(),
      FleeceEncodingBenchmark(),
    ]);
  });
}
