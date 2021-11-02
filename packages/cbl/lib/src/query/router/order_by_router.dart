import '../order_by.dart';
import '../ordering.dart';
import '../query.dart';

/// Interface for creating and chaining `ORDER BY` clauses.
///
/// {@category Query Builder}
abstract class OrderByRouter {
  /// Creates and returns a `ORDER BY` clause query component with the given
  /// orderings.
  OrderBy orderBy(
    OrderingInterface ordering0, [
    OrderingInterface? ordering1,
    OrderingInterface? ordering2,
    OrderingInterface? ordering3,
    OrderingInterface? ordering4,
    OrderingInterface? ordering5,
    OrderingInterface? ordering6,
    OrderingInterface? ordering7,
    OrderingInterface? ordering8,
    OrderingInterface? ordering9,
  ]);

  /// Creates and returns a `ORDER BY` clause query component with the given
  /// [orderings].
  OrderBy orderByAll(Iterable<OrderingInterface> orderings);
}

/// Version of [OrderByRouter] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncOrderByRouter implements OrderByRouter {
  @override
  SyncOrderBy orderBy(
    OrderingInterface ordering0, [
    OrderingInterface? ordering1,
    OrderingInterface? ordering2,
    OrderingInterface? ordering3,
    OrderingInterface? ordering4,
    OrderingInterface? ordering5,
    OrderingInterface? ordering6,
    OrderingInterface? ordering7,
    OrderingInterface? ordering8,
    OrderingInterface? ordering9,
  ]);

  @override
  SyncOrderBy orderByAll(Iterable<OrderingInterface> orderings);
}

/// Version of [OrderByRouter] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncOrderByRouter implements OrderByRouter {
  @override
  AsyncOrderBy orderBy(
    OrderingInterface ordering0, [
    OrderingInterface? ordering1,
    OrderingInterface? ordering2,
    OrderingInterface? ordering3,
    OrderingInterface? ordering4,
    OrderingInterface? ordering5,
    OrderingInterface? ordering6,
    OrderingInterface? ordering7,
    OrderingInterface? ordering8,
    OrderingInterface? ordering9,
  ]);

  @override
  AsyncOrderBy orderByAll(Iterable<OrderingInterface> orderings);
}
