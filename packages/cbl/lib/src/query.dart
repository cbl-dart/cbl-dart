import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'fleece.dart';
import 'utils.dart';
import 'worker/cbl_worker.dart';

export 'package:cbl_ffi/cbl_ffi.dart' show QueryLanguage;

late final _baseBindings = CBLBindings.instance.base;

// region Internal API

Future<Query> createQuery({
  required Pointer<CBLDatabase> db,
  required Worker worker,
  required String queryString,
  required QueryLanguage language,
  bool retain = false,
}) async {
  if (language == QueryLanguage.N1QL) {
    queryString = _removeWhiteSpaceFromQuery(queryString);
  }

  final address = await worker
      .execute(CreateDatabaseQuery(db.address, queryString, language));

  return Query._(address.toPointer(), worker, retain);
}

String _removeWhiteSpaceFromQuery(String query) =>
    query.replaceAll(RegExp(r'\s+'), ' ').trim();

// endregion

/// A [Query] represents a compiled database query.
///
/// The query language is a large subset of the
/// [N1QL](https://www.couchbase.com/products/n1ql) language from Couchbase
/// Server, which you can think of as "SQL for JSON" or "SQL++".
///
/// {@template cbl.Query.language}
/// Queries may be given either in
/// [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html),
/// or in JSON using a
/// [schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
/// that resembles a parse tree of N1QL. The JSON syntax is harder for humans,
/// but much more amenable to machine generation, if you need to create queries
/// programmatically or translate them from some other form.
/// {@endtemplate}
///
/// ## Listening to a Query
/// Adding a change listener to a query turns it into a "live query". When
/// changes are made to documents, the query will periodically re-run and
/// compare its results with the prior results; if the new results are
/// different, the listener callback will be called.
///
/// The [ResultSet] passed to the listener is the _entire new result set_, not
/// just the rows that changed.
class Query {
  Query._(this._pointer, this._worker, bool retain) {
    _baseBindings.bindCBLRefCountedToDartObject(this, _pointer, retain.toInt());
  }

  final Pointer<Void> _pointer;

  final Worker _worker;

  /// Assigns values to the query's parameters.
  ///
  /// These values will be substituted for those parameters whenever the query
  /// is executed, until they are next assigned.
  ///
  /// Parameters are specified in the query source as e.g. `$PARAM` (N1QL) or
  /// `["$PARAM"]` (JSON). In this example, the assigned [Dict] should have a
  /// key `PARAM` that maps to the value of the parameter.
  ///
  /// ```dart
  /// final query = await db.query(
  ///   '''
  ///   SELECT p.name, r.rating
  ///     FROM product p INNER JOIN reviews r ON array_contains(p.reviewList, r.META.id)
  ///         WHERE p.META.id  = $PRODUCT_ID
  ///   ''',
  /// );
  ///
  /// await query.setParameters(MutableDict({
  ///   'PRODUCT_ID': 'product320',
  /// }))
  /// ```
  Future<void> setParameters(Dict parameters) => _worker
      .execute(SetQueryParameters(_pointer.address, parameters.ref.address));

  /// Gets the values assigned to this query's parameters.
  ///
  /// The returned Dict must only be accessed while this Query has not been
  /// garbage collected.
  ///
  /// See:
  /// - [setParameters]
  Future<Dict?> getParameters() =>
      _worker.execute(GetQueryParameters(_pointer.address)).then(
          (address) => address?.let((it) => Dict.fromPointer(it.toPointer())));

  /// Runs the query, returning the results.
  Future<ResultSet> execute() => _worker
      .execute(ExecuteQuery(_pointer.address))
      .then((address) => ResultSet._(address.toPointer(), false));

  /// Returns information about the query, including the translated SQLite form,
  /// and the search strategy. You can use this to help optimize the query:
  /// the word `SCAN` in the strategy indicates a linear scan of the entire
  /// database, which should be avoided by adding an index. The strategy will
  /// also show which index(es), if any, are used.
  Future<String> explain() => _worker.execute(ExplainQuery(_pointer.address));

  /// Returns the number of columns in each result.
  Future<int> columnCount() =>
      _worker.execute(GetQueryColumnCount(_pointer.address));

