import 'package:cbl/src/support/utils.dart';
import 'package:test/test.dart';

void main() {
  group('redact', () {
    test('empty string', () {
      expect(redact(''), '');
    });

    test('1 character', () {
      expect(redact('a'), '*');
    });

    test('3 character', () {
      expect(redact('abc'), '***');
    });

    test('4 character', () {
      expect(redact('abcd'), '***d');
    });

    test('6 character', () {
      expect(redact('abcdef'), '***def');
    });

    test('7 character', () {
      expect(redact('abcdefg'), '****efg');
    });
  });
}
