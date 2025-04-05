// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

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

abstract class BenchmarkRunnerBase {
  BenchmarkRunnerBase({
    required this.executionMode,
  });

  final ExecutionMode executionMode;

  String get description;

  String get file;

  Map<String, String> get dartDefines => {
        'EXECUTION_MODE': executionMode.name,
      };

  BenchmarkResults parseResults(String stdout);

  Future<BenchmarkResults> run() async {
    final dartDefineOptions = dartDefines.entries
        .map((entry) => '--define=${entry.key}=${entry.value}');

    if (executionMode == ExecutionMode.aot) {
      print('Compiling $description ...');

      final compileResult = await Process.run(
        'dart',
        [
          'compile',
          'exe',
          'benchmark/$file.dart',
          ...dartDefineOptions,
        ],
      );

      if (compileResult.exitCode != 0) {
        throw Exception(
          'Failed to compile executable: ${compileResult.stderr}',
        );
      }
    }

    print('Running $description ...');

    final runResult = switch (executionMode) {
      ExecutionMode.jit => await Process.run(
          'dart',
          [
            ...dartDefineOptions,
            'run',
            'benchmark/$file.dart',
          ],
        ),
      ExecutionMode.aot => await Process.run('benchmark/$file.exe', []),
    };

    if (runResult.exitCode != 0) {
      throw Exception('Failed to run benchmark: ${runResult.stderr}');
    }

    final benchmarkResult = parseResults(runResult.stdout as String);

    print('Completed $description');
    print(jsonEncodePretty(benchmarkResult.toJson()));

    return benchmarkResult;
  }
}

class MicroBenchmarkRunner extends BenchmarkRunnerBase {
  MicroBenchmarkRunner({
    required super.executionMode,
    required this.file,
  });

  @override
  final String file;

  @override
  String get description => 'micro benchmark: $file (${executionMode.name})';

  @override
  BenchmarkResults parseResults(String stdout) {
    // Example output:
    // Document property lookup(RunTime): 281.6364406779661 us.
    // Document toPlainMap(RunTime): 312.2689128061145 us.
    final benchmarkResultRegExp = RegExp(r'(.+)\(RunTime\): ([\d.]+) us\.');

    // Latencies by benchmark name, in nanoseconds.
    final latencies = <String, double>{};

    for (final line in stdout.trim().split('\n')) {
      final match = benchmarkResultRegExp.firstMatch(line)!;
      final name = match.group(1)!;
      latencies[name] = double.parse(match.group(2)!) * 1000;
    }

    return BenchmarkResults({
      for (final MapEntry(key: name, value: latency) in latencies.entries)
        '${executionMode.name}_${file}_$name': BenchmarkResult(
          measures: [
            Measure(name: 'latency', value: latency),
          ],
        ),
    });
  }
}

class DatabaseBenchmarkRunner extends BenchmarkRunnerBase {
  DatabaseBenchmarkRunner({
    required super.executionMode,
    required this.apiType,
    required this.database,
    required this.operation,
    required this.fixture,
    required this.operationCount,
    required this.batchSize,
  });

  final ApiType apiType;
  final String database;
  final String operation;
  final String fixture;
  final int operationCount;
  final int batchSize;

  @override
  String get file => '${database}_$operation';

  @override
  String get description => _benchmarkName;

  @override
  Map<String, String> get dartDefines => {
        ...super.dartDefines,
        'OPERATION_COUNT': operationCount.toString(),
        'BATCH_SIZE': batchSize.toString(),
        'FIXTURE': fixture,
        'API': apiType.name,
      };

  String get _benchmarkName => [
        executionMode.name,
        apiType.name,
        database,
        operation,
        fixture,
        '$operationCount/$batchSize',
      ].join('_');

  @override
  BenchmarkResults parseResults(String stdout) => BenchmarkResults({
        _benchmarkName: BenchmarkResult.fromJson(
          jsonDecode(stdout) as Map<String, Object?>,
        ),
      });
}
