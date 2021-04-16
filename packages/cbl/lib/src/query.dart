import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import 'database.dart';
import 'fleece.dart';
import 'native_object.dart';
import 'utils.dart';
import 'worker/cbl_worker.dart';

export 'package:cbl_ffi/cbl_ffi.dart' show QueryLanguage;

// region Internal API

Future<Query> createQuery({
  required WorkerObject<CBLDatabase> db,
  required QueryDefinition queryDefinition,
}) {
  return db
      .execute((pointer) => CreateDatabaseQuery(
            pointer,
            queryDefinition.queryString,
            queryDefinition.language,
          ))
      .then((address) => Query._fromPointer(
            address.toPointer(),
            db.worker,
          ));
}

// endregion

/// A definition for a database query which can be compiled into a [Query].
///
/// {@macro cbl.Query.language}
///
/// Use [N1QLQuery] and [JSONQuery] to create query definitions in the
/// corresponding language.
///
/// See:
/// - [Database.query] for creating [Query]s.
@immutable
abstract class QueryDefinition {
  /// The query language this query is defined in.
  QueryLanguage get language;

  /// The query string which defines this query.
  String get queryString;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryDefinition &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          queryString == other.queryString;

  @override
  int get hashCode => super.hashCode ^ language.hashCode ^ queryString.hashCode;
}

/// A [QueryDefinition] written in N1QL.
class N1QLQuery extends QueryDefinition {
  static String _removeWhiteSpaceFromQueryDefinition(String query) =>
      query.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Creates a [QueryDefinition] written in N1QL.
  N1QLQuery(String queryDefinition)
      : queryString = _removeWhiteSpaceFromQueryDefinition(queryDefinition);

  @override
  QueryLanguage get language => QueryLanguage.N1QL;

  @override
  final String queryString;

  @override
  String toString() => 'N1QLQuery($queryString)';
}

/// A [QueryDefinition] in the JSON syntax.
class JSONQuery extends QueryDefinition {
  /// Creates a [QueryDefinition] in the JSON syntax from JSON
  /// represented as primitive Dart values.
  JSONQuery(List<dynamic> queryDefinition)
      : queryString = jsonEncode(queryDefinition);

  /// Creates a [QueryDefinition] in the JSON syntax from a JSON string.
  JSONQuery.fromString(this.queryString);

  @override
  QueryLanguage get language => QueryLanguage.json;

  @override
  final String queryString;

  @override
  String toString() => 'JSONQuery($queryString)';
}

/// A [Query] represents a compiled database query.
///
/// {@template cbl.Query.language}
/// The query language is a large subset of the
/// [N1QL](https://www.couchbase.com/products/n1ql) language from Couchbase
/// Server, which you can think of as "SQL for JSON" or "SQL++".
///
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
///
/// See:
/// - [QueryDefinition] for the object which represents an uncompiled database
///   query.
class Query extends NativeResource<WorkerObject<CBLQuery>> {
  Query._fromPointer(Pointer<CBLQuery> pointer, Worker worker)
      : super(CblRefCountedWorkerObject(
          pointer,
          worker,
          release: true,
          retain: false,
        ));

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
  /// final query = await db.query(N1QLQuery(
  ///   '''
  ///   SELECT p.name, r.rating
  ///     FROM product p INNER JOIN reviews r ON array_contains(p.reviewList, r.META.id)
  ///       WHERE p.META.id = $PRODUCT_ID
  ///   ''',
  /// ));
  ///
  /// await query.setParameters(MutableDict({
  ///   'PRODUCT_ID': 'product320',
  /// }))
  /// ```
  Future<void> setParameters(Dict parameters) =>
      native.execute((pointer) => SetQueryParameters(
            pointer,
            parameters.native.pointer.address,
          ));

  /// Gets the values assigned to this query's parameters.
  ///
  /// The returned Dict must only be accessed while this Query has not been
  /// garbage collected.
  ///
  /// See:
  /// - [setParameters]
  Future<Dict?> getParameters() => native
      .execute((pointer) => GetQueryParameters(pointer))
      .then((address) => Dict.fromPointer(address.toPointer()));

  /// Runs the query, returning the results.
  Future<ResultSet> execute() => native
      .execute((pointer) => ExecuteQuery(pointer))
      .then((address) => ResultSet._fromPointer(
            address.toPointer(),
            release: true,
            retain: false,
          ));

