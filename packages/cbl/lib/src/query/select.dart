import '../database/database.dart';
import '../query.dart';
import 'data_source.dart';
import 'from.dart';
import 'query.dart';
import 'router/from_router.dart';
import 'select_result.dart';

/// A query component representing the `SELECT` clause of a [Query].
abstract class Select implements Query, FromRouter {}

/// Version of [Select] for building [SyncQuery]s.
abstract class SyncSelect implements Select, SyncQuery, SyncFromRouter {}

/// Version of [Select] for building [AsyncQuery]s.
abstract class AsyncSelect implements Select, AsyncQuery, AsyncFromRouter {}

// === Impl ====================================================================

class SyncSelectImpl extends SyncBuilderQuery implements SyncSelect {
  SyncSelectImpl(Iterable<SelectResultInterface> select, bool distinct)
      : super(selects: select, distinct: distinct);

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
  AsyncSelectImpl(Iterable<SelectResultInterface> select, bool distinct)
      : super(selects: select, distinct: distinct);

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
