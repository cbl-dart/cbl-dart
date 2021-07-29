import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../database/database.dart';
import '../fleece/fleece.dart' as fl;
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'parameters.dart';
import 'result.dart';
import 'result_set.dart';

/// A [Database] query.
abstract class Query {
  /// Creates a [Database] query from an N1QL [query].
  factory Query(Database database, String query) =>
      QueryImpl(database, query, debugCreator: 'Query()');

  /// Creates a [Database] query from a JSON representation of the query.
  factory Query.fromJsonRepresentation(Database database, String json) =>
      QueryImpl.fromJsonRepresentation(
        database,
        json,
        debugCreator: 'Query.fromJsonRepresentation()',
      );

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
  /// Returns a [ResultSet] that iterates over [Result] rows one at a time.
  /// You can run the query any number of times, and you can have multiple
  /// [ResultSet]s active at once.
  ///
  /// The results come from a snapshot of the database taken at the moment
  /// [execute] is called, so they will not reflect any changes made to the
  /// database afterwards.
  ResultSet execute();

  /// Returns a string describing the implementation of the compiled query.
  ///
  /// This is intended to be read by a developer for purposes of optimizing the
  /// query, especially to add database indexes. It's not machine-readable and
  /// its format may change.
  ///
  /// As currently implemented, the result has three sections, separated by
  /// newline characters:
  /// * The first section is this query compiled into an SQLite query.
  /// * The second section is the output of SQLite's "EXPLAIN QUERY PLAN"
  ///   command applied to that query; for help interpreting this, see
  ///   https://www.sqlite.org/eqp.html . The most important thing to know is
  ///   that if you see "SCAN TABLE", it means that SQLite is doing a slow
  ///   linear scan of the documents instead of using an index.
  /// * The third sections is this queries JSON representation. This is the data
  ///   structure that is built by the the query to describe this query
  ///   builder or when a N1QL query is compiled.
  String explain();

  /// Returns a [Stream] of [ResultSet]s which emits when the [ResultSet] of
  /// this query changes.
  Stream<ResultSet> changes();
}

// === Impl ====================================================================

late final _bindings = cblBindings.query;

class QueryImpl extends CblObject<CBLQuery>
    with DelegatingResourceMixin
    implements Query {
  QueryImpl(Database database, String query, {required String debugCreator})
      : this._(
          database: database as DatabaseImpl,
          language: CBLQueryLanguage.n1ql,
          query: _normalizeN1qlQuery(query),
          debugCreator: debugCreator,
        );

  /// Creates a [Database] query from a JSON representation of the query.
  QueryImpl.fromJsonRepresentation(
    Database database,
    String json, {
    required String debugCreator,
  }) : this._(
          database: database as DatabaseImpl,
          language: CBLQueryLanguage.json,
          query: json,
          debugCreator: debugCreator,
        );

  QueryImpl._({
    required DatabaseImpl database,
    required CBLQueryLanguage language,
    required String query,
    required String? debugCreator,
  })  : _database = database,
        _language = language,
        _query = query,
        super(
          database.native.call((pointer) => _bindings.create(
                pointer,
                language,
                query,
              )),
          debugName: 'Query(creator: $debugCreator)',
        ) {
    database.registerChildResource(this);
  }

  final DatabaseImpl _database;
  final CBLQueryLanguage _language;
  final String _query;
  late final _columnNames = _getColumnNames();

  @override
  Parameters? get parameters => _parameters;
  ParametersImpl? _parameters;

  @override
  set parameters(Parameters? value) {
    if (value == null) {
      _parameters = null;
    } else {
      _parameters = ParametersImpl.from(value, readonly: true);
    }
    _applyParameters();
  }

  @override
  ResultSet execute() => useSync(() => ResultSetImpl(
        native.call(_bindings.execute),
        database: _database,
        columnNames: _columnNames,
        debugCreator: 'Query.execute()',
      ));

  @override
  String explain() => useSync(() => native.call(_bindings.explain));

  @override
  Stream<ResultSet> changes() => useSync(
      () => CallbackStreamController<ResultSet, Pointer<CBLListenerToken>>(
            parent: this,
            startStream: (callback) => _bindings.addChangeListener(
              native.pointer,
              callback.native.pointer,
            ),
            createEvent: (listenerToken, _) => ResultSetImpl(
              native.call((pointer) {
                // The native side sends no arguments. When the native side
                // notfies the listener it has to copy the current query
                // result set.
                return _bindings.copyCurrentResults(pointer, listenerToken);
              }),
              database: _database,
              columnNames: _columnNames,
              debugCreator: 'Query.changes()',
            ),
          ).stream);

  void _applyParameters() {
    final encoder = fl.FleeceEncoder();
    final parameters = _parameters;
    if (parameters != null) {
      final result = parameters.encodeTo(encoder);
      assert(result is! Future);
    } else {
      encoder.beginDict(0);
      encoder.endDict();
    }
    final data = encoder.finish();
    final doc = fl.Doc.fromResultData(data, FLTrust.trusted);
    final flDict = doc.root.asDict!;
    runNativeCalls(() => _bindings.setParameters(
          native.pointer,
          flDict.native.pointer.cast(),
        ));
  }

  List<String> _getColumnNames() =>
      List.generate(native.call(_bindings.columnCount), (index) {
        return native.call((pointer) => _bindings.columnName(pointer, index));
      });

  @override
  String toString() => 'Query(${describeEnum(_language)}: $_query)';
}

String _normalizeN1qlQuery(String query) => query
    // Collapse whitespace.
    .replaceAll(RegExp(r'\s+'), ' ');
