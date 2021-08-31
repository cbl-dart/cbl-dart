import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../fixtures/values.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Parameters', () {
    test('create with initial parameters', () {
      final parameters = Parameters({'a': true});
      expect(parameters.value('a'), isTrue);
    });

    test('set parameters', () {
      final parameters = Parameters();

      // ignore: cascade_invocations
      parameters.setValue('x', name: 'value');
      expect(parameters.value('value'), 'x');

      parameters.setValue('a', name: 'string');
      expect(parameters.value('string'), 'a');

      parameters.setInteger(1, name: 'int');
      expect(parameters.value('int'), 1);

      parameters.setFloat(.2, name: 'float');
      expect(parameters.value('float'), .2);

      parameters.setNumber(3, name: 'number');
      expect(parameters.value('number'), 3);

      parameters.setBoolean(true, name: 'boolean');
      expect(parameters.value('boolean'), true);

      parameters.setDate(testDate, name: 'date');
      expect(parameters.value('date'), testDate.toIso8601String());

      parameters.setBlob(testBlob, name: 'blob');
      expect(parameters.value('blob'), testBlob);

      parameters.setArray(MutableArray([true]), name: 'array');
      expect(parameters.value('array'), MutableArray([true]));

      parameters.setDictionary(
        MutableDictionary({'key': 'value'}),
        name: 'dictionary',
      );
      expect(
        parameters.value('dictionary'),
        MutableDictionary({'key': 'value'}),
      );
    });

    test('==', () {
      Parameters a;
      Parameters b;

      a = Parameters();
      expect(a, a);

      b = Parameters();
      expect(a, b);

      b = Parameters({'a': true});
      expect(a, isNot(b));
    });

    test('hashCode', () {
      Parameters a;
      Parameters b;

      a = Parameters();
      expect(a.hashCode, a.hashCode);

      b = Parameters();
      expect(a.hashCode, b.hashCode);

      b = Parameters({'a': true});
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('toString', () {
      expect(
        Parameters({'a': 'b'}).toString(),
        r'Parameters($a: b)',
      );
    });
  });
}
