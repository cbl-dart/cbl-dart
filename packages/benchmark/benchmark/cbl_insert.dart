// ignore_for_file: do_not_use_environment

import 'dart:math';

import 'package:benchmark/database_benchmark.dart';
import 'package:benchmark/parameter.dart';
import 'package:benchmark/utils.dart';
import 'package:cbl/cbl.dart';

void main() => CblInsertBenchmark().report();

class CblInsertBenchmark extends CblDatabaseBenchmark {
  late final List<List<Map<String, Object?>>> _batchesData;

  @override
  Future<void> setup() async {
    await super.setup();

    final operationCount = operationCountParameter.current;
    final batchSize = batchSizeParameter.current;
    final fixture = fixtureParameter.current;

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
  }

  @override
  void runSync() {
    withSyncDatabase((database) {
      final collection = database.defaultCollection;

      measureSync(() {
        for (final batch in _batchesData) {
          database.inBatchSync(() {
            for (final data in batch) {
              measureOperationSync(() {
                collection.saveDocument(MutableDocument(data));
              });
            }
          });
        }
      });
    });
  }

  @override
  Future<void> runAsync() async {
    await withAsyncDatabase((database) async {
      final collection = await database.defaultCollection;

      await measureAsync(() async {
        for (final batch in _batchesData) {
          await database.inBatch(() async {
            for (final data in batch) {
              await measureOperationAsync(() async {
                await collection.saveDocument(MutableDocument(data));
              });
            }
          });
        }
      });
    });
  }
}
