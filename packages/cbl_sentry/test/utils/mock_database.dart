import 'package:cbl/cbl.dart';

class MockDatabase implements Database {
  MockDatabase({required this.name});

  @override
  final String name;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}
