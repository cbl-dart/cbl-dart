// ignore_for_file: avoid_unused_constructor_parameters

import '../../cbl.dart';

abstract class AsyncBuilderQuery implements AsyncQuery {
  AsyncBuilderQuery({
    AsyncBuilderQuery? query,
    Iterable<SelectResultInterface>? selects,
    bool? distinct,
    DataSourceInterface? from,
    Iterable<JoinInterface>? joins,
    ExpressionInterface? where,
    Iterable<ExpressionInterface>? groupBys,
    ExpressionInterface? having,
    Iterable<OrderingInterface>? orderings,
    ExpressionInterface? limit,
    ExpressionInterface? offset,
  });

  @override
  Parameters? parameters;

  @override
  Future<ResultSet> execute() => throw UnimplementedError();

  @override
  Future<String> explain() => throw UnimplementedError();

  @override
  Stream<ResultSet> changes() => throw UnimplementedError();

  @override
  String? get jsonRepresentation => throw UnimplementedError();

  @override
  bool get isClosed => throw UnimplementedError();
}
