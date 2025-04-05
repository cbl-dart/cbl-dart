// ignore_for_file: do_not_use_environment

import 'dart:io';
import 'dart:math';

import 'package:benchmark/utils.dart';
import 'package:cbl/cbl.dart';

void main() => _Benchmark().report();

class _Benchmark extends DatabaseBenchmarkBase {
  var _databaseId = 0;

  late final Directory _tempDirectory;
  late final DatabaseConfiguration _databaseConfiguration;
  late final List<List<Map<String, Object?>>> _batchesData;

  String _nextDatabaseName() => '${_databaseId++}';

  @override
  Future<void> setup() async {
    await initCouchbaseLite();

    const operationCount = int.fromEnvironment('OPERATION_COUNT');
    const batchSize = int.fromEnvironment('BATCH_SIZE');
    const fixture = String.fromEnvironment('FIXTURE');

    final benchmarkData =
        List<Map<String, Object?>>.from(loadFixtureAsJson(fixture)! as List);
    final operationsData = List.generate(
      operationCount,
      (index) => benchmarkData[index % benchmarkData.length],
    );
    _batchesData = <List<Map<String, Object?>>>[
      for (var i = 0; i < operationCount; i += batchSize)
        operationsData.sublist(i, min(i + batchSize, operationCount)),
    ];

    _tempDirectory = await Directory.systemTemp.createTemp();
    _databaseConfiguration =
        DatabaseConfiguration(directory: _tempDirectory.path);
  }

  @override
  Future<void> tearDown() async {
    await _tempDirectory.delete(recursive: true);
  }

  @override
  void runSync() {
    final database =
        Database.openSync(_nextDatabaseName(), _databaseConfiguration);
    final collection = database.defaultCollection;

    measureSyncBenchmark(() {
      for (final batch in _batchesData) {
        database.inBatchSync(() {
          for (final data in batch) {
            measureSyncOperation(() {
              collection.saveDocument(MutableDocument(data));
            });
          }
        });
      }
    });

    database.close();
  }

  @override
  Future<void> runAsync() async {
    final database =
        await Database.openAsync(_nextDatabaseName(), _databaseConfiguration);
    final collection = await database.defaultCollection;

    await measureAsyncBenchmark(() async {
      for (final batch in _batchesData) {
        await database.inBatch(() async {
          for (final data in batch) {
            await measureAsyncOperation(() async {
              await collection.saveDocument(MutableDocument(data));
            });
          }
        });
      }
    });

    await database.close();
  }
}
