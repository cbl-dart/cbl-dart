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
///
/// {@category Query Builder}
abstract class Select implements Query, FromRouter {}

/// Version of [Select] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncSelect implements Select, SyncQuery, SyncFromRouter {}

/// Version of [Select] for building [AsyncQuery]s.
///
/// {@category Query Builder}
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
  Future<void> performClose() => throw UnimplementedError();
}

class SyncSelectImpl extends SyncBuilderQuery implements SyncSelect {
  SyncSelectImpl(
    Iterable<SelectResultInterface> select, {
    required bool distinct,
  }) : super(selects: select, distinct: distinct);

  @override
  SyncFrom from(DataSourceInterface dataSource) {
    _assertDataSourceDatabaseType<SyncDatabase>(dataSource, 'Sync', 'Async');
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
    _assertDataSourceDatabaseType<AsyncDatabase>(dataSource, 'Async', 'Sync');
    return AsyncFromImpl(query: this, from: dataSource);
  }
}

void _assertDataSourceDatabaseType<T>(
  DataSourceInterface dataSource,
  String expectedStyle,
  String actualStyle,
) {
  if ((dataSource as DataSourceImpl).database is! T) {
    throw ArgumentError(
      '${expectedStyle}QueryBuilder must be used with an '
      '${expectedStyle}Database. To build a query for a ${actualStyle}Database '
      'use ${actualStyle}QueryBuilder.',
    );
  }
}
