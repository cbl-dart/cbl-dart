import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DatabaseChange', () {
    test('==', () {
      final database = _Database();
      DatabaseChange a;
      DatabaseChange b;

      a = DatabaseChange(database, ['A']);
      expect(a, a);

      b = DatabaseChange(database, ['A']);
      expect(a, b);

      b = DatabaseChange(_Database(), ['B']);
      expect(b, isNot(a));
    });

    test('toString', () {
      expect(
        DatabaseChange(_Database(), ['A']).toString(),
        'DatabaseChange(database: _Database(), documentIds: [A])',
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
