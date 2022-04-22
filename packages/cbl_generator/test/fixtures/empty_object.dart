import 'package:cbl/cbl.dart';

part 'empty_object.cbl.type.g.dart';

@TypedDictionary()
abstract class EmptyDict with _$EmptyDict {
  factory EmptyDict() = MutableEmptyDict;
}

@TypedDocument()
abstract class EmptyDoc with _$EmptyDoc {
  factory EmptyDoc() = MutableEmptyDoc;
}
