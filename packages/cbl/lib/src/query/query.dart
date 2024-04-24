import 'dart:async';

import 'package:meta/meta.dart';

import '../bindings.dart';
import '../couchbase_lite.dart';
import '../database.dart';
import '../database/database.dart';
import '../support/resource.dart';
import 'parameters.dart';
import 'query_change.dart';
import 'result.dart';
import 'result_set.dart';

/// A listener that is called when the results of a [Query] have changed.
///
/// {@category Query}
typedef QueryChangeListener<T extends ResultSet> = void Function(
  QueryChange<T> change,
);

/// A [Database] query.
///
/// {@category Query}
abstract interface class Query implements Resource {
  /// The values with which to substitute the parameters defined in the query.
  ///
  /// All parameters defined in the query must be given values before running
  /// the query, or the query will fail.
  ///
  /// The returned [Parameters] will be readonly.
  Parameters? get parameters;

  /// Sets the [parameters] of this query.
  FutureOr<void> setParameters(Parameters? value);

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
  ///
  /// - The first section is this query compiled into an SQLite query.
  /// - The second section is the output of SQLite's "EXPLAIN QUERY PLAN"
  ///   command applied to that query; for help interpreting this, see
  ///   https://www.sqlite.org/eqp.html . The most important thing to know is
  ///   that if you see "SCAN TABLE", it means that SQLite is doing a slow
  ///   linear scan of the documents instead of using an index.
  /// - The third sections is this queries JSON representation. This is the data
  ///   structure that is built to describe this query, either by the the query
  ///   builder or when an SQL++ query is compiled.
  FutureOr<String> explain();

  /// Adds a [listener] to be notified of changes to the results of this query.
  ///
  /// A new listener will be called with the current results, after being added.
  /// Subsequently it will only be called when the results change, either
  /// because the contents of the database have changed or this query's
  /// [parameters] have been changed through [setParameters].
  ///
  /// {@macro cbl.Collection.addChangeListener}
  ///
  /// See also:
  ///
  /// - [QueryChange] for the change event given to [listener].
  /// - [removeChangeListener] for removing a previously added listener.
  FutureOr<ListenerToken> addChangeListener(QueryChangeListener listener);

  /// {@macro cbl.Collection.removeChangeListener}
  ///
  /// See also:
  ///
  /// - [addChangeListener] for listening to changes in the results of this
  ///   query.
  FutureOr<void> removeChangeListener(ListenerToken token);

  /// Returns a [Stream] to be notified of changes to the results of this query.
  ///
  /// This is an alternative stream based API for the [addChangeListener] API.
  ///
  /// {@macro cbl.Collection.AsyncListenStream}
  Stream<QueryChange> changes();

  /// The JSON representation of this query.
  ///
  /// This value can be used to recreate this query with [Database.createQuery]
  /// and the parameter `json` set to `true`.
  ///
  /// Is `null`, if this query was created from an SQL++ query.
  String? get jsonRepresentation;

  /// The SQL++ representation of this query.
  ///
  /// This value can be used to recreate this query with [Database.createQuery].
  ///
  /// Is `null`, if this query was created through the builder API or from the
  /// JSON representation.
  String? get sqlRepresentation;
}

/// A [Query] with a primarily synchronous API.
///
/// {@category Query}
abstract interface class SyncQuery implements Query {
  @override
  void setParameters(Parameters? value);

  @override
  SyncResultSet execute();

  @override
  String explain();

  @override
  ListenerToken addChangeListener(QueryChangeListener<SyncResultSet> listener);

  @override
  void removeChangeListener(ListenerToken token);

  @override
  Stream<QueryChange<SyncResultSet>> changes();
}

/// A [Query] query with a primarily asynchronous API.
///
/// {@category Query}
abstract interface class AsyncQuery implements Query {
  @override
  Future<void> setParameters(Parameters? value);

  @override
  Future<ResultSet> execute();

  @override
  Future<String> explain();

  @override
  Future<ListenerToken> addChangeListener(QueryChangeListener listener);

  @override
  Future<void> removeChangeListener(ListenerToken token);

  @override
  AsyncListenStream<QueryChange> changes();
}

abstract base class QueryBase with ClosableResourceMixin implements Query {
  QueryBase({
    required this.typeName,
    this.database,
    required this.language,
    this.definition,
  });

  final String typeName;
  final Database? database;
  final CBLQueryLanguage language;
  String? definition;

  bool _didAttachToParentResource = false;

  @override
  T useSync<T>(T Function() f) {
    attachToParentResource();
    return super.useSync(f);
  }

  @override
  Future<T> use<T>(FutureOr<T> Function() f) {
    attachToParentResource();
    return super.use(f);
  }

  @override
  String? get jsonRepresentation =>
      language == CBLQueryLanguage.json ? definition : null;

  @override
  String? get sqlRepresentation =>
      language == CBLQueryLanguage.n1ql ? definition : null;

  @override
  String toString() {
    final languageName = switch (language) {
      CBLQueryLanguage.json => 'JSON',
      CBLQueryLanguage.n1ql => 'SQL++',
    };
    return '$typeName($languageName: $definition)';
  }

  @protected
  void attachToParentResource() {
    if (!_didAttachToParentResource) {
      needsToBeClosedByParent = false;
      attachTo(database! as ClosableResourceMixin);
      _didAttachToParentResource = true;
    }
  }
}
