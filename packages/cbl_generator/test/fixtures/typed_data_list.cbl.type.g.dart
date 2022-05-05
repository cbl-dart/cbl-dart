// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports

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
}

class ImmutableBoolListDict extends _BoolListDictImplBase {
  ImmutableBoolListDict.internal(Dictionary internal) : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: InternalTypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

  @override
  late final value = InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );
}

class MutableBoolListDict extends _BoolListDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<BoolListDict, MutableBoolListDict> {
  MutableBoolListDict(
    List<bool> value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolListDict.internal(MutableDictionary internal) : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: InternalTypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

  late TypedDataList<bool, bool> _value = InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );

  @override
  TypedDataList<bool, bool> get value => _value;

  set value(List<bool> value) {
    final promoted = _valueConverter.promote(value);
    _value = promoted;
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: _valueConverter,
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
}

class ImmutableOptionalBoolListDict extends _OptionalBoolListDictImplBase {
  ImmutableOptionalBoolListDict.internal(Dictionary internal) : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: InternalTypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

  @override
  late final value = InternalTypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );
}

class MutableOptionalBoolListDict
    extends _OptionalBoolListDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<OptionalBoolListDict,
            MutableOptionalBoolListDict> {
  MutableOptionalBoolListDict(
    List<bool>? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalBoolListDict.internal(MutableDictionary internal)
      : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: InternalTypedDataHelpers.boolConverter,
    isNullable: false,
    isCached: false,
  );

  late TypedDataList<bool, bool>? _value =
      InternalTypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );

  @override
  TypedDataList<bool, bool>? get value => _value;

  set value(List<bool>? value) {
    final promoted = value == null ? null : _valueConverter.promote(value);
    _value = promoted;
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: _valueConverter,
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
}

class ImmutableBoolDictListDict extends _BoolDictListDictImplBase {
  ImmutableBoolDictListDict.internal(Dictionary internal) : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedDictionaryConverter<Dictionary, BoolDict,
        TypedDictionaryObject<BoolDict>>(ImmutableBoolDict.internal),
    isNullable: false,
    isCached: true,
  );

  @override
  late final value = InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );
}

class MutableBoolDictListDict
    extends _BoolDictListDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<BoolDictListDict,
            MutableBoolDictListDict> {
  MutableBoolDictListDict(
    List<BoolDict> value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolDictListDict.internal(MutableDictionary internal)
      : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedDictionaryConverter<MutableDictionary,
        MutableBoolDict, BoolDict>(MutableBoolDict.internal),
    isNullable: false,
    isCached: true,
  );

  late TypedDataList<MutableBoolDict, BoolDict> _value =
      InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );

  @override
  TypedDataList<MutableBoolDict, BoolDict> get value => _value;

  set value(List<BoolDict> value) {
    final promoted = _valueConverter.promote(value);
    _value = promoted;
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: _valueConverter,
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
}

class ImmutableBoolListListDict extends _BoolListListDictImplBase {
  ImmutableBoolListListDict.internal(Dictionary internal) : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedListConverter(
      converter: InternalTypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
    isNullable: false,
    isCached: true,
  );

  @override
  late final value = InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );
}

class MutableBoolListListDict
    extends _BoolListListDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<BoolListListDict,
            MutableBoolListListDict> {
  MutableBoolListListDict(
    List<List<bool>> value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolListListDict.internal(MutableDictionary internal)
      : super(internal);

  static const _valueConverter = const TypedListConverter(
    converter: const TypedListConverter(
      converter: InternalTypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
    isNullable: false,
    isCached: true,
  );

  late TypedDataList<TypedDataList<bool, bool>, List<bool>> _value =
      InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: _valueConverter,
  );

  @override
  TypedDataList<TypedDataList<bool, bool>, List<bool>> get value => _value;

  set value(List<List<bool>> value) {
    final promoted = _valueConverter.promote(value);
    _value = promoted;
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: _valueConverter,
    );
  }
}
