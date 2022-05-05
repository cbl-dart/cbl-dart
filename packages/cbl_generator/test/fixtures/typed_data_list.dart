// ignore_for_file: avoid_positional_boolean_parameters

import 'package:cbl/cbl.dart';

import 'builtin_types.dart';

part 'typed_data_list.cbl.type.g.dart';

@TypedDictionary()
abstract class BoolListDict with _$BoolListDict {
  factory BoolListDict(List<bool> value) = MutableBoolListDict;
}

@TypedDictionary()
abstract class OptionalBoolListDict with _$OptionalBoolListDict {
  factory OptionalBoolListDict(List<bool>? value) = MutableOptionalBoolListDict;
}

@TypedDictionary()
abstract class BoolDictListDict with _$BoolDictListDict {
  factory BoolDictListDict(List<BoolDict> value) = MutableBoolDictListDict;
}

@TypedDictionary()
abstract class BoolListListDict with _$BoolListListDict {
  factory BoolListListDict(List<List<bool>> value) = MutableBoolListListDict;
}
