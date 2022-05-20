// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'typed_data_child.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$TypedDataPropertyDoc
    implements TypedDocumentObject<MutableTypedDataPropertyDoc> {
  BoolDict get value;
}

abstract class _TypedDataPropertyDocImplBase<I extends Document>
    with _$TypedDataPropertyDoc
    implements TypedDataPropertyDoc {
  _TypedDataPropertyDocImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableTypedDataPropertyDoc toMutable() =>
      MutableTypedDataPropertyDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'TypedDataPropertyDoc',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableTypedDataPropertyDoc extends _TypedDataPropertyDocImplBase {
  ImmutableTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<Dictionary,
      BoolDict, TypedDictionaryObject<BoolDict>>(ImmutableBoolDict.internal);

  @override
  late final value = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypedDataPropertyDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [TypedDataPropertyDoc].
class MutableTypedDataPropertyDoc
    extends _TypedDataPropertyDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<TypedDataPropertyDoc,
            MutableTypedDataPropertyDoc> {
  /// Creates a new mutable [TypedDataPropertyDoc].
  MutableTypedDataPropertyDoc(
    BoolDict value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<
      MutableDictionary, MutableBoolDict, BoolDict>(MutableBoolDict.internal);

  late MutableBoolDict _value = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  MutableBoolDict get value => _value;

  set value(BoolDict value) {
    final promoted = _valueConverter.promote(value);
    _value = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: _valueConverter,
    );
  }
}

mixin _$OptionalTypedDataPropertyDoc
    implements TypedDocumentObject<MutableOptionalTypedDataPropertyDoc> {
  BoolDict? get value;
}

abstract class _OptionalTypedDataPropertyDocImplBase<I extends Document>
    with _$OptionalTypedDataPropertyDoc
    implements OptionalTypedDataPropertyDoc {
  _OptionalTypedDataPropertyDocImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableOptionalTypedDataPropertyDoc toMutable() =>
      MutableOptionalTypedDataPropertyDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'OptionalTypedDataPropertyDoc',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalTypedDataPropertyDoc
    extends _OptionalTypedDataPropertyDocImplBase {
  ImmutableOptionalTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<Dictionary,
      BoolDict, TypedDictionaryObject<BoolDict>>(ImmutableBoolDict.internal);

  @override
  late final value = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionalTypedDataPropertyDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalTypedDataPropertyDoc].
class MutableOptionalTypedDataPropertyDoc
    extends _OptionalTypedDataPropertyDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<OptionalTypedDataPropertyDoc,
            MutableOptionalTypedDataPropertyDoc> {
  /// Creates a new mutable [OptionalTypedDataPropertyDoc].
  MutableOptionalTypedDataPropertyDoc(
    BoolDict? value,
  ) : super(MutableDocument()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<
      MutableDictionary, MutableBoolDict, BoolDict>(MutableBoolDict.internal);

  late MutableBoolDict? _value = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  MutableBoolDict? get value => _value;

  set value(BoolDict? value) {
    final promoted = value == null ? null : _valueConverter.promote(value);
    _value = promoted;
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: _valueConverter,
    );
  }
}

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$TypedDataPropertyDict
    implements TypedDictionaryObject<MutableTypedDataPropertyDict> {
  BoolDict get value;
}

abstract class _TypedDataPropertyDictImplBase<I extends Dictionary>
    with _$TypedDataPropertyDict
    implements TypedDataPropertyDict {
  _TypedDataPropertyDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableTypedDataPropertyDict toMutable() =>
      MutableTypedDataPropertyDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'TypedDataPropertyDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableTypedDataPropertyDict extends _TypedDataPropertyDictImplBase {
  ImmutableTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<Dictionary,
      BoolDict, TypedDictionaryObject<BoolDict>>(ImmutableBoolDict.internal);

  @override
  late final value = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypedDataPropertyDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [TypedDataPropertyDict].
class MutableTypedDataPropertyDict
    extends _TypedDataPropertyDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<TypedDataPropertyDict,
            MutableTypedDataPropertyDict> {
  /// Creates a new mutable [TypedDataPropertyDict].
  MutableTypedDataPropertyDict(
    BoolDict value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<
      MutableDictionary, MutableBoolDict, BoolDict>(MutableBoolDict.internal);

  late MutableBoolDict _value = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  MutableBoolDict get value => _value;

  set value(BoolDict value) {
    final promoted = _valueConverter.promote(value);
    _value = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: _valueConverter,
    );
  }
}

mixin _$OptionalTypedDataPropertyDict
    implements TypedDictionaryObject<MutableOptionalTypedDataPropertyDict> {
  BoolDict? get value;
}

abstract class _OptionalTypedDataPropertyDictImplBase<I extends Dictionary>
    with _$OptionalTypedDataPropertyDict
    implements OptionalTypedDataPropertyDict {
  _OptionalTypedDataPropertyDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableOptionalTypedDataPropertyDict toMutable() =>
      MutableOptionalTypedDataPropertyDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'OptionalTypedDataPropertyDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalTypedDataPropertyDict
    extends _OptionalTypedDataPropertyDictImplBase {
  ImmutableOptionalTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<Dictionary,
      BoolDict, TypedDictionaryObject<BoolDict>>(ImmutableBoolDict.internal);

  @override
  late final value = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionalTypedDataPropertyDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalTypedDataPropertyDict].
class MutableOptionalTypedDataPropertyDict
    extends _OptionalTypedDataPropertyDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<OptionalTypedDataPropertyDict,
            MutableOptionalTypedDataPropertyDict> {
  /// Creates a new mutable [OptionalTypedDataPropertyDict].
  MutableOptionalTypedDataPropertyDict(
    BoolDict? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter = const TypedDictionaryConverter<
      MutableDictionary, MutableBoolDict, BoolDict>(MutableBoolDict.internal);

  late MutableBoolDict? _value = TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  MutableBoolDict? get value => _value;

  set value(BoolDict? value) {
    final promoted = value == null ? null : _valueConverter.promote(value);
    _value = promoted;
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      converter: _valueConverter,
    );
  }
}
