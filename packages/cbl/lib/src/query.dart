import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'bindings/bindings.dart';
import 'ffi_utils.dart';
import 'fleece.dart';
import 'native_callbacks.dart';
import 'utils.dart';
import 'worker/handlers.dart';
import 'worker/worker.dart';

export 'bindings/query.dart' show QueryLanguage;

late final _baseBindings = CBLBindings.instance.base;

// region Internal API

Query createQuery({
  required Pointer<Void> pointer,
  required Worker worker,
  bool retain = false,
}) =>
    Query._(pointer, worker, retain);

String removeWhiteSpaceFromQuery(String query) => query
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

// endregion

/// A callback to be invoked after a [Query]'s results have changed.
///
/// The callback is given the Query that triggered the listener and the updated
/// [ResultSet].
typedef QueryChangeListener = void Function(Query query, ResultSet resultSet);

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
    _baseBindings.bindCBLRefCountedToDartObject(this, _pointer, retain.toInt);
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
  Future<void> setParameters(Dict parameters) => _worker.makeRequest(
      SetQueryParameters(_pointer.address, parameters.ref.address));

  /// Gets the values assigned to this query's parameters.
  ///
  /// The returned Dict must only be accessed while this Query has not been
  /// garbage collected.
  ///
  /// See:
  /// - [setParameters]
  Future<Dict?> getParameters() => _worker
      .makeRequest<int?>(GetQueryParameters(_pointer.address))
      .then((address) => address?.let((it) => Dict.fromPointer(it.toPointer)));

  /// Runs the query, returning the results.
  Future<ResultSet> execute() => _worker
      .makeRequest<int>(ExecuteQuery(_pointer.address))
      .then((address) => ResultSet._(address.toPointer, false));

  /// Returns information about the query, including the translated SQLite form,
  /// and the search strategy. You can use this to help optimize the query:
  /// the word `SCAN` in the strategy indicates a linear scan of the entire
  /// database, which should be avoided by adding an index. The strategy will
  /// also show which index(es), if any, are used.
  Future<String> explain() =>
      _worker.makeRequest(ExplainQuery(_pointer.address));

  /// Returns the number of columns in each result.
  Future<int> get columnCount =>
      _worker.makeRequest(GetQueryColumnCount(_pointer.address));

  /// Returns the name of a column in the result.
  ///
  /// The column name is based on its expression in the `SELECT...` or `WHAT:`
  /// section of the query. A column that returns a property or property path
  /// will be named after that property. A column that returns an expression
  /// will have an automatically-generated name like `$1`. To give a column a
  /// custom name, use the `AS` syntax in the query. Every column is guaranteed
  /// to have a unique name.
  Future<String> columnName(int index) =>
      _worker.makeRequest(GetQueryColumnName(_pointer.address, index));

  /// Registers a change [listener] callback with this Query, turning it into a
  /// "live query" until the listener is removed (via [removeChangeListener]).
  ///
  /// When the first change listener is added, the query will run (in the
  /// background) and notify the listener(s) of the results when ready. After
  /// that, it will run in the background after the database changes, and only
  /// notify the listeners when the result set changes.
  Future<void> addChangeListener(QueryChangeListener listener) async {
    late int listenerTokenAddress;

    final listenerId =
        NativeCallbacks.instance.registerCallback<QueryChangeListener>(
      listener,
      (listener, arguments, result) async {
        // The native side sends no arguments. When the native side notfies the
        // listener it has to copy the current query result set.

        final resultSet = await _worker
            .makeRequest<int>(CopyCurrentQueryResultSet(
              _pointer.address,
              listenerTokenAddress,
            ))
            .then((address) => ResultSet._(address.toPointer, false));

        listener(this, resultSet);
      },
    );

    listenerTokenAddress = await _worker
        .makeRequest<int>(AddQueryChangeListener(_pointer.address, listenerId));
  }

  /// Stops the [changeListener] from being notified of changes.
  Future<void> removeChangeListener(QueryChangeListener changeListener) async {
    NativeCallbacks.instance.unregisterCallback(changeListener);
  }
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

  _ResultSetIterator(this._pointer);

  final Pointer<Void> _pointer;

  @override
  Result get current => this;

  @override
  bool moveNext() => _bindings.next(_pointer).toBool;

  @override
  Value operator [](Object keyOrIndex) {
    Pointer<Void> pointer;

    if (keyOrIndex is String) {
      pointer = runArena(() {
        return _bindings.valueForKey(_pointer, keyOrIndex.asUtf8Scoped);
      });
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
        .bindCBLRefCountedToDartObject(this, _pointer, retain.toInt);
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
    return _ResultSetIterator(_pointer);
  }

  /// All the results as [Array]s.
  Iterable<Array> get asArrays => map((result) => result.array);

  /// All the results as [Dict]s.
  Iterable<Dict> get asDicts => map((result) => result.dict);
}
