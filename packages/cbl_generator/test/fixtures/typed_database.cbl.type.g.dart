// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'typed_database.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$CustomValueTypeMatcherDoc {
  String get value;
}

abstract class CustomValueTypeMatcherDocDocument
    implements
        CustomValueTypeMatcherDoc,
        TypedDocumentObject<MutableCustomValueTypeMatcherDoc> {}

abstract class _CustomValueTypeMatcherDocDocumentImplBase<I extends Document>
    with _$CustomValueTypeMatcherDoc
    implements CustomValueTypeMatcherDocDocument {
  _CustomValueTypeMatcherDocDocumentImplBase(this.internal);

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
  MutableCustomValueTypeMatcherDoc toMutable() =>
      MutableCustomValueTypeMatcherDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'CustomValueTypeMatcherDoc',
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableCustomValueTypeMatcherDoc
    extends _CustomValueTypeMatcherDocDocumentImplBase {
  ImmutableCustomValueTypeMatcherDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomValueTypeMatcherDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [CustomValueTypeMatcherDoc].
class MutableCustomValueTypeMatcherDoc
    extends _CustomValueTypeMatcherDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          CustomValueTypeMatcherDocDocument,
          MutableCustomValueTypeMatcherDoc
        > {
  /// Creates a new mutable [CustomValueTypeMatcherDoc].
  MutableCustomValueTypeMatcherDoc(String value) : super(MutableDocument({})) {
    this.value = value;
  }

  MutableCustomValueTypeMatcherDoc.internal(super.internal);

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

mixin _$CustomValueTypeMatcherDocDictionary
    implements
        TypedDictionaryObject<MutableCustomValueTypeMatcherDocDictionary> {
  String get value;
}

abstract class CustomValueTypeMatcherDocDictionary
    with _$CustomValueTypeMatcherDocDictionary
    implements CustomValueTypeMatcherDoc {}

abstract class _CustomValueTypeMatcherDocDictionaryImplBase<
  I extends Dictionary
>
    with _$CustomValueTypeMatcherDocDictionary
    implements CustomValueTypeMatcherDocDictionary {
  _CustomValueTypeMatcherDocDictionaryImplBase(this.internal);

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
  MutableCustomValueTypeMatcherDocDictionary toMutable() =>
      MutableCustomValueTypeMatcherDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'CustomValueTypeMatcherDocDictionary',
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableCustomValueTypeMatcherDocDictionary
    extends _CustomValueTypeMatcherDocDictionaryImplBase {
  ImmutableCustomValueTypeMatcherDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomValueTypeMatcherDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [CustomValueTypeMatcherDocDictionary].
class MutableCustomValueTypeMatcherDocDictionary
    extends _CustomValueTypeMatcherDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          CustomValueTypeMatcherDocDictionary,
          MutableCustomValueTypeMatcherDocDictionary
        > {
  /// Creates a new mutable [CustomValueTypeMatcherDocDictionary].
  MutableCustomValueTypeMatcherDocDictionary(String value)
    : super(MutableDictionary()) {
    this.value = value;
  }

  MutableCustomValueTypeMatcherDocDictionary.internal(super.internal);

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
