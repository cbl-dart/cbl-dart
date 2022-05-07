// ignore_for_file: invalid_use_of_internal_member

// import 'package:cbl/cbl.dart' hide TypeMatcher;
// import 'package:cbl/src/typed_data/collection.dart';
// import 'package:cbl/src/typed_data/conversion.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('ImmutableTypedDataList', () {});

  group('MutableTypedDataList', () {});

  group('CachedTypedDataList', () {});
}

// final isUnexpectedTypeException = isA<UnexpectedTypeException>();

// extension on TypeMatcher<UnexpectedTypeException> {
//   TypeMatcher<UnexpectedTypeException> havingExpectedTypes(
//     Object expectedTypes,
//   ) =>
//       having((it) => it.expectedTypes, 'expectedTypes', expectedTypes);

//   TypeMatcher<UnexpectedTypeException> havingValue(
//     Object value,
//   ) =>
//       having((it) => it.value, 'value', value);
// }
