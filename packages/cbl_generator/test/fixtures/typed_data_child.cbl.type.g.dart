// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'typed_data_child.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$TypedDataPropertyDoc {
  BoolDict get value;
}

abstract class TypedDataPropertyDocDocument
    implements
        TypedDataPropertyDoc,
        TypedDocumentObject<MutableTypedDataPropertyDoc> {}

abstract class _TypedDataPropertyDocDocumentImplBase<I extends Document>
    with _$TypedDataPropertyDoc
    implements TypedDataPropertyDocDocument {
  _TypedDataPropertyDocDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableTypedDataPropertyDoc toMutable() =>
      MutableTypedDataPropertyDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'TypedDataPropertyDoc',
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableTypedDataPropertyDoc
    extends _TypedDataPropertyDocDocumentImplBase {
  ImmutableTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        Dictionary,
        BoolDict,
        TypedDictionaryObject<BoolDict>
      >(ImmutableBoolDict.internal);

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
      other is TypedDataPropertyDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [TypedDataPropertyDoc].
class MutableTypedDataPropertyDoc
    extends _TypedDataPropertyDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          TypedDataPropertyDocDocument,
          MutableTypedDataPropertyDoc
        > {
  /// Creates a new mutable [TypedDataPropertyDoc].
  MutableTypedDataPropertyDoc(BoolDict value) : super(MutableDocument({})) {
    this.value = value;
  }

  MutableTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        MutableDictionary,
        MutableBoolDict,
        BoolDict
      >(MutableBoolDict.internal);

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

mixin _$TypedDataPropertyDocDictionary
    implements TypedDictionaryObject<MutableTypedDataPropertyDocDictionary> {
  BoolDict get value;
}

abstract class TypedDataPropertyDocDictionary
    with _$TypedDataPropertyDocDictionary
    implements TypedDataPropertyDoc {}

abstract class _TypedDataPropertyDocDictionaryImplBase<I extends Dictionary>
    with _$TypedDataPropertyDocDictionary
    implements TypedDataPropertyDocDictionary {
  _TypedDataPropertyDocDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableTypedDataPropertyDocDictionary toMutable() =>
      MutableTypedDataPropertyDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'TypedDataPropertyDocDictionary',
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableTypedDataPropertyDocDictionary
    extends _TypedDataPropertyDocDictionaryImplBase {
  ImmutableTypedDataPropertyDocDictionary.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        Dictionary,
        BoolDict,
        TypedDictionaryObject<BoolDict>
      >(ImmutableBoolDict.internal);

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
      other is TypedDataPropertyDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [TypedDataPropertyDocDictionary].
class MutableTypedDataPropertyDocDictionary
    extends _TypedDataPropertyDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          TypedDataPropertyDocDictionary,
          MutableTypedDataPropertyDocDictionary
        > {
  /// Creates a new mutable [TypedDataPropertyDocDictionary].
  MutableTypedDataPropertyDocDictionary(BoolDict value)
    : super(MutableDictionary()) {
    this.value = value;
  }

  MutableTypedDataPropertyDocDictionary.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        MutableDictionary,
        MutableBoolDict,
        BoolDict
      >(MutableBoolDict.internal);

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

mixin _$OptionalTypedDataPropertyDoc {
  BoolDict? get value;
}

abstract class OptionalTypedDataPropertyDocDocument
    implements
        OptionalTypedDataPropertyDoc,
        TypedDocumentObject<MutableOptionalTypedDataPropertyDoc> {}

abstract class _OptionalTypedDataPropertyDocDocumentImplBase<I extends Document>
    with _$OptionalTypedDataPropertyDoc
    implements OptionalTypedDataPropertyDocDocument {
  _OptionalTypedDataPropertyDocDocumentImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableOptionalTypedDataPropertyDoc toMutable() =>
      MutableOptionalTypedDataPropertyDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'OptionalTypedDataPropertyDoc',
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalTypedDataPropertyDoc
    extends _OptionalTypedDataPropertyDocDocumentImplBase {
  ImmutableOptionalTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        Dictionary,
        BoolDict,
        TypedDictionaryObject<BoolDict>
      >(ImmutableBoolDict.internal);

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
      other is OptionalTypedDataPropertyDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalTypedDataPropertyDoc].
class MutableOptionalTypedDataPropertyDoc
    extends _OptionalTypedDataPropertyDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          OptionalTypedDataPropertyDocDocument,
          MutableOptionalTypedDataPropertyDoc
        > {
  /// Creates a new mutable [OptionalTypedDataPropertyDoc].
  MutableOptionalTypedDataPropertyDoc(BoolDict? value)
    : super(MutableDocument({})) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDoc.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        MutableDictionary,
        MutableBoolDict,
        BoolDict
      >(MutableBoolDict.internal);

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

mixin _$OptionalTypedDataPropertyDocDictionary
    implements
        TypedDictionaryObject<MutableOptionalTypedDataPropertyDocDictionary> {
  BoolDict? get value;
}

abstract class OptionalTypedDataPropertyDocDictionary
    with _$OptionalTypedDataPropertyDocDictionary
    implements OptionalTypedDataPropertyDoc {}

abstract class _OptionalTypedDataPropertyDocDictionaryImplBase<
  I extends Dictionary
>
    with _$OptionalTypedDataPropertyDocDictionary
    implements OptionalTypedDataPropertyDocDictionary {
  _OptionalTypedDataPropertyDocDictionaryImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableOptionalTypedDataPropertyDocDictionary toMutable() =>
      MutableOptionalTypedDataPropertyDocDictionary.internal(
        internal.toMutable(),
      );

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'OptionalTypedDataPropertyDocDictionary',
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalTypedDataPropertyDocDictionary
    extends _OptionalTypedDataPropertyDocDictionaryImplBase {
  ImmutableOptionalTypedDataPropertyDocDictionary.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        Dictionary,
        BoolDict,
        TypedDictionaryObject<BoolDict>
      >(ImmutableBoolDict.internal);

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
      other is OptionalTypedDataPropertyDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalTypedDataPropertyDocDictionary].
class MutableOptionalTypedDataPropertyDocDictionary
    extends _OptionalTypedDataPropertyDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          OptionalTypedDataPropertyDocDictionary,
          MutableOptionalTypedDataPropertyDocDictionary
        > {
  /// Creates a new mutable [OptionalTypedDataPropertyDocDictionary].
  MutableOptionalTypedDataPropertyDocDictionary(BoolDict? value)
    : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDocDictionary.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        MutableDictionary,
        MutableBoolDict,
        BoolDict
      >(MutableBoolDict.internal);

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
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableTypedDataPropertyDict extends _TypedDataPropertyDictImplBase {
  ImmutableTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        Dictionary,
        BoolDict,
        TypedDictionaryObject<BoolDict>
      >(ImmutableBoolDict.internal);

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
        TypedMutableDictionaryObject<
          TypedDataPropertyDict,
          MutableTypedDataPropertyDict
        > {
  /// Creates a new mutable [TypedDataPropertyDict].
  MutableTypedDataPropertyDict(BoolDict value) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        MutableDictionary,
        MutableBoolDict,
        BoolDict
      >(MutableBoolDict.internal);

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
    fields: {'value': value},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalTypedDataPropertyDict
    extends _OptionalTypedDataPropertyDictImplBase {
  ImmutableOptionalTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        Dictionary,
        BoolDict,
        TypedDictionaryObject<BoolDict>
      >(ImmutableBoolDict.internal);

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
        TypedMutableDictionaryObject<
          OptionalTypedDataPropertyDict,
          MutableOptionalTypedDataPropertyDict
        > {
  /// Creates a new mutable [OptionalTypedDataPropertyDict].
  MutableOptionalTypedDataPropertyDict(BoolDict? value)
    : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDict.internal(super.internal);

  static const _valueConverter =
      const TypedDictionaryConverter<
        MutableDictionary,
        MutableBoolDict,
        BoolDict
      >(MutableBoolDict.internal);

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
