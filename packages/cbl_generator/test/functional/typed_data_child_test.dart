import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/builtin_types.dart';
import '../fixtures/typed_data_child.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('immutable object', () {
    final internalDict = MutableDictionary({
      'value': {'value': true}
    });
    final internalDoc = MutableDocument({
      'value': {'value': true}
    });
    expect(
      ImmutableTypedDataPropertyDict.internal(internalDict).value.value,
      isTrue,
    );
    expect(
      ImmutableTypedDataPropertyDoc.internal(internalDoc).value.value,
      isTrue,
    );
    expect(
      ImmutableOptionalTypedDataPropertyDict.internal(internalDict)
          .value
          ?.value,
      isTrue,
    );
    expect(
      ImmutableOptionalTypedDataPropertyDoc.internal(internalDoc).value?.value,
      isTrue,
    );
    expect(
      ImmutableOptionalTypedDataPropertyDict.internal(
        MutableDictionary({'value': null}),
      ).value,
      isNull,
    );
    expect(
      ImmutableOptionalTypedDataPropertyDoc.internal(
        MutableDocument({'value': null}),
      ).value,
      isNull,
    );
  });

  test('lazy mutable object', () {
    final internalDict = MutableDictionary({
      'value': {'value': true}
    });
    final internalDoc = MutableDocument({
      'value': {'value': true}
    });
    expect(
      MutableTypedDataPropertyDict.internal(internalDict).value.value,
      isTrue,
    );
    expect(
      MutableTypedDataPropertyDoc.internal(internalDoc).value.value,
      isTrue,
    );
    expect(
      MutableOptionalTypedDataPropertyDict.internal(internalDict).value?.value,
      isTrue,
    );
    expect(
      MutableOptionalTypedDataPropertyDoc.internal(internalDoc).value?.value,
      isTrue,
    );
    expect(
      MutableOptionalTypedDataPropertyDict.internal(
        MutableDictionary({'value': null}),
      ).value,
      isNull,
    );
    expect(
      MutableOptionalTypedDataPropertyDoc.internal(
        MutableDocument({'value': null}),
      ).value,
      isNull,
    );
  });

  test('new mutable object', () {
    final child = BoolDict(true);
    expect(MutableTypedDataPropertyDict(child).value, child);
    expect(MutableTypedDataPropertyDoc(child).value, child);
    expect(
      MutableOptionalTypedDataPropertyDict(child).value,
      child,
    );
    expect(
      MutableOptionalTypedDataPropertyDoc(child).value,
      child,
    );
    expect(MutableOptionalTypedDataPropertyDict(null).value, isNull);
    expect(MutableOptionalTypedDataPropertyDoc(null).value, isNull);
  });

  test('set immutable value', () {
    final immutableValue =
        ImmutableBoolDict.internal(MutableDictionary({'value': false}));

    final dict = MutableTypedDataPropertyDict(BoolDict(true))
      ..value = immutableValue;
    expect(dict.value, isNot(immutableValue));
    expect(dict.value.value, isFalse);

    final optionalDict = MutableOptionalTypedDataPropertyDict(null)
      ..value = immutableValue;
    expect(optionalDict.value, isNot(immutableValue));
    expect(optionalDict.value?.value, isFalse);
  });
}
