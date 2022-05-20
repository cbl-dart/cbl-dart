// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'typed_data_list.dart';

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$BoolListDict implements TypedDictionaryObject<MutableBoolListDict> {
  List<bool> get value;
}

abstract class _BoolListDictImplBase<I extends Dictionary>
    with _$BoolListDict
    implements BoolListDict {
  _BoolListDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableBoolListDict toMutable() =>
      MutableBoolListDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'BoolListDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBoolListDict extends _BoolListDictImplBase {
  ImmutableBoolListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: TypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

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
      other is BoolListDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BoolListDict].
class MutableBoolListDict extends _BoolListDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<BoolListDict, MutableBoolListDict> {
  /// Creates a new mutable [BoolListDict].
  MutableBoolListDict(
    List<bool> value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: TypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

  late TypedDataList<bool, bool> _value = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  TypedDataList<bool, bool> get value => _value;

  set value(List<bool> value) {
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

mixin _$OptionalBoolListDict
    implements TypedDictionaryObject<MutableOptionalBoolListDict> {
  List<bool>? get value;
}

abstract class _OptionalBoolListDictImplBase<I extends Dictionary>
    with _$OptionalBoolListDict
    implements OptionalBoolListDict {
  _OptionalBoolListDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableOptionalBoolListDict toMutable() =>
      MutableOptionalBoolListDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'OptionalBoolListDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalBoolListDict extends _OptionalBoolListDictImplBase {
  ImmutableOptionalBoolListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: TypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

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
      other is OptionalBoolListDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalBoolListDict].
class MutableOptionalBoolListDict
    extends _OptionalBoolListDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<OptionalBoolListDict,
            MutableOptionalBoolListDict> {
  /// Creates a new mutable [OptionalBoolListDict].
  MutableOptionalBoolListDict(
    List<bool>? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalBoolListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: TypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

  late TypedDataList<bool, bool>? _value =
      TypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  TypedDataList<bool, bool>? get value => _value;

  set value(List<bool>? value) {
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

mixin _$BoolDictListDict
    implements TypedDictionaryObject<MutableBoolDictListDict> {
  List<BoolDict> get value;
}

abstract class _BoolDictListDictImplBase<I extends Dictionary>
    with _$BoolDictListDict
    implements BoolDictListDict {
  _BoolDictListDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableBoolDictListDict toMutable() =>
      MutableBoolDictListDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'BoolDictListDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBoolDictListDict extends _BoolDictListDictImplBase {
  ImmutableBoolDictListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedDictionaryConverter<Dictionary, BoolDict,
        TypedDictionaryObject<BoolDict>>(ImmutableBoolDict.internal),
    isNullable: false,
    isCached: true,
  );

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
      other is BoolDictListDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BoolDictListDict].
class MutableBoolDictListDict
    extends _BoolDictListDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<BoolDictListDict,
            MutableBoolDictListDict> {
  /// Creates a new mutable [BoolDictListDict].
  MutableBoolDictListDict(
    List<BoolDict> value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolDictListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedDictionaryConverter<MutableDictionary,
        MutableBoolDict, BoolDict>(MutableBoolDict.internal),
    isNullable: false,
    isCached: true,
  );

  late TypedDataList<MutableBoolDict, BoolDict> _value =
      TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  TypedDataList<MutableBoolDict, BoolDict> get value => _value;

  set value(List<BoolDict> value) {
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

mixin _$BoolListListDict
    implements TypedDictionaryObject<MutableBoolListListDict> {
  List<List<bool>> get value;
}

abstract class _BoolListListDictImplBase<I extends Dictionary>
    with _$BoolListListDict
    implements BoolListListDict {
  _BoolListListDictImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableBoolListListDict toMutable() =>
      MutableBoolListListDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'BoolListListDict',
        fields: {
          'value': value,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBoolListListDict extends _BoolListListDictImplBase {
  ImmutableBoolListListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedListConverter(
      converter: TypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
    isNullable: false,
    isCached: true,
  );

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
      other is BoolListListDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BoolListListDict].
class MutableBoolListListDict
    extends _BoolListListDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<BoolListListDict,
            MutableBoolListListDict> {
  /// Creates a new mutable [BoolListListDict].
  MutableBoolListListDict(
    List<List<bool>> value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolListListDict.internal(super.internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedListConverter(
      converter: TypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
    isNullable: false,
    isCached: true,
  );

  late TypedDataList<TypedDataList<bool, bool>, List<bool>> _value =
      TypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    converter: _valueConverter,
  );

  @override
  TypedDataList<TypedDataList<bool, bool>, List<bool>> get value => _value;

  set value(List<List<bool>> value) {
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
