import 'package:test/test.dart';

import '../fixtures/builtin_types.dart';
import '../fixtures/typed_data_child.dart';
import '../fixtures/typed_data_list.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('toString', () {
    expect(
      BoolListListDict([
        [true]
      ]).toString(),
      'BoolListListDict(value: [[true]])',
    );
    expect(
      BoolListListDict([
        [true]
      ]).toString(indent: '  '),
      '''
BoolListListDict(
  value: [
    [
      true,
    ],
  ],
)''',
    );
    expect(
      TypedDataPropertyDict(BoolDict(false)).toString(),
      'TypedDataPropertyDict(value: BoolDict(value: false))',
    );
    expect(
      TypedDataPropertyDict(BoolDict(false)).toString(indent: '  '),
      '''
TypedDataPropertyDict(
  value: BoolDict(
    value: false,
  ),
)''',
    );
  });
}
