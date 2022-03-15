import 'dart:async';

import '../database/database_base.dart';
import '../document/common.dart';
import '../fleece/decoder.dart';
import 'query.dart';
import 'result.dart';

/// A set of [Result]s which is returned when executing a [Query].
///
/// {@category Query}
// ignore: one_member_abstracts
abstract class ResultSet {
  /// Returns a stream which consumes this result set and emits its results.
  ///
  /// A result set can only be consumed once and listening to the returned
  /// stream counts as consuming it. Other methods for consuming this result set
  /// must not be used when using a stream.
  Stream<Result> asStream();

  /// Consumes this result set and returns a list of all its [Result]s.
  FutureOr<List<Result>> allResults();
}

/// A [ResultSet] which can be iterated synchronously as well asynchronously.
///
/// {@category Query}
abstract class SyncResultSet
    implements ResultSet, Iterable<Result>, Iterator<Result> {}

/// Creates a [DatabaseMContext] for use in [ResultSet] implementations.
///
/// Result sets don't use the shared keys of the database and so must not used
/// the [SharedKeysTable] of the database.
/// See SQLiteQuery.cc for more information.
/// https://github.com/couchbase/couchbase-lite-core/blob/733eecb4fc73a05ce35bf458703dac2d7382c296/LiteCore/Query/SQLiteQuery.cc#L514-L524
///
/// A bug was the result of using the databases shared keys table in the result
/// set.
/// https://github.com/cbl-dart/cbl-dart/issues/322
///
/// Result sets also cannot use a [SharedStringsTable] because the CBL C SDK
/// does not return strictly immutable Fleece data from the result set API.
DatabaseMContext createResultSetMContext(DatabaseBase database) =>
    DatabaseMContext(
      database: database,
      dictKeys: database.dictKeys,
      sharedKeysTable: SharedKeysTable(),
    );
