import 'dart:async';

import 'query.dart';
import 'result.dart';

/// A set of [Result]s which is returned when executing a [Query].
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
abstract class SyncResultSet
    implements ResultSet, Iterable<Result>, Iterator<Result> {}
