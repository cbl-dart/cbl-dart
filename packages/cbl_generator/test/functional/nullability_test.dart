import 'package:test/test.dart';

import '../fixtures/builtin_types.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('fields of primitive types return null when set to null', () {
    expect(NullableIntDict(null).value, isNull);
    expect(NullableDoubleDict(null).value, isNull);
    expect(NullableNumDict(null).value, isNull);
    expect(NullableBoolDict(null).value, isNull);
  });

  group('nullable field', () {
    test('constructor does not create entry in data for null value', () {
      final dict = MutableNullableIntDict(null);
      expect(dict.internal, isNot(contains('value')));
    });

    test('setter does not create entry in data for null value', () {
      final dict = MutableNullableIntDict(null)..value = null;
      expect(dict.internal, isNot(contains('value')));
    });

    test('setter removes existing entry in data for null value', () {
      final dict = MutableNullableIntDict(0);
      expect(dict.internal, contains('value'));
      dict.value = null;
      expect(dict.internal, isNot(contains('value')));
    });
  });
}
