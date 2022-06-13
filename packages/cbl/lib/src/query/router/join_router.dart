import '../join.dart';
import '../joins.dart';
import '../query.dart';

/// Interface for creating and chaining `JOIN` clauses.
///
/// {@category Query Builder}
abstract class JoinRouter {
  /// Creates and returns a `JOIN` clause query component with the given joins.
  Joins join(
    JoinInterface join0, [
    JoinInterface? join1,
    JoinInterface? join2,
    JoinInterface? join3,
    JoinInterface? join4,
    JoinInterface? join5,
    JoinInterface? join6,
    JoinInterface? join7,
    JoinInterface? join8,
    JoinInterface? join9,
  ]);

  /// Creates and returns a query component representing many `JOIN` clauses
  /// with the given [joins].
  Joins joinAll(Iterable<JoinInterface> joins);
}

/// Version of [JoinRouter] for building [SyncQuery]s.
///
/// {@category Query Builder}
abstract class SyncJoinRouter implements JoinRouter {
  @override
  SyncJoins join(
    JoinInterface join0, [
    JoinInterface? join1,
    JoinInterface? join2,
    JoinInterface? join3,
    JoinInterface? join4,
    JoinInterface? join5,
    JoinInterface? join6,
    JoinInterface? join7,
    JoinInterface? join8,
    JoinInterface? join9,
  ]);

  @override
  SyncJoins joinAll(Iterable<JoinInterface> joins);
}

/// Version of [JoinRouter] for building [AsyncQuery]s.
///
/// {@category Query Builder}
abstract class AsyncJoinRouter implements JoinRouter {
  @override
  AsyncJoins join(
    JoinInterface join0, [
    JoinInterface? join1,
    JoinInterface? join2,
    JoinInterface? join3,
    JoinInterface? join4,
    JoinInterface? join5,
    JoinInterface? join6,
    JoinInterface? join7,
    JoinInterface? join8,
    JoinInterface? join9,
  ]);

  @override
  AsyncJoins joinAll(Iterable<JoinInterface> joins);
}
