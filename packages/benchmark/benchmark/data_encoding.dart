import 'dart:convert';

import 'package:benchmark/utils.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/fleece/dict_key.dart';
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/integration/integration.dart';

abstract class EncodingBenchmark extends BenchmarkBase {
  EncodingBenchmark(super.description);

  final jsonValue = loadFixtureAsJson('1000people')! as List<Object?>;
}

class JsonDartEncodingBenchmark extends EncodingBenchmark {
  JsonDartEncodingBenchmark() : super('json_dart');

  @override
  void run() {
    JsonUtf8Encoder().convert(jsonValue);
  }
}

class FleeceEncoderEncodingBenchmark extends EncodingBenchmark {
  FleeceEncoderEncodingBenchmark() : super('fleece_encoder');

  @override
  void run() {
    (FleeceEncoder()..writeDartObject(jsonValue)).finish();
  }
}

class FleeceWrapperEncodingBenchmark extends EncodingBenchmark {
  FleeceWrapperEncodingBenchmark() : super('fleece_wrapper');

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
  await initCouchbaseLite();

  final benchmarks = [
    JsonDartEncodingBenchmark(),
    FleeceEncoderEncodingBenchmark(),
    FleeceWrapperEncodingBenchmark(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
