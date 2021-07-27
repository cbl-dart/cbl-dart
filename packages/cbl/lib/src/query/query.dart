import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';

import 'package:cbl/src/support/ffi.dart';
import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import '../database/_database.dart';
import '../document/array.dart';
import '../document/blob.dart';
import '../document/common.dart';
import '../document/dictionary.dart';
import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';

/// A query language
enum QueryLanguage {
  /// [JSON query schema](https://github.com/couchbase/couchbase-lite-core/wiki/JSON-Query-Schema)
  json,

  /// [N1QL syntax](https://docs.couchbase.com/server/6.0/n1ql/n1ql-language-reference/index.html)
  N1QL
}

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
  int get hashCode => language.hashCode ^ queryString.hashCode;
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

/// Query parameters used for setting values to the query parameters defined in
/// the query.
class Parameters {
  /// Creates new [Parameters], optionally initialized with other [parameters].
  Parameters([Parameters? parameters]) : this._(parameters: parameters);

  Parameters._({Parameters? parameters, bool readonly = false})
      : _data = parameters?._data?.let((it) => Map.of(it)),
        _readonly = readonly;

  final bool _readonly;
  Map<String, Object?>? _data;

  /// Gets the value of the parameter referenced by the given [name].
  Object? value(String name) => _data?[name];

  /// Set a value to the query parameter referenced by the given [name].
  ///
  /// {@template cbl.Parameters.parameterDefinition}
  /// TODO: describe how query parameters are defined.
  /// {@endtemplate}
  void setValue(Object? value, {required String name}) {
    _checkReadonly();
    _data ??= {};
    _data![name] = CblConversions.convertToCblObject(value);
  }

  /// Set a [String] to the query parameter referenced by the given
  /// [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setString(String? value, {required String name}) =>
      setValue(value, name: name);

  /// Set an integer number to the query parameter referenced by the given
  /// [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setInteger(int? value, {required String name}) =>
      setValue(value, name: name);

  /// Set a floating point number to the query parameter referenced by the given
  /// [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setFloat(double? value, {required String name}) =>
      setValue(value, name: name);

  /// Set a [num] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setNumber(num? value, {required String name}) =>
      setValue(value, name: name);

  /// Set a [bool] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setBoolean(bool? value, {required String name}) =>
      setValue(value, name: name);

  /// Set a [DateTime] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setDate(DateTime? value, {required String name}) =>
      setValue(value, name: name);

  /// Set a [Blob] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setBlob(Blob? value, {required String name}) =>
      setValue(value, name: name);

  /// Set an [Array]  to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setArray(Array? value, {required String name}) =>
      setValue(value?.toList(), name: name);

  /// Set a [Dictionary] to the query parameter referenced by the given [name].
  ///
  /// {@macro cbl.Parameters.parameterDefinition}
  void setDictionary(Dictionary? value, {required String name}) =>
      setValue(value?.toPlainMap(), name: name);

  void _checkReadonly() {
    if (_readonly) {
      throw StateError('This parameters object is readonly.');
    }
  }
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
abstract class Query implements Resource {
  /// The database this query is operating on.
  Database get database;

  /// The current values of the parameters of this [Query].
  ///
  /// These values will be substituted for those parameters whenever the query
  /// is executed, until they are next assigned.
  ///
  /// Parameters are specified in the query source as e.g. `$PARAM` (N1QL) or
  /// `["$PARAM"]` (JSON). In this example, the assigned [Parameters] should
  /// have a key `PARAM` that maps to the value of the parameter.
  ///
  /// ```dart
  /// final query = await db.query(N1QLQuery(
  ///   '''
  ///   SELECT p.name, r.rating
  ///     FROM _default AS p
  ///     INNER JOIN _default AS r ON array_contains(p.reviewList, META(r).id)
  ///       WHERE META(p).id = $PRODUCT_ID
  ///   ''',
  /// ));
  ///
  /// query.parameters.setString('product320', name: 'PRODUCT_ID');
  /// ```
  Parameters get parameters;
  set parameters(Parameters value);

  /// Runs the query, returning the results.
  ResultSet execute();

  /// Returns information about the query, including the translated SQLite form,
  /// and the search strategy. You can use this to help optimize the query:
  /// the word `SCAN` in the strategy indicates a linear scan of the entire
  /// database, which should be avoided by adding an index. The strategy will
  /// also show which index(es), if any, are used.
  String explain();

  /// Returns the number of columns in each result.
  int columnCount();

  /// Returns the name of a column in the result.
  ///
  /// The column name is based on its expression in the `SELECT...` or `WHAT:`
  /// section of the query. A column that returns a property or property path
  /// will be named after that property. A column that returns an expression
  /// will have an automatically-generated name like `$1`. To give a column a
  /// custom name, use the `AS` syntax in the query. Every column is guaranteed
  /// to have a unique name.
  String? columnName(int index);

