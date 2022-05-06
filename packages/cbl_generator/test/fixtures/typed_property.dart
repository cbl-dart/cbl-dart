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
