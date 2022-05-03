// ignore_for_file: avoid_positional_boolean_parameters

import 'package:cbl/cbl.dart';

import 'builtin_types.dart';

part 'typed_data_child.cbl.type.g.dart';

@TypedDictionary()
abstract class TypedDataPropertyDict with _$TypedDataPropertyDict {
  factory TypedDataPropertyDict(BoolDict value) = MutableTypedDataPropertyDict;
}

@TypedDocument()
abstract class TypedDataPropertyDoc with _$TypedDataPropertyDoc {
  factory TypedDataPropertyDoc(BoolDict value) = MutableTypedDataPropertyDoc;
}

@TypedDictionary()
abstract class OptionalTypedDataPropertyDict
    with _$OptionalTypedDataPropertyDict {
  factory OptionalTypedDataPropertyDict(BoolDict? value) =
      MutableOptionalTypedDataPropertyDict;
}

@TypedDocument()
abstract class OptionalTypedDataPropertyDoc
    with _$OptionalTypedDataPropertyDoc {
  factory OptionalTypedDataPropertyDoc(BoolDict? value) =
      MutableOptionalTypedDataPropertyDoc;
}
