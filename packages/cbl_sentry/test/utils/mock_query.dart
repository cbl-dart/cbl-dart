import 'package:cbl/cbl.dart';

class MockQuery implements Query {
  MockQuery({this.sqlRepresentation, this.jsonRepresentation});

  @override
  final String? sqlRepresentation;

  @override
  final String? jsonRepresentation;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}
