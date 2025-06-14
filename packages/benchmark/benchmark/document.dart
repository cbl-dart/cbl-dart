import 'dart:io';

import 'package:benchmark/utils.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:cbl/cbl.dart';

/// Benchmark that measures the performance of looking up properties in a
/// document.
class DocumentPropertyLookup extends BenchmarkBase {
  DocumentPropertyLookup() : super('property_lookup');

  static const properties = 100;

  late final Directory tempDir;
  late final SyncDatabase db;
  late final SyncCollection collection;
  late final String id;
  final data = {
    for (final i in Iterable<int>.generate(properties)) 'key$i': true,
  };

  @override
  void setup() {
    tempDir = Directory.systemTemp.createTempSync();
    db = Database.openSync(
      'db',
      DatabaseConfiguration(directory: tempDir.path),
    );
    collection = db.defaultCollection;
    final doc = MutableDocument(data);
    id = doc.id;
    collection.saveDocument(doc);
  }

  @override
  void teardown() {
    db.close();
    tempDir.deleteSync(recursive: true);
  }

  @override
  void run() {
    // We want to measure the time it takes to look up a property for the first
    // time. Looking up a property for the second time is fast because entries
    // are cached, which is why we load a new document each time.
    // To offset the time it takes to load a document, we access multiple
    // properties.
    final doc = collection.document(id)!;
    data.keys.forEach(doc.value);
  }
}

class DocumentToPlainMap extends BenchmarkBase {
  DocumentToPlainMap() : super('toPlainMap');

  static const properties = 100;

  late final Directory tempDir;
  late final SyncDatabase db;
  late final SyncCollection collection;
  late final String id;
  final data = {
    for (final i in Iterable<int>.generate(properties)) 'key$i': true,
  };

  @override
  void setup() {
    tempDir = Directory.systemTemp.createTempSync();
    db = Database.openSync(
      'db',
      DatabaseConfiguration(directory: tempDir.path),
    );
    collection = db.defaultCollection;
    final doc = MutableDocument(data);
    id = doc.id;
    collection.saveDocument(doc);
  }

  @override
  void teardown() {
    db.close();
    tempDir.deleteSync(recursive: true);
  }

  @override
  void run() {
    collection.document(id)!.toPlainMap();
  }
}

void main() async {
  await initCouchbaseLite();

  final benchmarks = [DocumentPropertyLookup(), DocumentToPlainMap()];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
