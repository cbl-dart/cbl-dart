import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DocumentChange', () {
    test('==', () {
      final database = _Database();
      final collection = _Collection();
      DocumentChange a;
      DocumentChange b;

      a = DocumentChange(database, collection, 'A');
      expect(a, a);

      b = DocumentChange(database, collection, 'A');
      expect(a, b);

      b = DocumentChange(_Database(), collection, 'B');
      expect(b, isNot(a));
    });

    test('toString', () {
      expect(
        DocumentChange(_Database(), _Collection(), 'A').toString(),
        'DocumentChange(database: _Database(), collection: _Collection(), '
        'documentId: A)',
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

class _Collection implements Collection {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_Collection()';
}
