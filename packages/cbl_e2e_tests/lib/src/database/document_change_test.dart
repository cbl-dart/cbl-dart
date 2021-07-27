import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DocumentChange', () {
    test('==', () {
      final database = _Database();
      DocumentChange a;
      DocumentChange b;

      a = DocumentChange(database, 'A');
      expect(a, a);

      b = DocumentChange(database, 'A');
      expect(a, b);

      b = DocumentChange(_Database(), 'B');
      expect(b, isNot(a));
    });

    test('toString', () {
      expect(
        DocumentChange(_Database(), 'A').toString(),
        'DocumentChange(database: _Database(), documentId: A)',
      );
    });
  });
}

class _Database implements Database {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_Database()';
}
