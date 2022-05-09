import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/builtin_types.dart';
import '../matchers.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  group('nullable property', () {
    test('value has wrong type', () {
      final doc =
          MutableNullableBoolDict.internal(MutableDictionary({'value': 'a'}));
      expect(
        () => doc.value,
        throwsA(
          isTypedDataException.havingCode(TypedDataErrorCode.dataMismatch),
        ),
      );
    });
  });

  group('non-nullable property', () {
    test('value has wrong type', () {
      final doc = MutableBoolDict.internal(MutableDictionary({'value': 'a'}));
      expect(
        () => doc.value,
        throwsA(
          isTypedDataException.havingCode(TypedDataErrorCode.dataMismatch),
        ),
      );
    });

    test('value is missing', () {
      final doc = MutableBoolDict.internal(MutableDictionary({}));
      expect(
        () => doc.value,
        throwsA(
          isTypedDataException.havingCode(TypedDataErrorCode.dataMismatch),
        ),
      );
    });
  });
}
