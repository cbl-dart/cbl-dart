import 'package:cbl/cbl.dart';

import '../test_binding.dart';

/// Opens a test database and registers a tear down hook to clean it up when
/// the test scope is done.
///
/// The name of the database is generated by giving [dbName] to [testDbName]
/// unless [useNameDirectly] is `true`. Then [dbName] is used directly.
///
/// The database will be created in the [tmpDir].
Database openTestDb(
  String? dbName, {
  bool useNameDirectly = false,
  bool autoClose = true,
}) {
  final db = Database.open(
    useNameDirectly ? dbName! : testDbName(dbName),
    config: DatabaseConfiguration(
      directory: tmpDir,
    ),
  );

  if (autoClose) addTearDown(db.close);

  return db;
}

extension DatabaseUtilsExtension on Database {
  /// Returns a stream wich emits the ids of all the documents in this database.
  Iterable<String> getAllIds() => query(N1QLQuery('SELECT META().id'))
      .execute()
      .map((result) => result[0] as String);

  /// Returns a stream which emits the ids of all the documents in the
  /// database when they change.
  Stream<List<String>> watchAllIds() =>
      query(N1QLQuery('SELECT META().id')).changes().map((resultSet) =>
          resultSet.map((result) => result[0] as String).toList());

  /// Deletes all documents in this database and returns whether any documents
  /// where deleted.
  bool deleteAllDocuments() {
    var deletedAnyDocument = false;
    for (final id in getAllIds()) {
      final doc = getDocument(id);
      if (doc != null) {
        deleteDocument(doc);
      }
      deletedAnyDocument = doc != null;
    }
    return deletedAnyDocument;
  }
}
