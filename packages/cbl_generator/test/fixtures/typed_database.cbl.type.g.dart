// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments

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
  String get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableCustomValueTypeMatcherDoc toMutable() =>
      MutableCustomValueTypeMatcherDoc.internal(internal.toMutable());
}

class ImmutableCustomValueTypeMatcherDoc
    extends _CustomValueTypeMatcherDocImplBase {
  ImmutableCustomValueTypeMatcherDoc.internal(Document internal)
      : super(internal);
}

class MutableCustomValueTypeMatcherDoc
    extends _CustomValueTypeMatcherDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<CustomValueTypeMatcherDoc,
            MutableCustomValueTypeMatcherDoc> {
  MutableCustomValueTypeMatcherDoc(
    String value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableCustomValueTypeMatcherDoc.internal(MutableDocument internal)
      : super(internal);

  set value(String value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.stringConverter,
      );
}
