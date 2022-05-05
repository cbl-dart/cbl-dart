// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports

part of 'doc_comment.dart';

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$DocCommentDict implements TypedDictionaryObject<MutableDocCommentDict> {
  /// This is a doc comment.
  String get value;
}

abstract class _DocCommentDictImplBase<I extends Dictionary>
    with _$DocCommentDict
    implements DocCommentDict {
  _DocCommentDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableDocCommentDict toMutable() =>
      MutableDocCommentDict.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDocCommentDict extends _DocCommentDictImplBase {
  ImmutableDocCommentDict.internal(Dictionary internal) : super(internal);
}

/// Mutable version of [DocCommentDict].
class MutableDocCommentDict extends _DocCommentDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<DocCommentDict, MutableDocCommentDict> {
  /// Creates a new mutable [DocCommentDict].
  MutableDocCommentDict(
    String value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableDocCommentDict.internal(MutableDictionary internal) : super(internal);

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
