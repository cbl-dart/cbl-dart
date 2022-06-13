import 'dart:async';

import 'package:meta/meta.dart';

import '../database/database_base.dart';
import '../document/common.dart';
import '../fleece/decoder.dart';
import '../fleece/dict_key.dart';
import '../typed_data.dart';
import 'query.dart';
import 'result.dart';

/// A set of [Result]s which is returned when executing a [Query].
///
/// {@category Query}
abstract class ResultSet {
  /// Returns a stream which consumes this result set and emits its results.
  ///
  /// A result set can only be consumed once and listening to the returned
  /// stream counts as consuming it. Other methods for consuming this result set
  /// must not be used when using a stream.
  Stream<Result> asStream();

  /// Returns a stream which consumes this result set and emits its results as
  /// typed dictionaries of type [D].
  ///
  /// A result set can only be consumed once and listening to the returned
  /// stream counts as consuming it. Other methods for consuming this result set
  /// must not be used when using a stream.
  @experimental
  Stream<D> asTypedStream<D extends TypedDictionaryObject>();

  /// Consumes this result set and returns a list of all its [Result]s.
  FutureOr<List<Result>> allResults();

  /// Consumes this result set and returns a list of all its results as typed
  /// dictionaries of type [D].
  @experimental
  FutureOr<List<D>> allTypedResults<D extends TypedDictionaryObject>();
}

/// A [ResultSet] which can be iterated synchronously as well asynchronously.
///
/// {@category Query}
abstract class SyncResultSet
    implements ResultSet, Iterable<Result>, Iterator<Result> {
  /// Returns an iterable which consumes this result set and emits its results
  /// as typed dictionaries of type [D].
  @experimental
  Iterable<D> asTypedIterable<D extends TypedDictionaryObject>();

  @override
  List<Result> allResults();

  @override
  @experimental
  List<D> allTypedResults<D extends TypedDictionaryObject>();
}

/// A [ResultSet] which can be iterated asynchronously.
///
/// {@category Query}
abstract class AsyncResultSet extends ResultSet {
  @override
  Future<List<Result>> allResults();

  @override
  @experimental
  Future<List<D>> allTypedResults<D extends TypedDictionaryObject>();
}

/// Creates a [DatabaseMContext] for use in [ResultSet] implementations.
///
/// Result sets don't use the shared keys of the database and so must not use
/// the [DictKeys] and [SharedKeysTable] of the database. See SQLiteQuery.cc for
/// more information.
/// https://github.com/couchbase/couchbase-lite-core/blob/733eecb4fc73a05ce35bf458703dac2d7382c296/LiteCore/Query/SQLiteQuery.cc#L514-L524
///
/// A bug was the result of using the databases shared keys table in the result
/// set. https://github.com/cbl-dart/cbl-dart/issues/322
///
/// Result sets also cannot use a [SharedStringsTable] because the CBL C SDK
/// does not return strictly immutable Fleece data from the result set API.
DatabaseMContext createResultSetMContext(DatabaseBase database) =>
    DatabaseMContext(
      database: database,
      dictKeys: OptimizingDictKeys(),
      sharedKeysTable: SharedKeysTable(),
    );
