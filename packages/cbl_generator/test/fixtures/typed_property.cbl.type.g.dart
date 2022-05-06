// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'typed_property.dart';

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$CustomDataNameDict
    implements TypedDictionaryObject<MutableCustomDataNameDict> {
  bool get value;
}

abstract class _CustomDataNameDictImplBase<I extends Dictionary>
    with _$CustomDataNameDict
    implements CustomDataNameDict {
  _CustomDataNameDictImplBase(this.internal);

  @override
  final I internal;

  @override
  bool get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'custom',
        reviver: InternalTypedDataHelpers.boolConverter,
      );

  @override
  MutableCustomDataNameDict toMutable() =>
      MutableCustomDataNameDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => InternalTypedDataHelpers.renderString(
        indent: indent,
        className: 'CustomDataNameDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableCustomDataNameDict extends _CustomDataNameDictImplBase {
  ImmutableCustomDataNameDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomDataNameDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [CustomDataNameDict].
class MutableCustomDataNameDict
    extends _CustomDataNameDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<CustomDataNameDict,
            MutableCustomDataNameDict> {
  /// Creates a new mutable [CustomDataNameDict].
  MutableCustomDataNameDict(
    bool value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableCustomDataNameDict.internal(MutableDictionary internal)
      : super(internal);

  set value(bool value) {
    final promoted = InternalTypedDataHelpers.boolConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'custom',
      value: promoted,
      freezer: InternalTypedDataHelpers.boolConverter,
    );
  }
}
