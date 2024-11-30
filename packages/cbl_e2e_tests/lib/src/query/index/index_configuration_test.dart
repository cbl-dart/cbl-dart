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

  group('VectorEncoding', () {
    test('==', () {
      expect(VectorEncoding.none(), VectorEncoding.none());
      expect(
        VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit),
        VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit),
      );
      expect(
        VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1),
        VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1),
      );

      expect(
        VectorEncoding.none(),
        isNot(VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit)),
      );
      expect(
        VectorEncoding.none(),
        isNot(VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1)),
      );
    });

    test('hashCode', () {
      expect(VectorEncoding.none().hashCode, VectorEncoding.none().hashCode);
      expect(
        VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit).hashCode,
        VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit).hashCode,
      );
      expect(
        VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1).hashCode,
        VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1).hashCode,
      );

      expect(
        VectorEncoding.none().hashCode,
        isNot(VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit)
            .hashCode),
      );
      expect(
        VectorEncoding.none().hashCode,
        isNot(VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1)
            .hashCode),
      );
    });

    test('toString', () {
      expect(VectorEncoding.none().toString(), 'VectorEncoding.none()');
      expect(
        VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit).toString(),
        'VectorEncoding.scalarQuantizer(eightBit)',
      );
      expect(
        VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1).toString(),
        'VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1)',
      );
    });
  });

  group('VectorIndexConfiguration', () {
    test('default values', () {
      final index = VectorIndexConfiguration('a', dimensions: 2, centroids: 3);
      expect(index.lazy, isFalse);
      expect(
        index.encoding,
        VectorEncoding.scalarQuantizer(ScalarQuantizerType.eightBit),
      );
      expect(index.metric, DistanceMetric.euclideanSquared);
      expect(index.minTrainingSize, isNull);
      expect(index.maxTrainingSize, isNull);
      expect(index.numProbes, isNull);
    });

    test('update', () {
      final index = VectorIndexConfiguration('a', dimensions: 2, centroids: 3);
      expect(index.expression, 'a');
      expect(index.expressions, ['a']);
      index.expressions = ['b'];
      expect(index.expression, 'b');
      expect(index.expressions, ['b']);
    });

    test('==', () {
      VectorIndexConfiguration a;
      VectorIndexConfiguration b;

      a = VectorIndexConfiguration('a', dimensions: 2, centroids: 3);
      expect(a, a);

      b = VectorIndexConfiguration('a', dimensions: 2, centroids: 3);
      expect(a, b);

      b = VectorIndexConfiguration('b', dimensions: 2, centroids: 3);
      expect(a, isNot(b));
    });

    test('hashCode', () {
      VectorIndexConfiguration a;
      VectorIndexConfiguration b;

      a = VectorIndexConfiguration('a', dimensions: 2, centroids: 3);
      expect(a.hashCode, a.hashCode);

      b = VectorIndexConfiguration('a', dimensions: 2, centroids: 3);
      expect(a.hashCode, b.hashCode);

      b = VectorIndexConfiguration('b', dimensions: 2, centroids: 3);
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('toString', () {
      expect(
        VectorIndexConfiguration('a', dimensions: 2, centroids: 3).toString(),
        'VectorIndexConfiguration(a | '
        'dimensions: 2, '
        'centroids: 3, '
        'encoding: VectorEncoding.scalarQuantizer(eightBit), '
        'metric: euclideanSquared)',
      );

      expect(
        VectorIndexConfiguration(
          'a',
          dimensions: 2,
          centroids: 3,
          lazy: true,
          encoding: VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1),
          metric: DistanceMetric.euclidean,
          minTrainingSize: 4,
          maxTrainingSize: 5,
          numProbes: 6,
        ).toString(),
        'VectorIndexConfiguration(a | '
        'dimensions: 2, '
        'centroids: 3, '
        'LAZY, '
        'encoding: VectorEncoding.productQuantizer(subQuantizers: 1, bits: 1), '
        'metric: euclidean, '
        'minTrainingSize: 4, '
        'maxTrainingSize: 5, '
        'numProbes: 6)',
      );
    });
  });
}
