// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:benchmark/utils.dart';

void main() async {
  final benchmarks = [
    for (final mode in ExecutionMode.values)
      for (final api in ApiType.values)
        for (final batchSize in [1, 10, 100])
          Benchmark(
            executionMode: mode,
            apiType: api,
            database: 'cbl',
            operation: 'insert',
            fixture: 'users',
            operationCount: 1000,
            batchSize: batchSize,
          ),
  ];

  final results = BenchmarkResults(results: {
    for (final benchmark in benchmarks)
      benchmark.benchmarkName: await benchmark.run(),
  });

  File('results.json').writeAsStringSync(jsonEncodePretty(results.toJson()));
}

class Benchmark {
  Benchmark({
    required this.executionMode,
    required this.apiType,
    required this.database,
    required this.operation,
    required this.fixture,
    required this.operationCount,
    required this.batchSize,
  });

  final ExecutionMode executionMode;
  final ApiType apiType;
  final String database;
  final String operation;
  final String fixture;
  final int operationCount;
  final int batchSize;

  String get benchmarkName => [
        executionMode.name,
        apiType.name,
        database,
        operation,
        fixture,
        '$operationCount/$batchSize',
      ].join('_');

  Future<BenchmarkResult> run() async {
    final dartDefines = <String, String>{
      'OPERATION_COUNT': operationCount.toString(),
      'BATCH_SIZE': batchSize.toString(),
      'FIXTURE': fixture,
      'API': apiType.name,
      'EXECUTION_MODE': executionMode.name,
    };

    final dartDefineOptions = dartDefines.entries
        .map((entry) => '--define=${entry.key}=${entry.value}');

    if (executionMode == ExecutionMode.aot) {
      print('Compiling $benchmarkName ...');

      final compileResult = await Process.run(
        'dart',
        [
          'compile',
          'exe',
          'benchmark/${database}_$operation.dart',
          ...dartDefineOptions,
        ],
      );

      if (compileResult.exitCode != 0) {
        throw Exception(
          'Failed to compile executable: ${compileResult.stderr}',
        );
      }
    }

    print('Running $benchmarkName ...');

    final runResult = switch (executionMode) {
      ExecutionMode.jit => await Process.run(
          'dart',
          [
            ...dartDefineOptions,
            'run',
            'benchmark/${database}_$operation.dart',
          ],
        ),
      ExecutionMode.aot =>
        await Process.run('benchmark/${database}_$operation.exe', []),
    };

    if (runResult.exitCode != 0) {
      throw Exception('Failed to run benchmark: ${runResult.stderr}');
    }

    final benchmarkResultJson =
        jsonDecode(runResult.stdout as String) as Map<String, Object?>;
    final benchmarkResult = BenchmarkResult.fromJson(benchmarkResultJson);

    print('Completed $benchmarkName');
    print(jsonEncodePretty(benchmarkResult.toJson()));

    return benchmarkResult;
  }
}
