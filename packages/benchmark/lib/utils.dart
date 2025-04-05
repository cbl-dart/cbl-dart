import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cbl_dart/cbl_dart.dart';
// ignore: implementation_imports
import 'package:cbl_dart/src/acquire_libraries.dart';
import 'package:meta/meta.dart';

Future<void> initCouchbaseLite() async {
  await setupDevelopmentLibraries(
    standaloneDartE2eTestDir: '../cbl_e2e_tests_standalone_dart',
  );
  await CouchbaseLiteDart.init(edition: Edition.enterprise);
}

String jsonEncodePretty(Map<String, Object?> json) =>
    const JsonEncoder.withIndent('  ').convert(json);

String loadFixtureAsString(String name) =>
    File('fixture/$name.json').readAsStringSync();

Object? loadFixtureAsJson(String name) => jsonDecode(loadFixtureAsString(name));

enum ExecutionMode {
  jit,
  aot,
}

enum ApiType {
  sync,
  async,
}

class Measure {
  Measure({
    required this.name,
    required this.value,
    this.upperValue,
    this.lowerValue,
  });

  Measure.median({
    required this.name,
    required List<double> values,
  })  : value = _median(values),
        upperValue = values.reduce(max),
        lowerValue = values.reduce(min);

  Measure.fromJson(Map<String, Object?> json)
      : name = json['name']! as String,
        value = (json['value']! as num).toDouble(),
        upperValue = (json['upper_value'] as num?)?.toDouble(),
        lowerValue = (json['lower_value'] as num?)?.toDouble();

  final String name;
  final double value;
  final double? upperValue;
  final double? lowerValue;

  Map<String, Object?> toJson() => {
        'name': name,
        'value': value,
        if (upperValue != null) 'upper_value': upperValue,
        if (lowerValue != null) 'lower_value': lowerValue,
      };
}

double _median(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'values', 'must not be empty');
  }
  final sorted = List.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted[middle];
}

class BenchmarkResult {
  BenchmarkResult({required this.measures});

  BenchmarkResult.fromJson(Map<String, Object?> json)
      : measures = (json.entries
            .map((entry) =>
                Measure.fromJson(entry.value! as Map<String, Object?>))
            .toList());

  final List<Measure> measures;

  Map<String, Object?> toJson() => {
        for (final measure in measures) measure.name: measure.toJson(),
      };
}

class BenchmarkResults {
  BenchmarkResults([this.results = const {}]);

  BenchmarkResults.fromJson(Map<String, Object?> json)
      : results = json.map((key, value) => MapEntry(
              key,
              BenchmarkResult.fromJson(value! as Map<String, Object?>),
            ));

  final Map<String, BenchmarkResult> results;

  BenchmarkResults merge(BenchmarkResults other) => BenchmarkResults({
        ...results,
        ...other.results,
      });

  Map<String, Object?> toJson() => {
        for (final entry in results.entries) entry.key: entry.value.toJson(),
      };
}

abstract class DatabaseBenchmarkBase {
  static final _apiType =
      // ignore: do_not_use_environment
      ApiType.values.byName(const String.fromEnvironment('API'));

  static final _executionMode = ExecutionMode.values
      // ignore: do_not_use_environment
      .byName(const String.fromEnvironment('EXECUTION_MODE'));

  /// Durations of all measured operations in nanoseconds.
  final _operationDurations = <double>[];

  /// Stopwatch used to measure the total time of the benchmark.
  final _benchmarkStopwatch = Stopwatch();

  Future<void> report() async {
    await setup();

    try {
      if (_executionMode == ExecutionMode.jit) {
        // Warm up the JIT compiler.
        await _run();
      }

      _operationDurations.clear();
      _benchmarkStopwatch.reset();

      await _run();

      final throughput = _operationDurations.length /
          (_benchmarkStopwatch.elapsedMicroseconds /
              Duration.microsecondsPerSecond);

      final result = BenchmarkResult(
        measures: [
          Measure.median(name: 'latency', values: _operationDurations),
          Measure(name: 'throughput', value: throughput),
        ],
      );

      // ignore: avoid_print
      print(jsonEncodePretty(result.toJson()));
    } finally {
      await tearDown();
    }
  }

  Future<void> _run() async {
    switch (_apiType) {
      case ApiType.sync:
        runSync();
        break;
      case ApiType.async:
        await runAsync();
        break;
    }
  }

  @protected
  Future<void> setup() async {}

  @protected
  Future<void> tearDown() async {}

  @visibleForOverriding
  void runSync() => throw UnimplementedError();

  @visibleForOverriding
  Future<void> runAsync() => throw UnimplementedError();

  @protected
  void measureSyncBenchmark(void Function() fn) {
    _benchmarkStopwatch.start();
    fn();
    _benchmarkStopwatch.stop();
  }

  @protected
  Future<void> measureAsyncBenchmark(Future<void> Function() fn) async {
    _benchmarkStopwatch.start();
    await fn();
    _benchmarkStopwatch.stop();
  }

  @protected
  void measureSyncOperation(void Function() fn) {
    final stopwatch = Stopwatch()..start();
    fn();
    stopwatch.stop();
    _operationDurations.add(stopwatch.elapsedMicroseconds * 1000);
  }

  @protected
  Future<void> measureAsyncOperation(Future<void> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    await fn();
    stopwatch.stop();
    _operationDurations.add(stopwatch.elapsedMicroseconds * 1000);
  }
}
