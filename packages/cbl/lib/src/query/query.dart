import 'dart:async';

import '../database.dart';
import '../database/database.dart';
import '../support/resource.dart';
import 'ffi_query.dart';
import 'parameters.dart';
import 'result.dart';
import 'result_set.dart';

/// A [Database] query.
abstract class Query implements Resource {
  /// {@template cbl.Query.fromN1ql}
  /// Creates an [AsyncQuery] from a N1QL [query].
  /// {@endtemplate}
  static Future<AsyncQuery> fromN1ql(AsyncDatabase database, String query) =>
      AsyncQuery.fromN1ql(database, query);

  /// {@template cbl.Query.fromN1qlSync}
  /// Creates a [SyncQuery] from a N1QL [query].
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static SyncQuery fromN1qlSync(SyncDatabase database, String query) =>
      SyncQuery.fromN1ql(database, query);

  /// {@template cbl.Query.fromJsonRepresentation}
  /// Creates an [AsyncQuery] from the [Query.jsonRepresentation] of a query.
  /// {@endtemplate}
  static Future<AsyncQuery> fromJsonRepresentation(
    AsyncDatabase database,
    String jsonRepresentation,
  ) =>
      AsyncQuery.fromJsonRepresentation(database, jsonRepresentation);

  /// {@template cbl.Query.fromJsonRepresentation}
  /// Creates an [SyncQuery] from the [Query.jsonRepresentation] of a query.
  /// {@endtemplate}
  // ignore: prefer_constructors_over_static_methods
  static SyncQuery fromJsonRepresentationSync(
    SyncDatabase database,
    String jsonRepresentation,
  ) =>
      SyncQuery.fromJsonRepresentation(database, jsonRepresentation);

  /// [Parameters] used for setting values to the query parameters defined
  /// in the query.
  ///
  /// All parameters defined in the query must be given values before running
  /// the query, or the query will fail.
  ///
  /// The returned [Parameters] will be readonly.
  Parameters? get parameters;
  set parameters(Parameters? value);

  /// Executes this query.
  ///
  /// Returns a [ResultSet] that iterates over [Result] rows one at a time. You
  /// can run the query any number of times, and you can have multiple
  /// [ResultSet]s active at once.
  ///
  /// The results come from a snapshot of the database taken at the moment
  /// [execute] is called, so they will not reflect any changes made to the
  /// database afterwards.
  FutureOr<ResultSet> execute();

  /// Returns a string describing the implementation of the compiled query.
  ///
  /// This is intended to be read by a developer for purposes of optimizing the
  /// query, especially to add database indexes. It's not machine-readable and
  /// its format may change.
  ///
  /// As currently implemented, the result has three sections, separated by two
  /// newlines:
  /// * The first section is this query compiled into an SQLite query.
  /// * The second section is the output of SQLite's "EXPLAIN QUERY PLAN"
  ///   command applied to that query; for help interpreting this, see
  ///   https://www.sqlite.org/eqp.html . The most important thing to know is
  ///   that if you see "SCAN TABLE", it means that SQLite is doing a slow
  ///   linear scan of the documents instead of using an index.
  /// * The third sections is this queries JSON representation. This is the data
  ///   structure that is built to describe this query, either by the the query
  ///   builder or when a N1QL query is compiled.
  FutureOr<String> explain();

  /// Returns a [Stream] of [ResultSet]s which emits when the [ResultSet] of
  /// this query changes.
  Stream<ResultSet> changes();

  /// The JSON representation of this query.
  ///
  /// This value can be used to recreate this query with
  /// [SyncQuery.fromJsonRepresentation] or [AsyncQuery.fromJsonRepresentation].
  ///
  /// Is `null`, if this query was created from a N1QL query.
  String? get jsonRepresentation;
}

/// A [Query] with a primarily synchronous API.
abstract class SyncQuery implements Query {
  /// {@macro cbl.Query.fromN1qlSync}
  factory SyncQuery.fromN1ql(SyncDatabase database, String query) =>
      FfiQuery(database, query, debugCreator: 'SyncQuery.fromN1ql()');

  /// {@macro cbl.Query.fromJsonRepresentationSync}
  factory SyncQuery.fromJsonRepresentation(
          SyncDatabase database, String json) =>
      FfiQuery.fromJsonRepresentation(
        database,
        json,
        debugCreator: 'SyncQuery.fromJsonRepresentation()',
      );

  @override
  SyncResultSet execute();

  @override
  String explain();

  @override
  Stream<SyncResultSet> changes();
}

/// A [Query] query with a primarily asynchronous API.
abstract class AsyncQuery implements Query {
  /// {@macro cbl.Query.fromN1ql}
  static Future<AsyncQuery> fromN1ql(AsyncDatabase database, String query) =>
      throw UnimplementedError();

  /// {@macro cbl.Query.fromJsonRepresentation}
  static Future<AsyncQuery> fromJsonRepresentation(
    AsyncDatabase database,
    String json,
  ) =>
      throw UnimplementedError();

  @override
  Future<ResultSet> execute();

  @override
  Future<String> explain();
}
