import 'package:cbl/cbl.dart';

part 'document_meta_data.cbl.type.g.dart';

@TypedDocument()
abstract class DocWithId with _$DocWithId {
  factory DocWithId(@DocumentId() String id) = MutableDocWithId;
}

@TypedDocument()
abstract class DocWithOptionalId with _$DocWithOptionalId {
  factory DocWithOptionalId([@DocumentId() String? id]) =
      MutableDocWithOptionalId;
}

@TypedDocument()
abstract class DocWithIdAndField with _$DocWithIdAndField {
  factory DocWithIdAndField(@DocumentId() String id, String value) =
      MutableDocWithIdAndField;
}

@TypedDocument()
abstract class DocWithOptionalIdAndField with _$DocWithOptionalIdAndField {
  factory DocWithOptionalIdAndField(String value, [@DocumentId() String? id]) =
      MutableDocWithOptionalIdAndField;
}

@TypedDocument()
abstract class DocWithIdGetter with _$DocWithIdGetter {
  factory DocWithIdGetter() = MutableDocWithIdGetter;

  @DocumentId()
  String get id;
}

@TypedDocument()
abstract class DocWithSequenceGetter with _$DocWithSequenceGetter {
  factory DocWithSequenceGetter() = MutableDocWithSequenceGetter;

  @DocumentSequence()
  int get sequence;
}

@TypedDocument()
abstract class DocWithRevisionIdGetter with _$DocWithRevisionIdGetter {
  factory DocWithRevisionIdGetter() = MutableDocWithRevisionIdGetter;

  @DocumentRevisionId()
  String? get revisionId;
}
