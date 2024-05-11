import '../expressions/expression.dart';
import '../query.dart';
import '../where.dart';

/// Interface for creating and chaining `WHERE` clauses.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract interface class WhereRouter {
  /// Creates and returns a `WHERE` clause query component with the given
  /// [expression].
  Where where(ExpressionInterface expression);
}

/// Version of [WhereRouter] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract interface class SyncWhereRouter implements WhereRouter {
  @override
  SyncWhere where(ExpressionInterface expression);
}

/// Version of [WhereRouter] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract interface class AsyncWhereRouter implements WhereRouter {
  @override
  AsyncWhere where(ExpressionInterface expression);
}
