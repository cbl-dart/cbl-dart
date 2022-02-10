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

  final jsonString = largeJsonDoc;
}

class JsonInDartDecodingBenchmark extends DecodingBenchmark {
  JsonInDartDecodingBenchmark() : super('JSON (in Dart)');

  final utf8String = utf8.encode(largeJsonDoc);

  @override
  void run() {
    utf8.decoder.fuse(json.decoder).convert(utf8String);
  }
}

class FleeceDecodingBenchmark extends DecodingBenchmark {
  FleeceDecodingBenchmark() : super('Fleece');

  late final data = FleeceEncoder().convertJson(jsonString);

  @override
  void run() {
    final decoder = FleeceDecoder();
    final value = decoder.loadValueFromData(data, trust: FLTrust.trusted)!;
    decoder.loadedValueToDartObject(value);
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
