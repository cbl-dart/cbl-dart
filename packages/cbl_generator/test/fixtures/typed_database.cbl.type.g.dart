// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'typed_database.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$CustomValueTypeMatcherDoc
    implements TypedDocumentObject<MutableCustomValueTypeMatcherDoc> {
  String get value;
}

abstract class _CustomValueTypeMatcherDocImplBase<I extends Document>
    with _$CustomValueTypeMatcherDoc
    implements CustomValueTypeMatcherDoc {
  _CustomValueTypeMatcherDocImplBase(this.internal);

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
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableCustomValueTypeMatcherDoc
    extends _CustomValueTypeMatcherDocImplBase {
  ImmutableCustomValueTypeMatcherDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomValueTypeMatcherDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [CustomValueTypeMatcherDoc].
class MutableCustomValueTypeMatcherDoc
    extends _CustomValueTypeMatcherDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<CustomValueTypeMatcherDoc,
            MutableCustomValueTypeMatcherDoc> {
  /// Creates a new mutable [CustomValueTypeMatcherDoc].
  MutableCustomValueTypeMatcherDoc(
    String value,
  ) : super(MutableDocument()) {
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
