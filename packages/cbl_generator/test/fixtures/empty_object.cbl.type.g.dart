// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'empty_object.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$EmptyDoc {}

abstract class EmptyDocDocument
    implements EmptyDoc, TypedDocumentObject<MutableEmptyDoc> {}

abstract class _EmptyDocDocumentImplBase<I extends Document>
    with _$EmptyDoc
    implements EmptyDocDocument {
  _EmptyDocDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableEmptyDoc toMutable() => MutableEmptyDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'EmptyDoc',
    fields: {},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableEmptyDoc extends _EmptyDocDocumentImplBase {
  ImmutableEmptyDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptyDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [EmptyDoc].
class MutableEmptyDoc extends _EmptyDocDocumentImplBase<MutableDocument>
    implements TypedMutableDocumentObject<EmptyDocDocument, MutableEmptyDoc> {
  /// Creates a new mutable [EmptyDoc].
  MutableEmptyDoc() : super(MutableDocument({}));

  MutableEmptyDoc.internal(super.internal);
}

mixin _$EmptyDocDictionary
    implements TypedDictionaryObject<MutableEmptyDocDictionary> {}

abstract class EmptyDocDictionary
    with _$EmptyDocDictionary
    implements EmptyDoc {}

abstract class _EmptyDocDictionaryImplBase<I extends Dictionary>
    with _$EmptyDocDictionary
    implements EmptyDocDictionary {
  _EmptyDocDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableEmptyDocDictionary toMutable() =>
      MutableEmptyDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'EmptyDocDictionary',
    fields: {},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableEmptyDocDictionary extends _EmptyDocDictionaryImplBase {
  ImmutableEmptyDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptyDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [EmptyDocDictionary].
class MutableEmptyDocDictionary
    extends _EmptyDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          EmptyDocDictionary,
          MutableEmptyDocDictionary
        > {
  /// Creates a new mutable [EmptyDocDictionary].
  MutableEmptyDocDictionary() : super(MutableDictionary());

  MutableEmptyDocDictionary.internal(super.internal);
}

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$EmptyDict implements TypedDictionaryObject<MutableEmptyDict> {}

abstract class _EmptyDictImplBase<I extends Dictionary>
    with _$EmptyDict
    implements EmptyDict {
  _EmptyDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableEmptyDict toMutable() =>
      MutableEmptyDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'EmptyDict',
    fields: {},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableEmptyDict extends _EmptyDictImplBase {
  ImmutableEmptyDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmptyDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [EmptyDict].
class MutableEmptyDict extends _EmptyDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<EmptyDict, MutableEmptyDict> {
  /// Creates a new mutable [EmptyDict].
  MutableEmptyDict() : super(MutableDictionary());

  MutableEmptyDict.internal(super.internal);
}
