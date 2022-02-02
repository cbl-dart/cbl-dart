import 'package:cbl/cbl.dart';

class MockQuery implements Query {
  MockQuery({this.n1ql, this.jsonRepresentation});

  @override
  final String? n1ql;

  @override
  final String? jsonRepresentation;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}
