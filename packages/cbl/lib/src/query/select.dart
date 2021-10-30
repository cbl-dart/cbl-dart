import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/database.dart';
import '../support/listener_token.dart';
import 'data_source.dart';
import 'ffi_query.dart';
import 'from.dart';
import 'parameters.dart';
import 'proxy_query.dart';
import 'query.dart';
import 'query_builder.dart';
import 'query_change.dart';
import 'result_set.dart';
import 'router/from_router.dart';
import 'select_result.dart';

/// A query component representing the `SELECT` clause of a [Query].
abstract class Select implements Query, FromRouter {}

/// Version of [Select] for building [SyncQuery]s.
abstract class SyncSelect implements Select, SyncQuery, SyncFromRouter {}

/// Version of [Select] for building [AsyncQuery]s.
abstract class AsyncSelect implements Select, AsyncQuery, AsyncFromRouter {}

// === Impl ====================================================================

class SelectImpl extends QueryBase with BuilderQueryMixin implements Select {
  SelectImpl(
    Iterable<SelectResultInterface> select, {
    required bool distinct,
  }) : super(
          typeName: 'SelectImpl',
          debugCreator: 'SelectImpl()',
          language: CBLQueryLanguage.json,
        ) {
    initBuilderQuery(
      selects: select,
      distinct: distinct,
    );
  }

  @override
  From from(DataSourceInterface dataSource) {
    final database = (dataSource as DataSourceImpl).database;

    if (database is SyncDatabase) {
      return SyncFromImpl(query: this, from: dataSource);
    }

    if (database is AsyncDatabase) {
      return AsyncFromImpl(query: this, from: dataSource);
    }

    throw UnimplementedError();
  }

  @override
  Parameters? get parameters => throw UnimplementedError();

  @override
  FutureOr<void> setParameters(Parameters? value) =>
      useSync(() => throw UnimplementedError());

  @override
  FutureOr<ResultSet> execute() => useSync(() => throw UnimplementedError());

  @override
  FutureOr<String> explain() => useSync(() => throw UnimplementedError());

  @override
  FutureOr<ListenerToken> addChangeListener(QueryChangeListener listener) =>
      useSync(() => throw UnimplementedError());

  @override
  FutureOr<void> removeChangeListener(ListenerToken token) =>
      useSync(() => throw UnimplementedError());

  @override
  Stream<QueryChange> changes() => useSync(() => throw UnimplementedError());

  @override
  FutureOr<void> performPrepare() => throw UnimplementedError();

  @override
  Future<void> finalize() => throw UnimplementedError();
}

class SyncSelectImpl extends SyncBuilderQuery implements SyncSelect {
  SyncSelectImpl(
    Iterable<SelectResultInterface> select, {
    required bool distinct,
  }) : super(selects: select, distinct: distinct);

  @override
  SyncFrom from(DataSourceInterface dataSource) {
    if ((dataSource as DataSourceImpl).database is! SyncDatabase) {
      throw ArgumentError(
        '`SyncQueryBuilder` must be used with a `SyncDatabase`. '
        'To build a query for an `AsyncDatabase` use `AsyncQueryBuilder`.',
      );
    }

    return SyncFromImpl(query: this, from: dataSource);
  }
}

class AsyncSelectImpl extends AsyncBuilderQuery implements AsyncSelect {
  AsyncSelectImpl(
    Iterable<SelectResultInterface> select, {
    required bool distinct,
  }) : super(selects: select, distinct: distinct);

  @override
  AsyncFrom from(DataSourceInterface dataSource) {
    if ((dataSource as DataSourceImpl).database is! AsyncDatabase) {
      throw ArgumentError(
        '`AsyncQueryBuilder` must be used with an `AsyncDatabase`. '
        'To build a query for a `SyncDatabase` use `SyncQueryBuilder`.',
      );
    }

    return AsyncFromImpl(query: this, from: dataSource);
  }
}
