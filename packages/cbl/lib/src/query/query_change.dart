import 'package:meta/meta.dart';

import '../query.dart';
import 'query.dart';

/// A [Query] change event.
@immutable
class QueryChange<R extends ResultSet> {
  /// Creates a [Query] change event.
  const QueryChange(this.query, this.results);

  /// The query that changed.
  final Query query;

  /// The new query results.
  final R results;

  @override
  String toString() => 'QueryChange(query: $query)';
}
