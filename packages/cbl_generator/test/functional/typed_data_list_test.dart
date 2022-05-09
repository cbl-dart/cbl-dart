import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/typed_data_list.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('get list', () {
    expect(
      ImmutableBoolListDict.internal(MutableDictionary({
        'value': [true]
      })).value,
      [true],
    );
    expect(
      ImmutableOptionalBoolListDict.internal(MutableDictionary({
        'value': [true]
      })).value,
      [true],
    );
    expect(
      ImmutableOptionalBoolListDict.internal(MutableDictionary({'value': null}))
          .value,
      null,
    );
    expect(MutableBoolListDict([true]).value, [true]);
    expect(MutableOptionalBoolListDict([true]).value, [true]);
    expect(MutableOptionalBoolListDict(null).value, null);
  });

  test('set list', () {
    final dartList = [false];
    final immutableList = ImmutableBoolListDict.internal(MutableDictionary({
      'value': [false]
    })).value;
    final mutableList = MutableBoolListDict([false]).value;

    expect(
      (MutableBoolListDict([true])..value = dartList).value,
      [false],
    );
    expect(
      (MutableOptionalBoolListDict([true])..value = dartList).value,
      [false],
    );
    expect(
      (MutableOptionalBoolListDict(null)..value = dartList).value,
      [false],
    );
    expect(
      (MutableBoolListDict([true])..value = immutableList).value,
      [false],
    );
    expect(
      (MutableOptionalBoolListDict([true])..value = immutableList).value,
      [false],
    );
    expect(
      (MutableOptionalBoolListDict(null)..value = immutableList).value,
      [false],
    );
    expect(
      (MutableBoolListDict([true])..value = mutableList).value,
      [false],
    );
    expect(
      (MutableOptionalBoolListDict([true])..value = mutableList).value,
      [false],
    );
    expect(
      (MutableOptionalBoolListDict(null)..value = mutableList).value,
      [false],
    );
  });

  test('nested list', () {
    expect(
      ImmutableBoolListListDict.internal(MutableDictionary({
        'value': <Object>[],
      })).value,
      isEmpty,
    );
    expect(
      ImmutableBoolListListDict.internal(MutableDictionary({
        'value': [<Object>[]],
      })).value.first,
      isEmpty,
    );
    expect(
      ImmutableBoolListListDict.internal(MutableDictionary({
        'value': [
          [true]
        ],
      })).value.first,
      [true],
    );
    expect(MutableBoolListListDict([]).value, isEmpty);
    expect(MutableBoolListListDict([[]]).value.first, isEmpty);
    expect(
      MutableBoolListListDict([
        [true]
      ]).value.first,
      [true],
    );
    expect((MutableBoolListListDict([])..value = []).value, isEmpty);
    expect((MutableBoolListListDict([])..value = [[]]).value.first, isEmpty);
    expect(
      (MutableBoolListListDict([])
            ..value = [
              [true]
            ])
          .value
          .first,
      [true],
    );
  });
}
