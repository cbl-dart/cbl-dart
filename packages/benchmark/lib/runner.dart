// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'parameter.dart';
import 'result.dart';
import 'utils.dart';

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
  List<MapEntry<String, String>> get parameters => [];

  Map<String, String> get _environment => Map.fromEntries([
    executionModeParameter.envEntry(executionMode),
    ...parameters,
  ]);

  String get _dartFile => '$_dartDirectory/$benchmark.dart';

  String get _aotBuildDir {
    final dirName = invocationId.replaceAll(RegExp('[^a-zA-Z0-9]'), '_');
    return '$_aotDirectory/$dirName';
  }

  String get _aotExecutable {
    final extension = Platform.isWindows ? '.exe' : '';
    return '$_aotBuildDir/bundle/bin/$benchmark$extension';
  }

  BenchmarkResults parseResults(String stdout);

  Future<void> setupAllRuns() async {
    if (executionMode == ExecutionMode.aot) {
      print('Compiling $invocationId ...');

      await Directory(_aotDirectory).create(recursive: true);

      final compileResult = await Process.run('dart', [
        'build',
        'cli',
        '--target=$_dartFile',
        '--output=$_aotBuildDir',
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
        'run',
        _dartFile,
      ], environment: _environment),
      ExecutionMode.aot => await Process.run(
        _aotExecutable,
        [],
        environment: _environment,
      ),
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
      final match = benchmarkResultRegExp.firstMatch(line);
      if (match == null) {
        // Skip preamble lines (e.g. "Running build hooks..." from native
        // assets).
        continue;
      }
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
  List<MapEntry<String, String>> get parameters => [
    apiTypeParameter.envEntry(apiType),
    fixtureParameter.envEntry(fixture),
    operationCountParameter.envEntry(operationCount),
    batchSizeParameter.envEntry(batchSize),
  ];

  @override
  BenchmarkResults parseResults(String stdout) {
    // Strip any output before the JSON object, such as "Running build hooks..."
    // printed by the Dart native assets system.
    final jsonStart = stdout.indexOf('{');
    if (jsonStart == -1) {
      throw FormatException('No JSON object found in benchmark output', stdout);
    }
    return BenchmarkResults({
      invocationId: BenchmarkResult.fromJson(
        jsonDecode(stdout.substring(jsonStart)) as Map<String, Object?>,
      ),
    });
  }
}
