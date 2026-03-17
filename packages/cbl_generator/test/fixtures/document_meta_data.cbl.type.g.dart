// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'document_meta_data.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$DocWithId {
  String get id;
}

abstract class DocWithIdDocument
    implements DocWithId, TypedDocumentObject<MutableDocWithId> {}

abstract class _DocWithIdDocumentImplBase<I extends Document>
    with _$DocWithId
    implements DocWithIdDocument {
  _DocWithIdDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  MutableDocWithId toMutable() =>
      MutableDocWithId.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithId',
    fields: {'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithId extends _DocWithIdDocumentImplBase {
  ImmutableDocWithId.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithIdDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithId].
class MutableDocWithId extends _DocWithIdDocumentImplBase<MutableDocument>
    implements TypedMutableDocumentObject<DocWithIdDocument, MutableDocWithId> {
  /// Creates a new mutable [DocWithId].
  MutableDocWithId(String id) : super(MutableDocument(id: id, {}));

  MutableDocWithId.internal(super.internal);
}

mixin _$DocWithIdDictionary
    implements TypedDictionaryObject<MutableDocWithIdDictionary> {
  String get id;
}

abstract class DocWithIdDictionary
    with _$DocWithIdDictionary
    implements DocWithId {}

abstract class _DocWithIdDictionaryImplBase<I extends Dictionary>
    with _$DocWithIdDictionary
    implements DocWithIdDictionary {
  _DocWithIdDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'id',
    key: 'id',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithIdDictionary toMutable() =>
      MutableDocWithIdDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithIdDictionary',
    fields: {'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdDictionary extends _DocWithIdDictionaryImplBase {
  ImmutableDocWithIdDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithIdDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithIdDictionary].
class MutableDocWithIdDictionary
    extends _DocWithIdDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithIdDictionary,
          MutableDocWithIdDictionary
        > {
  /// Creates a new mutable [DocWithIdDictionary].
  MutableDocWithIdDictionary(String id) : super(MutableDictionary()) {
    this.id = id;
  }

  MutableDocWithIdDictionary.internal(super.internal);

  set id(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'id',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithOptionalId {
  String get id;
}

abstract class DocWithOptionalIdDocument
    implements
        DocWithOptionalId,
        TypedDocumentObject<MutableDocWithOptionalId> {}

abstract class _DocWithOptionalIdDocumentImplBase<I extends Document>
    with _$DocWithOptionalId
    implements DocWithOptionalIdDocument {
  _DocWithOptionalIdDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  MutableDocWithOptionalId toMutable() =>
      MutableDocWithOptionalId.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithOptionalId',
    fields: {'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithOptionalId extends _DocWithOptionalIdDocumentImplBase {
  ImmutableDocWithOptionalId.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithOptionalIdDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithOptionalId].
class MutableDocWithOptionalId
    extends _DocWithOptionalIdDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          DocWithOptionalIdDocument,
          MutableDocWithOptionalId
        > {
  /// Creates a new mutable [DocWithOptionalId].
  MutableDocWithOptionalId([String? id]) : super(MutableDocument(id: id, {}));

  MutableDocWithOptionalId.internal(super.internal);
}

mixin _$DocWithOptionalIdDictionary
    implements TypedDictionaryObject<MutableDocWithOptionalIdDictionary> {
  String get id;
}

abstract class DocWithOptionalIdDictionary
    with _$DocWithOptionalIdDictionary
    implements DocWithOptionalId {}

abstract class _DocWithOptionalIdDictionaryImplBase<I extends Dictionary>
    with _$DocWithOptionalIdDictionary
    implements DocWithOptionalIdDictionary {
  _DocWithOptionalIdDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'id',
    key: 'id',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithOptionalIdDictionary toMutable() =>
      MutableDocWithOptionalIdDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithOptionalIdDictionary',
    fields: {'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithOptionalIdDictionary
    extends _DocWithOptionalIdDictionaryImplBase {
  ImmutableDocWithOptionalIdDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithOptionalIdDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithOptionalIdDictionary].
class MutableDocWithOptionalIdDictionary
    extends _DocWithOptionalIdDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithOptionalIdDictionary,
          MutableDocWithOptionalIdDictionary
        > {
  /// Creates a new mutable [DocWithOptionalIdDictionary].
  MutableDocWithOptionalIdDictionary(String id) : super(MutableDictionary()) {
    this.id = id;
  }

  MutableDocWithOptionalIdDictionary.internal(super.internal);

  set id(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'id',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithIdAndField {
  String get id;

  String get value;
}

abstract class DocWithIdAndFieldDocument
    implements
        DocWithIdAndField,
        TypedDocumentObject<MutableDocWithIdAndField> {}

abstract class _DocWithIdAndFieldDocumentImplBase<I extends Document>
    with _$DocWithIdAndField
    implements DocWithIdAndFieldDocument {
  _DocWithIdAndFieldDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  String get value => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithIdAndField toMutable() =>
      MutableDocWithIdAndField.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithIdAndField',
    fields: {'id': id, 'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdAndField extends _DocWithIdAndFieldDocumentImplBase {
  ImmutableDocWithIdAndField.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithIdAndFieldDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithIdAndField].
class MutableDocWithIdAndField
    extends _DocWithIdAndFieldDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          DocWithIdAndFieldDocument,
          MutableDocWithIdAndField
        > {
  /// Creates a new mutable [DocWithIdAndField].
  MutableDocWithIdAndField(String id, String value)
    : super(MutableDocument(id: id, {})) {
    this.value = value;
  }

  MutableDocWithIdAndField.internal(super.internal);

  set value(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithIdAndFieldDictionary
    implements TypedDictionaryObject<MutableDocWithIdAndFieldDictionary> {
  String get id;

  String get value;
}

abstract class DocWithIdAndFieldDictionary
    with _$DocWithIdAndFieldDictionary
    implements DocWithIdAndField {}

abstract class _DocWithIdAndFieldDictionaryImplBase<I extends Dictionary>
    with _$DocWithIdAndFieldDictionary
    implements DocWithIdAndFieldDictionary {
  _DocWithIdAndFieldDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'id',
    key: 'id',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  String get value => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithIdAndFieldDictionary toMutable() =>
      MutableDocWithIdAndFieldDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithIdAndFieldDictionary',
    fields: {'id': id, 'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdAndFieldDictionary
    extends _DocWithIdAndFieldDictionaryImplBase {
  ImmutableDocWithIdAndFieldDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithIdAndFieldDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithIdAndFieldDictionary].
class MutableDocWithIdAndFieldDictionary
    extends _DocWithIdAndFieldDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithIdAndFieldDictionary,
          MutableDocWithIdAndFieldDictionary
        > {
  /// Creates a new mutable [DocWithIdAndFieldDictionary].
  MutableDocWithIdAndFieldDictionary(String id, String value)
    : super(MutableDictionary()) {
    this.id = id;
    this.value = value;
  }

  MutableDocWithIdAndFieldDictionary.internal(super.internal);

  set id(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'id',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set value(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithOptionalIdAndField {
  String get value;

  String get id;
}

abstract class DocWithOptionalIdAndFieldDocument
    implements
        DocWithOptionalIdAndField,
        TypedDocumentObject<MutableDocWithOptionalIdAndField> {}

abstract class _DocWithOptionalIdAndFieldDocumentImplBase<I extends Document>
    with _$DocWithOptionalIdAndField
    implements DocWithOptionalIdAndFieldDocument {
  _DocWithOptionalIdAndFieldDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  String get value => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithOptionalIdAndField toMutable() =>
      MutableDocWithOptionalIdAndField.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithOptionalIdAndField',
    fields: {'id': id, 'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithOptionalIdAndField
    extends _DocWithOptionalIdAndFieldDocumentImplBase {
  ImmutableDocWithOptionalIdAndField.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithOptionalIdAndFieldDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithOptionalIdAndField].
class MutableDocWithOptionalIdAndField
    extends _DocWithOptionalIdAndFieldDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          DocWithOptionalIdAndFieldDocument,
          MutableDocWithOptionalIdAndField
        > {
  /// Creates a new mutable [DocWithOptionalIdAndField].
  MutableDocWithOptionalIdAndField(String value, [String? id])
    : super(MutableDocument(id: id, {})) {
    this.value = value;
  }

  MutableDocWithOptionalIdAndField.internal(super.internal);

  set value(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithOptionalIdAndFieldDictionary
    implements
        TypedDictionaryObject<MutableDocWithOptionalIdAndFieldDictionary> {
  String get value;

  String get id;
}

abstract class DocWithOptionalIdAndFieldDictionary
    with _$DocWithOptionalIdAndFieldDictionary
    implements DocWithOptionalIdAndField {}

abstract class _DocWithOptionalIdAndFieldDictionaryImplBase<
  I extends Dictionary
>
    with _$DocWithOptionalIdAndFieldDictionary
    implements DocWithOptionalIdAndFieldDictionary {
  _DocWithOptionalIdAndFieldDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  String get value => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  String get id => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'id',
    key: 'id',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithOptionalIdAndFieldDictionary toMutable() =>
      MutableDocWithOptionalIdAndFieldDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithOptionalIdAndFieldDictionary',
    fields: {'value': value, 'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithOptionalIdAndFieldDictionary
    extends _DocWithOptionalIdAndFieldDictionaryImplBase {
  ImmutableDocWithOptionalIdAndFieldDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithOptionalIdAndFieldDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithOptionalIdAndFieldDictionary].
class MutableDocWithOptionalIdAndFieldDictionary
    extends _DocWithOptionalIdAndFieldDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithOptionalIdAndFieldDictionary,
          MutableDocWithOptionalIdAndFieldDictionary
        > {
  /// Creates a new mutable [DocWithOptionalIdAndFieldDictionary].
  MutableDocWithOptionalIdAndFieldDictionary(String value, String id)
    : super(MutableDictionary()) {
    this.value = value;
    this.id = id;
  }

  MutableDocWithOptionalIdAndFieldDictionary.internal(super.internal);

  set value(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set id(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'id',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithIdGetter {}

abstract class DocWithIdGetterDocument
    implements DocWithIdGetter, TypedDocumentObject<MutableDocWithIdGetter> {}

abstract class _DocWithIdGetterDocumentImplBase<I extends Document>
    with _$DocWithIdGetter
    implements DocWithIdGetterDocument {
  _DocWithIdGetterDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  MutableDocWithIdGetter toMutable() =>
      MutableDocWithIdGetter.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithIdGetter',
    fields: {'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdGetter extends _DocWithIdGetterDocumentImplBase {
  ImmutableDocWithIdGetter.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithIdGetterDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithIdGetter].
class MutableDocWithIdGetter
    extends _DocWithIdGetterDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          DocWithIdGetterDocument,
          MutableDocWithIdGetter
        > {
  /// Creates a new mutable [DocWithIdGetter].
  MutableDocWithIdGetter() : super(MutableDocument({}));

  MutableDocWithIdGetter.internal(super.internal);
}

mixin _$DocWithIdGetterDictionary
    implements TypedDictionaryObject<MutableDocWithIdGetterDictionary> {}

abstract class DocWithIdGetterDictionary
    with _$DocWithIdGetterDictionary
    implements DocWithIdGetter {}

abstract class _DocWithIdGetterDictionaryImplBase<I extends Dictionary>
    with _$DocWithIdGetterDictionary
    implements DocWithIdGetterDictionary {
  _DocWithIdGetterDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'id',
    key: 'id',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithIdGetterDictionary toMutable() =>
      MutableDocWithIdGetterDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithIdGetterDictionary',
    fields: {'id': id},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithIdGetterDictionary
    extends _DocWithIdGetterDictionaryImplBase {
  ImmutableDocWithIdGetterDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithIdGetterDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithIdGetterDictionary].
class MutableDocWithIdGetterDictionary
    extends _DocWithIdGetterDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithIdGetterDictionary,
          MutableDocWithIdGetterDictionary
        > {
  /// Creates a new mutable [DocWithIdGetterDictionary].
  MutableDocWithIdGetterDictionary() : super(MutableDictionary());

  MutableDocWithIdGetterDictionary.internal(super.internal);

  set id(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'id',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$DocWithSequenceGetter {}

abstract class DocWithSequenceGetterDocument
    implements
        DocWithSequenceGetter,
        TypedDocumentObject<MutableDocWithSequenceGetter> {}

abstract class _DocWithSequenceGetterDocumentImplBase<I extends Document>
    with _$DocWithSequenceGetter
    implements DocWithSequenceGetterDocument {
  _DocWithSequenceGetterDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  int get sequence => internal.sequence;

  @override
  MutableDocWithSequenceGetter toMutable() =>
      MutableDocWithSequenceGetter.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithSequenceGetter',
    fields: {'sequence': sequence},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithSequenceGetter
    extends _DocWithSequenceGetterDocumentImplBase {
  ImmutableDocWithSequenceGetter.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithSequenceGetterDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithSequenceGetter].
class MutableDocWithSequenceGetter
    extends _DocWithSequenceGetterDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          DocWithSequenceGetterDocument,
          MutableDocWithSequenceGetter
        > {
  /// Creates a new mutable [DocWithSequenceGetter].
  MutableDocWithSequenceGetter() : super(MutableDocument({}));

  MutableDocWithSequenceGetter.internal(super.internal);
}

mixin _$DocWithSequenceGetterDictionary
    implements TypedDictionaryObject<MutableDocWithSequenceGetterDictionary> {}

abstract class DocWithSequenceGetterDictionary
    with _$DocWithSequenceGetterDictionary
    implements DocWithSequenceGetter {}

abstract class _DocWithSequenceGetterDictionaryImplBase<I extends Dictionary>
    with _$DocWithSequenceGetterDictionary
    implements DocWithSequenceGetterDictionary {
  _DocWithSequenceGetterDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  int get sequence => TypedDataHelpers.readProperty(
    internal: internal,
    name: 'sequence',
    key: 'sequence',
    converter: TypedDataHelpers.intConverter,
  );

  @override
  MutableDocWithSequenceGetterDictionary toMutable() =>
      MutableDocWithSequenceGetterDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithSequenceGetterDictionary',
    fields: {'sequence': sequence},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithSequenceGetterDictionary
    extends _DocWithSequenceGetterDictionaryImplBase {
  ImmutableDocWithSequenceGetterDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithSequenceGetterDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithSequenceGetterDictionary].
class MutableDocWithSequenceGetterDictionary
    extends _DocWithSequenceGetterDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithSequenceGetterDictionary,
          MutableDocWithSequenceGetterDictionary
        > {
  /// Creates a new mutable [DocWithSequenceGetterDictionary].
  MutableDocWithSequenceGetterDictionary() : super(MutableDictionary());

  MutableDocWithSequenceGetterDictionary.internal(super.internal);

  set sequence(int value) {
    final promoted = TypedDataHelpers.intConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'sequence',
      value: promoted,
      converter: TypedDataHelpers.intConverter,
    );
  }
}

mixin _$DocWithRevisionIdGetter {}

abstract class DocWithRevisionIdGetterDocument
    implements
        DocWithRevisionIdGetter,
        TypedDocumentObject<MutableDocWithRevisionIdGetter> {}

abstract class _DocWithRevisionIdGetterDocumentImplBase<I extends Document>
    with _$DocWithRevisionIdGetter
    implements DocWithRevisionIdGetterDocument {
  _DocWithRevisionIdGetterDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get revisionId => internal.revisionId;

  @override
  MutableDocWithRevisionIdGetter toMutable() =>
      MutableDocWithRevisionIdGetter.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithRevisionIdGetter',
    fields: {'revisionId': revisionId},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithRevisionIdGetter
    extends _DocWithRevisionIdGetterDocumentImplBase {
  ImmutableDocWithRevisionIdGetter.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithRevisionIdGetterDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithRevisionIdGetter].
class MutableDocWithRevisionIdGetter
    extends _DocWithRevisionIdGetterDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          DocWithRevisionIdGetterDocument,
          MutableDocWithRevisionIdGetter
        > {
  /// Creates a new mutable [DocWithRevisionIdGetter].
  MutableDocWithRevisionIdGetter() : super(MutableDocument({}));

  MutableDocWithRevisionIdGetter.internal(super.internal);
}

mixin _$DocWithRevisionIdGetterDictionary
    implements
        TypedDictionaryObject<MutableDocWithRevisionIdGetterDictionary> {}

abstract class DocWithRevisionIdGetterDictionary
    with _$DocWithRevisionIdGetterDictionary
    implements DocWithRevisionIdGetter {}

abstract class _DocWithRevisionIdGetterDictionaryImplBase<I extends Dictionary>
    with _$DocWithRevisionIdGetterDictionary
    implements DocWithRevisionIdGetterDictionary {
  _DocWithRevisionIdGetterDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get revisionId => TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'revisionId',
    key: 'revisionId',
    converter: TypedDataHelpers.stringConverter,
  );

  @override
  MutableDocWithRevisionIdGetterDictionary toMutable() =>
      MutableDocWithRevisionIdGetterDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'DocWithRevisionIdGetterDictionary',
    fields: {'revisionId': revisionId},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocWithRevisionIdGetterDictionary
    extends _DocWithRevisionIdGetterDictionaryImplBase {
  ImmutableDocWithRevisionIdGetterDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocWithRevisionIdGetterDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DocWithRevisionIdGetterDictionary].
class MutableDocWithRevisionIdGetterDictionary
    extends _DocWithRevisionIdGetterDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          DocWithRevisionIdGetterDictionary,
          MutableDocWithRevisionIdGetterDictionary
        > {
  /// Creates a new mutable [DocWithRevisionIdGetterDictionary].
  MutableDocWithRevisionIdGetterDictionary() : super(MutableDictionary());

  MutableDocWithRevisionIdGetterDictionary.internal(super.internal);

  set revisionId(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'revisionId',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}
