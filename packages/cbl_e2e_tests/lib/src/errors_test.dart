import 'package:cbl/cbl.dart';

import '../test_binding_impl.dart';
import 'test_binding.dart';

void main() {
  setupTestBinding();

  group('DatabaseException', () {
    group('toString', () {
      test('highlight errorPosition', () {
        final exception = DatabaseException(
          'a',
          DatabaseErrorCode.invalidQuery,
          queryString: 'b',
          errorPosition: 0,
        );
        expect(
          exception.toString(),
          'DatabaseException(a, code: invalidQuery)\nb\n^\n',
        );
      });

      test('handle negative errorPosition', () {
        final exception = DatabaseException(
          'a',
          DatabaseErrorCode.invalidQuery,
          queryString: 'b',
          errorPosition: -1,
        );
        expect(
          exception.toString(),
          'DatabaseException(a, code: invalidQuery)\nb',
        );
      });
    });
  });
}
