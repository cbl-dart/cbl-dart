import 'package:cbl/cbl.dart';
import 'package:test/test.dart' as test;

final isTypedDataException = test.isA<TypedDataException>();

extension TypedDataExceptionMatcherExt on test.TypeMatcher<TypedDataException> {
  test.TypeMatcher<TypedDataException> havingMessage(String message) =>
      having((it) => it.message, 'message', message);

  test.TypeMatcher<TypedDataException> havingCode(TypedDataErrorCode code) =>
      having((it) => it.code, 'code', code);
}
