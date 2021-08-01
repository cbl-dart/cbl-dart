import '../join.dart';
import '../joins.dart';

/// Interface for creating and chaining `JOIN` clauses.
abstract class JoinRouter {
  /// Creates and returns a `JOIN` clause query component with the given
  /// [join].
  Joins join(JoinInterface join);

  /// Creates and returns a query component representing many `JOIN` clauses
  /// with the given [joins].
  Joins joinMany(Iterable<JoinInterface> joins);
}
