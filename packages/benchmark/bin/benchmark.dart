// ignore_for_file: avoid_print

import 'dart:io';

import 'package:benchmark/parameter.dart';
import 'package:benchmark/result.dart';
import 'package:benchmark/runner.dart';
import 'package:benchmark/utils.dart';

void main() async {
  final benchmarks = [
    // Micro benchmarks
    for (final file in ['document', 'data_encoding', 'data_decoding'])
      for (final mode in ExecutionMode.values)
        MicroBenchmarkRunner(executionMode: mode, file: file),

    // Database benchmarks
    for (final mode in ExecutionMode.values)
      for (final api in ApiType.values)
        for (final batchSize in [1, 10, 100])
          DatabaseBenchmarkRunner(
            executionMode: mode,
            apiType: api,
            database: 'cbl',
            operation: 'insert',
            fixture: 'users',
            operationCount: 1000,
            batchSize: batchSize,
          ),
  ];

  var results = BenchmarkResults();
  for (final benchmark in benchmarks) {
    results = results.merge(await benchmark.run());
  }

  File('results.json').writeAsStringSync(jsonEncodePretty(results.toJson()));
}
