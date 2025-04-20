// ignore_for_file: avoid_print

import 'dart:io';

import 'package:benchmark/parameter.dart';
import 'package:benchmark/result.dart';
import 'package:benchmark/runner.dart';
import 'package:benchmark/utils.dart';
import 'package:pool/pool.dart';

void main() async {
  final benchmarks = [
    // Micro benchmarks
    for (final benchmark in ['document', 'data_encoding', 'data_decoding'])
      for (final mode in ExecutionMode.values)
        MicroBenchmarkRunner(executionMode: mode, benchmark: benchmark),

    // Database benchmarks
    for (final mode in ExecutionMode.values)
      for (final api in ApiType.values)
        for (final operationCount in [1000, 10000])
          for (final batchSize in [1, 10, 100, 1000])
            DatabaseBenchmarkRunner(
              executionMode: mode,
              apiType: api,
              database: 'cbl',
              operation: 'insert',
              fixture: 'users',
              operationCount: operationCount,
              batchSize: batchSize,
            ),
  ];

  await Pool(Platform.numberOfProcessors)
      .forEach(benchmarks, (benchmark) => benchmark.setupAllRuns())
      .drain<void>();

  const runs = 3;

  final runResults = <BenchmarkResults>[];

  for (var i = 0; i < runs; i++) {
    print('Run ${i + 1} of $runs ...');

    var results = BenchmarkResults();
    for (final benchmark in benchmarks) {
      results = results.merge(await benchmark.run());
    }
    runResults.add(results);
  }

  final results = BenchmarkResults.combine(runResults, statistic: average);

  File('results.json').writeAsStringSync(jsonEncodePretty(results.toJson()));
}
