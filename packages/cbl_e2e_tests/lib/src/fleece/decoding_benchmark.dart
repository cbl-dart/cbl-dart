import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl_ffi/cbl_ffi.dart';

import '../../test_binding_impl.dart';
import '../fixtures/large_json_doc.dart';
import '../test_binding.dart';
import '../utils/benchmark.dart';

abstract class DecodingBenchmark extends BenchmarkBase {
  DecodingBenchmark(String description) : super('Decoding: $description');

  late final jsonString = largeJsonDoc;
}

class JsonInDartDecodingBenchmark extends DecodingBenchmark {
  JsonInDartDecodingBenchmark() : super('JSON (in Dart)');

  late JsonDecoder _decoder;

  @override
  void setup() {
    _decoder = const JsonDecoder();
  }

  @override
  void run() {
    _decoder.convert(jsonString);
  }
}

class FleeceDecodingBenchmark extends DecodingBenchmark {
  FleeceDecodingBenchmark() : super('Fleece');

  late FleeceDecoder _decoder;

  late final data = FleeceEncoder().convertJson(jsonString);

  @override
  void setup() {
    _decoder = FleeceDecoder();
  }

  @override
  void run() {
    final value = _decoder.loadValueFromData(data, trust: FLTrust.trusted)!;
    _decoder.loadedValueToDartObject(value);
  }
}

Future<void> main() async {
  setupTestBinding();

  test('Decoding Benchmark', () {
    runBenchmarks([
      JsonInDartDecodingBenchmark(),
      FleeceDecodingBenchmark(),
    ]);
  });
}
