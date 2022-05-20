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
  bool get value => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'custom',
        converter: TypedDataHelpers.boolConverter,
      );

  @override
  MutableCustomDataNameDict toMutable() =>
      MutableCustomDataNameDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
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
  ImmutableCustomDataNameDict.internal(super.internal);

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

  MutableCustomDataNameDict.internal(super.internal);

  set value(bool value) {
    final promoted = TypedDataHelpers.boolConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'custom',
      value: promoted,
      converter: TypedDataHelpers.boolConverter,
    );
  }
}

mixin _$DefaultValueDict
    implements TypedDictionaryObject<MutableDefaultValueDict> {
  bool get value;
}

abstract class _DefaultValueDictImplBase<I extends Dictionary>
    with _$DefaultValueDict
    implements DefaultValueDict {
  _DefaultValueDictImplBase(this.internal);

  @override
  final I internal;

  @override
  bool get value => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        converter: TypedDataHelpers.boolConverter,
      );

  @override
  MutableDefaultValueDict toMutable() =>
      MutableDefaultValueDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'DefaultValueDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDefaultValueDict extends _DefaultValueDictImplBase {
  ImmutableDefaultValueDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefaultValueDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DefaultValueDict].
class MutableDefaultValueDict
    extends _DefaultValueDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<DefaultValueDict,
            MutableDefaultValueDict> {
  /// Creates a new mutable [DefaultValueDict].
  MutableDefaultValueDict([
    bool value = true,
  ]) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableDefaultValueDict.internal(super.internal);

  set value(bool value) {
    final promoted = TypedDataHelpers.boolConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: TypedDataHelpers.boolConverter,
    );
  }
}

mixin _$ScalarConverterDict
    implements TypedDictionaryObject<MutableScalarConverterDict> {
  Uri get value;
}

abstract class _ScalarConverterDictImplBase<I extends Dictionary>
    with _$ScalarConverterDict
    implements ScalarConverterDict {
  _ScalarConverterDictImplBase(this.internal);

  @override
  final I internal;

  @override
  Uri get value => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        converter: const ScalarConverterAdapter(
          const TestConverter(),
        ),
      );

  @override
  MutableScalarConverterDict toMutable() =>
      MutableScalarConverterDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'ScalarConverterDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableScalarConverterDict extends _ScalarConverterDictImplBase {
  ImmutableScalarConverterDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScalarConverterDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [ScalarConverterDict].
class MutableScalarConverterDict
    extends _ScalarConverterDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<ScalarConverterDict,
            MutableScalarConverterDict> {
  /// Creates a new mutable [ScalarConverterDict].
  MutableScalarConverterDict(
    Uri value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableScalarConverterDict.internal(super.internal);

  set value(Uri value) {
    final promoted = const ScalarConverterAdapter(
      const TestConverter(),
    ).promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: const ScalarConverterAdapter(
        const TestConverter(),
      ),
    );
  }
}
