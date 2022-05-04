// ignore_for_file: avoid_positional_boolean_parameters

import 'package:cbl/cbl.dart';

part 'typed_data_list.cbl.type.g.dart';

@TypedDictionary()
abstract class BoolListDict with _$BoolListDict {
  factory BoolListDict(List<bool> value) = MutableBoolListDict;
}

@TypedDictionary()
abstract class OptionalBoolListDict with _$OptionalBoolListDict {
  factory OptionalBoolListDict(List<bool>? value) = MutableOptionalBoolListDict;
}
