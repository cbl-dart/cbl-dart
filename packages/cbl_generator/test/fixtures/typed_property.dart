// ignore_for_file: avoid_positional_boolean_parameters

import 'package:cbl/cbl.dart';

part 'typed_property.cbl.type.g.dart';

@TypedDictionary()
abstract class CustomDataNameDict with _$CustomDataNameDict {
  factory CustomDataNameDict(
    @TypedProperty(property: 'custom') bool value,
  ) = MutableCustomDataNameDict;
}

@TypedDictionary()
abstract class DefaultValueDict with _$DefaultValueDict {
  factory DefaultValueDict([
    @TypedProperty(defaultValue: 'true') bool value,
  ]) = MutableDefaultValueDict;
}

class TestConverter extends ScalarConverter<Uri> {
  const TestConverter();
  @override
  Uri fromData(Object value) {
    if (value is! String) {
      throw UnexpectedTypeException(value: value, expectedTypes: [String]);
    }
    return Uri.parse(value);
  }

  @override
  Object toData(Uri value) => value.toString();
}

@TypedDictionary()
abstract class ScalarConverterDict with _$ScalarConverterDict {
  factory ScalarConverterDict(
    @TypedProperty(converter: TestConverter()) Uri value,
  ) = MutableScalarConverterDict;
}
