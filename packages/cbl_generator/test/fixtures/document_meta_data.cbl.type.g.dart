// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports

part of 'document_meta_data.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$DocWithId implements TypedDocumentObject<MutableDocWithId> {
  String get id;
}

abstract class _DocWithIdImplBase<I extends Document>
    with _$DocWithId
    implements DocWithId {
  _DocWithIdImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  MutableDocWithId toMutable() =>
      MutableDocWithId.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithId extends _DocWithIdImplBase {
  ImmutableDocWithId.internal(Document internal) : super(internal);
}

/// Mutable version of [DocWithId].
class MutableDocWithId extends _DocWithIdImplBase<MutableDocument>
    implements TypedMutableDocumentObject<DocWithId, MutableDocWithId> {
  /// Creates a new mutable [DocWithId].
  MutableDocWithId(
    String id,
  ) : super(MutableDocument.withId(id));

  MutableDocWithId.internal(MutableDocument internal) : super(internal);
}

mixin _$DocWithOptionalId
    implements TypedDocumentObject<MutableDocWithOptionalId> {
  String get id;
}

abstract class _DocWithOptionalIdImplBase<I extends Document>
    with _$DocWithOptionalId
    implements DocWithOptionalId {
  _DocWithOptionalIdImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  MutableDocWithOptionalId toMutable() =>
      MutableDocWithOptionalId.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithOptionalId extends _DocWithOptionalIdImplBase {
  ImmutableDocWithOptionalId.internal(Document internal) : super(internal);
}

/// Mutable version of [DocWithOptionalId].
class MutableDocWithOptionalId
    extends _DocWithOptionalIdImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<DocWithOptionalId,
            MutableDocWithOptionalId> {
  /// Creates a new mutable [DocWithOptionalId].
  MutableDocWithOptionalId([
    String? id,
  ]) : super(id == null ? MutableDocument() : MutableDocument.withId(id));

  MutableDocWithOptionalId.internal(MutableDocument internal) : super(internal);
}

mixin _$DocWithIdAndField
    implements TypedDocumentObject<MutableDocWithIdAndField> {
  String get id;

  String get value;
}

abstract class _DocWithIdAndFieldImplBase<I extends Document>
    with _$DocWithIdAndField
    implements DocWithIdAndField {
  _DocWithIdAndFieldImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  String get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableDocWithIdAndField toMutable() =>
      MutableDocWithIdAndField.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdAndField extends _DocWithIdAndFieldImplBase {
  ImmutableDocWithIdAndField.internal(Document internal) : super(internal);
}

/// Mutable version of [DocWithIdAndField].
class MutableDocWithIdAndField
    extends _DocWithIdAndFieldImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<DocWithIdAndField,
            MutableDocWithIdAndField> {
  /// Creates a new mutable [DocWithIdAndField].
  MutableDocWithIdAndField(
    String id,
    String value,
  ) : super(MutableDocument.withId(id)) {
    this.value = value;
  }

  MutableDocWithIdAndField.internal(MutableDocument internal) : super(internal);

  set value(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithOptionalIdAndField
    implements TypedDocumentObject<MutableDocWithOptionalIdAndField> {
  String get value;

  String get id;
}

abstract class _DocWithOptionalIdAndFieldImplBase<I extends Document>
    with _$DocWithOptionalIdAndField
    implements DocWithOptionalIdAndField {
  _DocWithOptionalIdAndFieldImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  String get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableDocWithOptionalIdAndField toMutable() =>
      MutableDocWithOptionalIdAndField.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithOptionalIdAndField
    extends _DocWithOptionalIdAndFieldImplBase {
  ImmutableDocWithOptionalIdAndField.internal(Document internal)
      : super(internal);
}

/// Mutable version of [DocWithOptionalIdAndField].
class MutableDocWithOptionalIdAndField
    extends _DocWithOptionalIdAndFieldImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<DocWithOptionalIdAndField,
            MutableDocWithOptionalIdAndField> {
  /// Creates a new mutable [DocWithOptionalIdAndField].
  MutableDocWithOptionalIdAndField(
    String value, [
    String? id,
  ]) : super(id == null ? MutableDocument() : MutableDocument.withId(id)) {
    this.value = value;
  }

  MutableDocWithOptionalIdAndField.internal(MutableDocument internal)
      : super(internal);

  set value(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithIdGetter implements TypedDocumentObject<MutableDocWithIdGetter> {
}

abstract class _DocWithIdGetterImplBase<I extends Document>
    with _$DocWithIdGetter
    implements DocWithIdGetter {
  _DocWithIdGetterImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  MutableDocWithIdGetter toMutable() =>
      MutableDocWithIdGetter.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdGetter extends _DocWithIdGetterImplBase {
  ImmutableDocWithIdGetter.internal(Document internal) : super(internal);
}

/// Mutable version of [DocWithIdGetter].
class MutableDocWithIdGetter extends _DocWithIdGetterImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<DocWithIdGetter, MutableDocWithIdGetter> {
  /// Creates a new mutable [DocWithIdGetter].
  MutableDocWithIdGetter() : super(MutableDocument());

  MutableDocWithIdGetter.internal(MutableDocument internal) : super(internal);
}

mixin _$DocWithSequenceGetter
    implements TypedDocumentObject<MutableDocWithSequenceGetter> {}

abstract class _DocWithSequenceGetterImplBase<I extends Document>
    with _$DocWithSequenceGetter
    implements DocWithSequenceGetter {
  _DocWithSequenceGetterImplBase(this.internal);

  @override
  final I internal;

  @override
  int get sequence => internal.sequence;

  @override
  MutableDocWithSequenceGetter toMutable() =>
      MutableDocWithSequenceGetter.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithSequenceGetter extends _DocWithSequenceGetterImplBase {
  ImmutableDocWithSequenceGetter.internal(Document internal) : super(internal);
}

/// Mutable version of [DocWithSequenceGetter].
class MutableDocWithSequenceGetter
    extends _DocWithSequenceGetterImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<DocWithSequenceGetter,
            MutableDocWithSequenceGetter> {
  /// Creates a new mutable [DocWithSequenceGetter].
  MutableDocWithSequenceGetter() : super(MutableDocument());

  MutableDocWithSequenceGetter.internal(MutableDocument internal)
      : super(internal);
}

mixin _$DocWithRevisionIdGetter
    implements TypedDocumentObject<MutableDocWithRevisionIdGetter> {}

abstract class _DocWithRevisionIdGetterImplBase<I extends Document>
    with _$DocWithRevisionIdGetter
    implements DocWithRevisionIdGetter {
  _DocWithRevisionIdGetterImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get revisionId => internal.revisionId;

  @override
  MutableDocWithRevisionIdGetter toMutable() =>
      MutableDocWithRevisionIdGetter.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithRevisionIdGetter
    extends _DocWithRevisionIdGetterImplBase {
  ImmutableDocWithRevisionIdGetter.internal(Document internal)
      : super(internal);
}

/// Mutable version of [DocWithRevisionIdGetter].
class MutableDocWithRevisionIdGetter
    extends _DocWithRevisionIdGetterImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<DocWithRevisionIdGetter,
            MutableDocWithRevisionIdGetter> {
  /// Creates a new mutable [DocWithRevisionIdGetter].
  MutableDocWithRevisionIdGetter() : super(MutableDocument());

  MutableDocWithRevisionIdGetter.internal(MutableDocument internal)
      : super(internal);
}
