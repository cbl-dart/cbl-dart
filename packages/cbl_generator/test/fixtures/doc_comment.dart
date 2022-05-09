import 'package:cbl/cbl.dart';

part 'doc_comment.cbl.type.g.dart';

@TypedDictionary()
abstract class DocCommentDict with _$DocCommentDict {
  factory DocCommentDict(
    /// This is a doc comment.
    String value,
  ) = MutableDocCommentDict;
}
