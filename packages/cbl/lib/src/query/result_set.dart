import 'result.dart';

abstract class ResultSet implements Iterable<Result>, Iterator<Result> {}

abstract class ResultSetImpl implements ResultSet {
  @override
  Iterator<Result> get iterator => this;
}
