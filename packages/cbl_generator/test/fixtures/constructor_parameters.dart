import 'package:cbl/cbl.dart';

part 'constructor_parameters.cbl.type.g.dart';

@TypedDictionary()
abstract class ParamDict with _$ParamDict {
  factory ParamDict(String a) = MutableParamDict;
}

@TypedDocument()
abstract class ParamDoc with _$ParamDoc {
  factory ParamDoc(String a) = MutableParamDoc;
}

@TypedDictionary()
abstract class OptionalParamDict with _$OptionalParamDict {
  factory OptionalParamDict([String? a]) = MutableOptionalParamDict;
}

@TypedDocument()
abstract class OptionalParamDoc with _$OptionalParamDoc {
  factory OptionalParamDoc([String? a]) = MutableOptionalParamDoc;
}

@TypedDictionary()
abstract class PositionalMixedParamDict with _$PositionalMixedParamDict {
  factory PositionalMixedParamDict(String a, [String? b]) =
      MutablePositionalMixedParamDict;
}

@TypedDocument()
abstract class PositionalMixedParamDoc with _$PositionalMixedParamDoc {
  factory PositionalMixedParamDoc(String a, [String? b]) =
      MutablePositionalMixedParamDoc;
}

@TypedDictionary()
abstract class NamedParamDict with _$NamedParamDict {
  factory NamedParamDict({required String a}) = MutableNamedParamDict;
}

@TypedDocument()
abstract class NamedParamDoc with _$NamedParamDoc {
  factory NamedParamDoc({required String a}) = MutableNamedParamDoc;
}

@TypedDictionary()
abstract class NamedOptionalParamDict with _$NamedOptionalParamDict {
  factory NamedOptionalParamDict({String? a}) = MutableNamedOptionalParamDict;
}

@TypedDocument()
abstract class NamedOptionalParamDoc with _$NamedOptionalParamDoc {
  factory NamedOptionalParamDoc({String? a}) = MutableNamedOptionalParamDoc;
}

@TypedDictionary()
abstract class NamedMixedParamDict with _$NamedMixedParamDict {
  factory NamedMixedParamDict(String a, {String? b}) =
      MutableNamedMixedParamDict;
}

@TypedDocument()
abstract class NamedMixedParamDoc with _$NamedMixedParamDoc {
  factory NamedMixedParamDoc(String a, {String? b}) = MutableNamedMixedParamDoc;
}
