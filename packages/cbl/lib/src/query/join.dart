import 'data_source.dart';
import 'expressions/expression.dart';
import 'query.dart';

/// Represent a `JOIN` clause in a [Query].
///
/// {@category Query Builder}
abstract class JoinInterface {}

/// Represents the `ON` clause of `JOIN` clause.
///
/// {@category Query Builder}
// ignore: one_member_abstracts
abstract class JoinOnInterface {
  /// Specifies the given [expression] as the join condition.
  JoinInterface on(ExpressionInterface expression);
}

/// Factory for creating `JOIN` clauses.
///
/// {@category Query Builder}
class Join {
  Join._();

  /// Creates a `JOIN` with the given [dataSource].
  ///
  /// This is the same as an `INNER JOIN`.
  static JoinOnInterface join(DataSourceInterface dataSource) =>
      JoinOnImpl(type: JoinType.inner, dataSource: dataSource);

  /// Creates a `LEFT JOIN` with the given [dataSource].
  ///
  /// This is the same as an `LEFT OUTER JOIN`.
  static JoinOnInterface leftJoin(DataSourceInterface dataSource) =>
      JoinOnImpl(type: JoinType.leftOuter, dataSource: dataSource);

  /// Creates a `LEFT OUTER JOIN` with the given [dataSource].
  static JoinOnInterface leftOuterJoin(DataSourceInterface dataSource) =>
      JoinOnImpl(type: JoinType.leftOuter, dataSource: dataSource);

  /// Creates an `INNER JOIN` with the given [dataSource].
  static JoinOnInterface innerJoin(DataSourceInterface dataSource) =>
      JoinOnImpl(type: JoinType.inner, dataSource: dataSource);

  /// Creates an `CROSS JOIN` with the given [dataSource].
  static JoinInterface crossJoin(DataSourceInterface dataSource) =>
      JoinImpl(dataSource: dataSource);
}

// === Impl ====================================================================

enum JoinType {
  leftOuter,
  inner,
}

class JoinOnImpl implements JoinOnInterface {
  JoinOnImpl({
    JoinType? type,
    required DataSourceInterface dataSource,
  })  : _type = type,
        _dataSource = dataSource as DataSourceImpl;

  final JoinType? _type;
  final DataSourceImpl _dataSource;

  @override
  JoinInterface on(ExpressionInterface expression) =>
      JoinImpl(type: _type, dataSource: _dataSource, on: expression);
}

class JoinImpl implements JoinInterface {
  JoinImpl({
    JoinType? type,
    required DataSourceInterface dataSource,
    ExpressionInterface? on,
  })  : _type = type,
        _dataSource = dataSource as DataSourceImpl,
        _on = on as ExpressionImpl?;

  final JoinType? _type;
  final DataSourceImpl _dataSource;
  final ExpressionImpl? _on;

  Map<String, Object?> toJson() {
    String join;
    switch (_type) {
      case null:
        join = 'CROSS';
        break;
      case JoinType.leftOuter:
        join = 'LEFT OUTER';
        break;
      case JoinType.inner:
        join = 'INNER';
        break;
    }

    return {
      ..._dataSource.toJson(),
      'JOIN': join,
      if (_on != null) 'ON': _on!.toJson(),
    };
  }
}
