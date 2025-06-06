// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'parameter.dart';
import 'result.dart';
import 'utils.dart';

final _dartaotruntime = File(
  Platform.executable,
).parent.uri.resolve('dartaotruntime').toFilePath();

abstract class BenchmarkRunnerBase {
  BenchmarkRunnerBase({required this.executionMode});

  static const _aotDirectory = '.dart_tool/benchmark-aot';
  static const _dartDirectory = 'benchmark';

  final ExecutionMode executionMode;

  /// Name of the benchmark.
  ///
  /// The Dart file implementing the benchmark must be named located at
  /// `benchmark/$name.dart`.
  String get benchmark;

  /// Unique identifier for the benchmark invocation.
  ///
  /// This distinguishes between invocations with different [executionMode]s and
  /// [parameters].
  String get invocationId => [
    executionMode.name,
    benchmark,
    ...parameters.map((parameter) => parameter.value),
  ].join('_');

  /// Parameters to invoke the benchmark with.
  List<DartDefine> get parameters => [];

  List<String> get _dartDefineOptions => DartDefine.commandLineOptions([
    executionModeParameter.dartDefine(executionMode),
    ...parameters,
  ]);

  String get _dartFile => '$_dartDirectory/$benchmark.dart';

  String get _aotFile {
    final fileName = invocationId.replaceAll(RegExp('[^a-zA-Z0-9]'), '_');
    return '$_aotDirectory/$fileName.aot';
  }

  BenchmarkResults parseResults(String stdout);

  Future<void> setupAllRuns() async {
    if (executionMode == ExecutionMode.aot) {
      print('Compiling $invocationId ...');

      await Directory(_aotDirectory).create(recursive: true);

      final compileResult = await Process.run('dart', [
        'compile',
        'aot-snapshot',
        _dartFile,
        ..._dartDefineOptions,
        '--output=$_aotFile',
      ]);

      if (compileResult.exitCode != 0) {
        throw Exception(
          'Failed to compile executable: ${compileResult.stderr}',
        );
      }
    }
  }

  Future<BenchmarkResults> run() async {
    print('Running $invocationId ...');

    final runResult = switch (executionMode) {
      ExecutionMode.jit => await Process.run('dart', [
        ..._dartDefineOptions,
        'run',
        _dartFile,
      ]),
      ExecutionMode.aot => await Process.run(_dartaotruntime, [_aotFile]),
    };

    if (runResult.exitCode != 0) {
      throw Exception('Failed to run benchmark: ${runResult.stderr}');
    }

    final benchmarkResult = parseResults(runResult.stdout as String);

    print('Completed $invocationId');
    print(jsonEncodePretty(benchmarkResult.toJson()));

    return benchmarkResult;
  }
}

class MicroBenchmarkRunner extends BenchmarkRunnerBase {
  MicroBenchmarkRunner({required super.executionMode, required this.benchmark});

  @override
  final String benchmark;

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
        '${invocationId}_$name': BenchmarkResult(
          measures: [Measure(name: 'latency', value: latency)],
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
  String get benchmark => '${database}_$operation';

  @override
  String get invocationId => [
    executionMode.name,
    apiType.name,
    benchmark,
    fixture,
    '$operationCount/$batchSize',
  ].join('_');

  @override
  List<DartDefine> get parameters => [
    apiTypeParameter.dartDefine(apiType),
    fixtureParameter.dartDefine(fixture),
    operationCountParameter.dartDefine(operationCount),
    batchSizeParameter.dartDefine(batchSize),
  ];

  @override
  BenchmarkResults parseResults(String stdout) => BenchmarkResults({
    invocationId: BenchmarkResult.fromJson(
      jsonDecode(stdout) as Map<String, Object?>,
    ),
  });
}
