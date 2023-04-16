// ignore_for_file: invalid_use_of_internal_member

import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/typed_property.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('custom data name', () {
    expect(
      (CustomDataNameDict(true).internal as Dictionary).value('custom'),
      isTrue,
    );
    expect(
      ImmutableCustomDataNameDict.internal(MutableDictionary({'custom': true}))
          .value,
      isTrue,
    );
  });

  test('default value', () {
    expect(DefaultValueDict().value, isTrue);
    // ignore: avoid_redundant_argument_values
    expect(DefaultValueDict(true).value, isTrue);
    expect(DefaultValueDict(false).value, isFalse);
  });

  test('converter', () {
    expect(
      ScalarConverterDict(Uri.parse('http://example.com')).value,
      Uri.parse('http://example.com'),
    );
  });
}
