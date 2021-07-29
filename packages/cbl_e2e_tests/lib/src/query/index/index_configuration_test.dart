import 'package:cbl/cbl.dart';

import '../../../test_binding_impl.dart';
import '../../test_binding.dart';

void main() {
  setupTestBinding();

  group('ValueIndexConfiguration', () {
    test('throws when expressions is empty', () {
      expect(() => ValueIndexConfiguration([]), throwsArgumentError);
      expect(
        () => ValueIndexConfiguration(['a']).expressions = [],
        throwsArgumentError,
      );
    });

    test('==', () {
      ValueIndexConfiguration a;
      ValueIndexConfiguration b;

      a = ValueIndexConfiguration(['a']);
      expect(a, a);

      b = ValueIndexConfiguration(['a']);
      expect(a, b);

      b = ValueIndexConfiguration(['b']);
      expect(a, isNot(b));
    });

    test('hashCode', () {
      ValueIndexConfiguration a;
      ValueIndexConfiguration b;

      a = ValueIndexConfiguration(['a']);
      expect(a.hashCode, a.hashCode);

      b = ValueIndexConfiguration(['a']);
      expect(a.hashCode, b.hashCode);

      b = ValueIndexConfiguration(['b']);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('toString', () {
      expect(
        ValueIndexConfiguration(['a', 'b']).toString(),
        'ValueIndexConfiguration(a, b)',
      );
    });
  });

  group('FullTextIndexConfiguration', () {
    test('default values', () {
      final index = FullTextIndexConfiguration(['a']);
      expect(index.ignoreAccents, isFalse);
      expect(index.language, isNull);
    });

    test('update', () {
      final index = FullTextIndexConfiguration(
        ['a'],
        ignoreAccents: true,
        language: FullTextLanguage.english,
      );
      expect(index.expressions, ['a']);
      index.expressions = ['b'];
      expect(index.expressions, ['b']);

      expect(index.ignoreAccents, isTrue);
      index.ignoreAccents = false;
      expect(index.ignoreAccents, isFalse);

      expect(index.language, FullTextLanguage.english);
      index.language = null;
      expect(index.language, isNull);
    });

    test('throws when expressions is empty', () {
      expect(() => FullTextIndexConfiguration([]), throwsArgumentError);
      expect(
        () => FullTextIndexConfiguration(['a']).expressions = [],
        throwsArgumentError,
      );
    });

    test('==', () {
      FullTextIndexConfiguration a;
      FullTextIndexConfiguration b;

      a = FullTextIndexConfiguration(
        ['a'],
        ignoreAccents: true,
        language: FullTextLanguage.english,
      );
      expect(a, a);

      b = FullTextIndexConfiguration(
        ['a'],
        ignoreAccents: true,
        language: FullTextLanguage.english,
      );
      expect(a, b);

      b = FullTextIndexConfiguration(
        ['b'],
        ignoreAccents: false,
        language: FullTextLanguage.french,
      );
      expect(a, isNot(b));
    });

    test('hashCode', () {
      FullTextIndexConfiguration a;
      FullTextIndexConfiguration b;

      a = FullTextIndexConfiguration(
        ['a'],
        ignoreAccents: true,
        language: FullTextLanguage.english,
      );
      expect(a.hashCode, a.hashCode);

      b = FullTextIndexConfiguration(
        ['a'],
        ignoreAccents: true,
        language: FullTextLanguage.english,
      );
      expect(a.hashCode, b.hashCode);

      b = FullTextIndexConfiguration(
        ['b'],
        ignoreAccents: false,
        language: FullTextLanguage.french,
      );
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('toString', () {
      expect(
        FullTextIndexConfiguration(['a', 'b']).toString(),
        'FullTextIndexConfiguration(a, b)',
      );

      expect(
        FullTextIndexConfiguration(['a', 'b'], ignoreAccents: true).toString(),
        'FullTextIndexConfiguration(a, b | IGNORE-ACCENTS)',
      );

      expect(
        FullTextIndexConfiguration(
          ['a', 'b'],
          ignoreAccents: true,
          language: FullTextLanguage.english,
        ).toString(),
        'FullTextIndexConfiguration(a, b | IGNORE-ACCENTS, language: english)',
      );
    });
  });
}