  /// Returns a [Stream] which emits a [ResultSet] when this query's results
  /// change, turning it into a "live query" until the stream is canceled.
  ///
  /// When the first change stream is created, the query will run and notify the
  /// subscriber of the results when ready. After that, it will run in the
  /// background after the database changes, and only notify the subscriber when
  /// the result set changes.
  Stream<ResultSet> changes();
}

class QueryImpl extends CblObject<CBLQuery>
    with DelegatingResourceMixin
    implements Query {
  static late final _bindings = cblBindings.query;

  QueryImpl({
    required this.database,
    required QueryLanguage language,
    required String query,
    required String? debugCreator,
  }) : super(
          database.native.call((pointer) => _bindings.create(
                pointer,
                language.toCBLQueryLanguage(),
                query,
              )),
          debugName: 'Query(creator: $debugCreator)',
        ) {
    database.registerChildResource(this);
  }

  @override
  final DatabaseImpl database;

  @override
  Parameters get parameters => useSync(() => _parameters);
  var _parameters = Parameters();

  @override
  set parameters(Parameters value) => useSync(() => _parameters = value);

  void _flushParameters() {
    final dict = MutableDictionary(parameters._data) as MutableDictionaryImpl;
    final encoder = fl.FleeceEncoder();
    final result = dict.encodeTo(encoder);
    assert(result is! Future);
    final data = encoder.finish();
    final doc = fl.Doc.fromResultData(data, FLTrust.trusted);
    final flDict = doc.root.asDict!;
    runNativeCalls(() => _bindings.setParameters(
          native.pointer,
          flDict.native.pointer.cast(),
        ));
  }

  @override
  ResultSet execute() => useSync(() {
        _flushParameters();
        return ResultSet._(
          native.call(_bindings.execute),
          debugCreator: 'Query.execute()',
        );
      });

  @override
  String explain() => useSync(() => native.call(_bindings.explain));

  @override
  int columnCount() => useSync(() => native.call(_bindings.columnCount));

  @override
  String? columnName(int index) => useSync(() => native.call((pointer) {
        return _bindings.columnName(pointer, index);
      }));

  @override
  Stream<ResultSet> changes() => useSync(
      () => CallbackStreamController<ResultSet, Pointer<CBLListenerToken>>(
            parent: this,
            startStream: (callback) {
              _flushParameters();
              return _bindings.addChangeListener(
                native.pointer,
                callback.native.pointer,
              );
            },
            createEvent: (listenerToken, _) {
              return ResultSet._(
                native.call((pointer) {
                  // The native side sends no arguments. When the native side
                  // notfies the listener it has to copy the current query result
                  // set.
                  return _bindings.copyCurrentResults(
                    pointer,
                    listenerToken,
                  );
                }),
                debugCreator: 'Query.changes()',
              );
            },
          ).stream);
}

/// One of the results that [Query]s return in [ResultSet]s.
///
/// A Result is only valid until the next Result has been received. To retain
/// data pull it out of the Result before moving on to the next Result.
abstract class Result {
  /// Returns the value of a column of the current result, given its
  /// (zero-based) numeric index as an `int` or its name as a [String].
  ///
  /// This may return `null`, indicating `MISSING`, if the value doesn't exist,
  /// e.g. if the column is a property that doesn't exist in the document.
  ///
  /// See:
  /// - [Query.columnName] for a discussion of column names.
  Object? operator [](Object keyOrIndex);

  /// Returns the current result as an array of column values.
  Array get array;

  /// Returns the current result as a dictionary mapping column names to values.
  Dictionary get dictionary;
}

class _ResultSetIterator extends NativeResource<CBLResultSet>
    implements Iterator<Result>, Result {
  static late final _bindings = cblBindings.resultSet;

  _ResultSetIterator(NativeObject<CBLResultSet> native) : super(native);

  var _hasMore = true;
  var _hasCurrent = false;

  @override
  Result get current => this;

  @override
  bool moveNext() {
    if (_hasMore) {
      _hasCurrent = native.call(_bindings.next);
      if (!_hasCurrent) {
        _hasMore = false;
      }
    }
    return _hasMore;
  }

  @override
  Object? operator [](Object keyOrIndex) {
    _checkHasCurrent();
    Pointer<FLValue> pointer;

    if (keyOrIndex is String) {
      pointer =
          native.call((pointer) => _bindings.valueForKey(pointer, keyOrIndex));
    } else if (keyOrIndex is int) {
      pointer =
          native.call((pointer) => _bindings.valueAtIndex(pointer, keyOrIndex));
    } else {
      throw ArgumentError.value(keyOrIndex, 'keyOrIndex');
    }

    return MRoot.fromValue(
      pointer,
      context: MContext(),
      isMutable: false,
    ).asNative;
  }

  @override
  Array get array {
    _checkHasCurrent();
    return MRoot.fromValue(
      native.call(_bindings.resultArray).cast(),
      context: MContext(),
      isMutable: false,
    ).asNative as Array;
  }

  @override
  Dictionary get dictionary {
    _checkHasCurrent();
    return MRoot.fromValue(
      native.call(_bindings.resultDict).cast(),
      context: MContext(),
      isMutable: false,
    ).asNative as Dictionary;
  }

  void _checkHasCurrent() {
    if (!_hasCurrent) {
      throw StateError(
        'ResultSet iterator is empty or its moveNext method has not been '
        'called.',
      );
    }
  }
}

/// A [ResultSet] is an iterable of the [Result]s returned by a query.
///
/// It can only be iterated __once__.
///
/// See:
/// - [Result] for how to consume a single Result.
class ResultSet extends CblObject<CBLResultSet> with IterableMixin<Result> {
  ResultSet._(
    Pointer<CBLResultSet> pointer, {
    required String? debugCreator,
  }) : super(
          pointer,
          debugName: 'ResultSet(creator: $debugCreator)',
        );

  var _consumed = false;

  @override
  Iterator<Result> get iterator {
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

  /// All the results as [Dictionary]s.
  Iterable<Dictionary> get asDictionaries => map((result) => result.dictionary);
}

extension on QueryLanguage {
  CBLQueryLanguage toCBLQueryLanguage() => CBLQueryLanguage.values[index];
}