  /// Returns the name of a column in the result.
  ///
  /// The column name is based on its expression in the `SELECT...` or `WHAT:`
  /// section of the query. A column that returns a property or property path
  /// will be named after that property. A column that returns an expression
  /// will have an automatically-generated name like `$1`. To give a column a
  /// custom name, use the `AS` syntax in the query. Every column is guaranteed
  /// to have a unique name.
  Future<String> columnName(int index) =>
      _worker.execute(GetQueryColumnName(_pointer.address, index));

  /// Returns a [Stream] which emits a [ResultSet] when this query's results
  /// change, turning it into a "live query" until the stream is canceled.
  ///
  /// When the first change stream is created, the query will run and notify the
  /// subscriber of the results when ready. After that, it will run in the
  /// background after the database changes, and only notify the subscriber when
  /// the result set changes.
  Stream<ResultSet> changes() => callbackStream<ResultSet, int>(
        worker: _worker,
        requestFactory: (callbackId) =>
            AddQueryChangeListener(_pointer.address, callbackId),
        eventCreator: (listenerTokenAddress, _) async {
          // The native side sends no arguments. When the native side notfies
          // the listener it has to copy the current query result set.

          final resultSetAddress =
              await _worker.execute(CopyCurrentQueryResultSet(
            _pointer.address,
            listenerTokenAddress,
          ));

          return ResultSet._(resultSetAddress.toPointer(), false);
        },
      );
}

/// One of the results that [Query]s return in [ResultSet]s.
///
/// A Result is only valid until the next Result has been received. To retain
/// data pull it out of the Result before moving on to the next Result.
abstract class Result {
  /// Returns the value of a column of the current result, given its
  /// (zero-based) numeric index as an `int` or it's name as a [String].
  ///
  /// This may return `null`, indicating `MISSING`, if the value doesn't exist,
  /// e.g. if the column is a property that doesn't exist in the document.
  ///
  /// See:
  /// - [Query.columnName] for a discussion of column names.
  Value operator [](Object keyOrIndex);

  /// Returns the current result as an array of column values.
  Array get array;

  /// Returns the current result as a dictionary mapping column names to values.
  Dict get dict;
}

class _ResultSetIterator extends Iterator<Result> implements Result {
  static late final _bindings = CBLBindings.instance.resultSet;

  _ResultSetIterator(this._resultSet);

  final ResultSet _resultSet;

  Pointer<Void> get _pointer => _resultSet._pointer;

  @override
  Result get current => this;

  @override
  bool moveNext() => _bindings.next(_pointer).toBool();

  @override
  Value operator [](Object keyOrIndex) {
    Pointer<Void> pointer;

    if (keyOrIndex is String) {
      pointer = runArena(() => _bindings.valueForKey(
            _pointer,
            keyOrIndex.toNativeUtf8().withScoped(),
          ));
    } else if (keyOrIndex is int) {
      pointer = _bindings.valueAtIndex(_pointer, keyOrIndex);
    } else {
      throw ArgumentError.value(keyOrIndex, 'keyOrIndex');
    }

    return Value.fromPointer(pointer);
  }

  @override
  Array get array => Array.fromPointer(
        _bindings.rowArray(_pointer),
        bindToValue: true,
        retain: true,
      );

  @override
  Dict get dict => Dict.fromPointer(
        _bindings.rowDict(_pointer),
        bindToValue: true,
        retain: true,
      );
}

/// A [ResultSet] is an iterable of the [Result]s returned by a query.
///
/// It can only be iterated __once__.
///
/// See:
/// - [Result] for how to consume a single Result.
class ResultSet extends IterableBase<Result> {
  ResultSet._(this._pointer, bool retain) {
    CBLBindings.instance.base
        .bindCBLRefCountedToDartObject(this, _pointer, retain.toInt());
  }

  final Pointer<Void> _pointer;

  var _consumed = false;

  @override
  _ResultSetIterator get iterator {
    if (_consumed) {
      throw StateError(
        'ResultSet can only be consumed once and already has been.',
      );
    }
    _consumed = true;
    return _ResultSetIterator(this);
  }

  /// All the results as [Array]s.
  Iterable<Array> get asArrays => map((result) => result.array);

  /// All the results as [Dict]s.
  Iterable<Dict> get asDicts => map((result) => result.dict);
}