  /// Returns information about the query, including the translated SQLite form,
  /// and the search strategy. You can use this to help optimize the query:
  /// the word `SCAN` in the strategy indicates a linear scan of the entire
  /// database, which should be avoided by adding an index. The strategy will
  /// also show which index(es), if any, are used.
  Future<String> explain() =>
      native.execute((pointer) => ExplainQuery(pointer));

  /// Returns the number of columns in each result.
  Future<int> columnCount() =>
      native.execute((pointer) => GetQueryColumnCount(pointer));

  /// Returns the name of a column in the result.
  ///
  /// The column name is based on its expression in the `SELECT...` or `WHAT:`
  /// section of the query. A column that returns a property or property path
  /// will be named after that property. A column that returns an expression
  /// will have an automatically-generated name like `$1`. To give a column a
  /// custom name, use the `AS` syntax in the query. Every column is guaranteed
  /// to have a unique name.
  Future<String> columnName(int index) =>
      native.execute((pointer) => GetQueryColumnName(pointer, index));

  /// Returns a [Stream] which emits a [ResultSet] when this query's results
  /// change, turning it into a "live query" until the stream is canceled.
  ///
  /// When the first change stream is created, the query will run and notify the
  /// subscriber of the results when ready. After that, it will run in the
  /// background after the database changes, and only notify the subscriber when
  /// the result set changes.
  Stream<ResultSet> changes() => callbackStream<ResultSet, int>(
        worker: native.worker,
        createRegisterCallbackRequest: (callback) => AddQueryChangeListener(
          native.pointerUnsafe,
          callback.native.pointerUnsafe.address,
        ),
        createEvent: (listenerTokenAddress, _) async {
          // The native side sends no arguments. When the native side notfies
          // the listener it has to copy the current query result set.

          final resultSetAddress =
              await native.execute((pointer) => CopyCurrentQueryResultSet(
                    pointer,
                    listenerTokenAddress,
                  ));

          return ResultSet._fromPointer(
            resultSetAddress.toPointer(),
            release: true,
            retain: false,
          );
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

class _ResultSetIterator extends NativeResource<NativeObject<CBLResultSet>>
    implements Iterator<Result>, Result {
  static late final _bindings = CBLBindings.instance.resultSet;

  _ResultSetIterator(NativeObject<CBLResultSet> native) : super(native);

  @override
  Result get current => this;

  @override
  bool moveNext() => _bindings.next(native.pointerUnsafe).toBool();

  @override
  Value operator [](Object keyOrIndex) {
    Pointer<FLValue> pointer;

    if (keyOrIndex is String) {
      pointer = runArena(() => _bindings.valueForKey(
            native.pointerUnsafe,
            keyOrIndex.toNativeUtf8().withScoped(),
          ));
    } else if (keyOrIndex is int) {
      pointer = _bindings.valueAtIndex(native.pointerUnsafe, keyOrIndex);
    } else {
      throw ArgumentError.value(keyOrIndex, 'keyOrIndex');
    }

    return Value.fromPointer(pointer);
  }

  @override
  Array get array => MutableArray.fromPointer(
        _bindings.rowArray(native.pointerUnsafe).cast(),
        release: true,
        retain: true,
      );

  @override
  Dict get dict => MutableDict.fromPointer(
        _bindings.rowDict(native.pointerUnsafe).cast(),
        release: true,
        retain: true,
      );
}

/// A [ResultSet] is an iterable of the [Result]s returned by a query.
///
/// It can only be iterated __once__.
///
/// See:
/// - [Result] for how to consume a single Result.
class ResultSet extends NativeResource<NativeObject<CBLResultSet>>
    with IterableMixin<Result> {
  ResultSet._fromPointer(
    Pointer<CBLResultSet> pointer, {
    required bool release,
    required bool retain,
  }) : super(CblRefCountedObject(
          pointer,
          release: release,
          retain: retain,
        ));

  var _consumed = false;

  @override
  _ResultSetIterator get iterator {
    if (_consumed) {
      throw StateError(
        'ResultSet can only be consumed once and already has been.',
      );
    }
    _consumed = true;
    return _ResultSetIterator(native);
  }

  /// All the results as [Array]s.
  Iterable<Array> get asArrays => map((result) => result.array);

  /// All the results as [Dict]s.
  Iterable<Dict> get asDicts => map((result) => result.dict);
}
