import 'expressions/expression.dart';
import 'ffi_query.dart';
import 'proxy_query.dart';
import 'query.dart';

/// A query component representing the `LIMIT` clause of a [Query].
///
/// {@category Query Builder}
abstract class Limit implements Query {}

/// Version of [Limit] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncLimit implements Limit, SyncQuery {}

/// Version of [Limit] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncLimit implements Limit, AsyncQuery {}

// === Impl ====================================================================

class SyncLimitImpl extends SyncBuilderQuery implements SyncLimit {
  SyncLimitImpl({
    required SyncBuilderQuery super.query,
    required ExpressionInterface super.limit,
    super.offset,
  });
}

class AsyncLimitImpl extends AsyncBuilderQuery implements AsyncLimit {
  AsyncLimitImpl({
    required AsyncBuilderQuery super.query,
    required ExpressionInterface super.limit,
    super.offset,
  });
}
