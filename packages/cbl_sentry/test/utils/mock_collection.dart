import 'package:cbl/cbl.dart';

class MockCollection implements Collection {
  MockCollection({required this.name});

  @override
  final String name;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError();
  }
}
