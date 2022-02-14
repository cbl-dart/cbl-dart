import 'dart:convert';
import 'dart:developer';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/cbl.dart';
import 'package:cbl/src/fleece/decoder.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/context.dart';
import 'package:cbl/src/fleece/integration/root.dart';
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

  late final utf8String = utf8.encode(jsonString);

  @override
  void run() {
    utf8.decoder.fuse(json.decoder).convert(utf8String);
  }
}

class FleeceRecursiveDecodingBenchmark extends DecodingBenchmark {
  FleeceRecursiveDecodingBenchmark() : super('Fleece (recursive)');

  late final data = FleeceEncoder().convertJson(jsonString);

  @override
  void run() {
    // ignore: deprecated_member_use
    const RecursiveFleeceDecoder(trust: FLTrust.trusted).convert(data);
  }
}

class FleeceListenerDecodingBenchmark extends DecodingBenchmark {
  FleeceListenerDecodingBenchmark() : super('Fleece (listener)');

  late final data = FleeceEncoder().convertJson(jsonString);

  @override
  void run() {
    const FleeceDecoder(trust: FLTrust.trusted).convert(data);
  }
}

class FleeceWrapperDecodingBenchmark extends DecodingBenchmark {
  FleeceWrapperDecodingBenchmark() : super('Fleece (wrapper)');

  late final data = FleeceEncoder().convertJson(jsonString);

  @override
  void run() {
    final root = MRoot.fromData(data, context: MContext(), isMutable: false);
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
