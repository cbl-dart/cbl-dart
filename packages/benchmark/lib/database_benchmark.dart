import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:meta/meta.dart';

import 'parameter.dart';
import 'result.dart';
import 'utils.dart';

/// Base class for database benchmarks.
abstract class DatabaseBenchmarkBase {
  final _operationDurations = <Duration>[];
  final _totalDurationStopwatch = Stopwatch();

  /// Runs the benchmark and prints the results to stdout.
  Future<void> report() async {
    await setup();

    try {
      if (executionModeParameter.current == ExecutionMode.jit) {
        // Warm up the JIT compiler.
        await _run();
      }

      _operationDurations.clear();
      _totalDurationStopwatch.reset();

      await _run();

      final result = BenchmarkResult.workload(
        latencies: _operationDurations,
        latencyStatistic: median,
        totalDuration: _totalDurationStopwatch.elapsed,
      );

      // ignore: avoid_print
      print(jsonEncodePretty(result.toJson()));
    } finally {
      await tearDown();
    }
  }

  Future<void> _run() async {
    switch (apiTypeParameter.current) {
      case ApiType.sync:
        runSync();
        break;
      case ApiType.async:
        await runAsync();
        break;
    }
  }

  /// Setup code executed prior to the benchmark runs.
  @protected
  Future<void> setup() async {}

  /// Teardown code executed after the benchmark runs.
  @protected
  Future<void> tearDown() async {}

  /// Run the benchmarked workload synchronously.
  ///
  /// Use [measureSync] and [measureOperationSync] to measure the time it takes
  /// to complete the workload and its operations isolated from setup and
  /// teardown.
  ///
  /// This method might be called multiple times, so ensure it is isolated from
  /// any state that might be modified by other invocations.
  @visibleForOverriding
  void runSync() => throw UnimplementedError();

  /// Run the benchmarked workload asynchronously.
  ///
  /// Use [measureAsync], [measureOperationSync] and [measureOperationAsync] to
  /// measure the time it takes to complete the workload and its operations
  /// isolated from setup and teardown.
  ///
  /// This method might be called multiple times, so ensure it is isolated from
  /// any state that might be modified by other invocations.
  @visibleForOverriding
  Future<void> runAsync() => throw UnimplementedError();

  /// Measure the total time it takes to complete the synchronous benchmarked
  /// workload.
  @protected
  void measureSync(void Function() fn) {
    _totalDurationStopwatch.start();
    fn();
    _totalDurationStopwatch.stop();
  }

  /// Measure the total time it takes to complete the asynchronous benchmarked
  /// workload.
  @protected
  Future<void> measureAsync(Future<void> Function() fn) async {
    _totalDurationStopwatch.start();
    await fn();
    _totalDurationStopwatch.stop();
  }

  /// Measure the time it takes to complete a single synchronous operation
  /// within the benchmarked workload.
  ///
  /// This method must only be called from within a [measureSync] or
  /// [measureAsync] call.
  @protected
  void measureOperationSync(void Function() fn) {
    final stopwatch = Stopwatch()..start();
    fn();
    stopwatch.stop();
    _operationDurations.add(stopwatch.elapsed);
  }

  /// Measure the time it takes to complete a single asynchronous operation
  /// within the benchmarked workload.
  ///
  /// This method must only be called from within a [measureAsync] call.
  @protected
  Future<void> measureOperationAsync(Future<void> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    await fn();
    stopwatch.stop();
    _operationDurations.add(stopwatch.elapsed);
  }
}

/// Base class for Couchbase Lite database benchmarks.
abstract class CblDatabaseBenchmark extends DatabaseBenchmarkBase {
  var _nextDatabaseId = 0;

  // A benchmark might open multiple databases (e.g. for warum up and testing).
  // We need to make sure that each database has a unique in the temporary
  // directory.
  String _nextDatabaseName() => '${_nextDatabaseId++}';

  late final Directory _tempDirectory;

  DatabaseConfiguration get _databaseConfiguration =>
      createDatabaseConfiguration(_tempDirectory);

  @visibleForOverriding
  DatabaseConfiguration createDatabaseConfiguration(Directory tempDirectory) =>
      DatabaseConfiguration(directory: tempDirectory.path);

  @override
  Future<void> setup() async {
    await super.setup();

    await initCouchbaseLite();

    _tempDirectory = await Directory.systemTemp.createTemp();
  }

  @override
  Future<void> tearDown() async {
    await super.tearDown();
    await _tempDirectory.delete(recursive: true);
  }

  @protected
  SyncDatabase openSyncDatabase() =>
      Database.openSync(_nextDatabaseName(), _databaseConfiguration);

  @protected
  Future<AsyncDatabase> openAsyncDatabase() =>
      Database.openAsync(_nextDatabaseName(), _databaseConfiguration);

  @protected
  void withSyncDatabase(void Function(SyncDatabase database) fn) {
    final database = openSyncDatabase();
    try {
      fn(database);
    } finally {
      database.close();
    }
  }

  @protected
  Future<void> withAsyncDatabase(
    Future<void> Function(AsyncDatabase database) fn,
  ) async {
    final database = await openAsyncDatabase();
    try {
      await fn(database);
    } finally {
      await database.close();
    }
  }
}
