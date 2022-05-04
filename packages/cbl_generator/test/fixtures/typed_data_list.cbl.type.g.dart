// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments

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

  @override
  late final value = InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: const TypedListConverter(
      converter: InternalTypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
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

  late List<bool> _value = InternalTypedDataHelpers.readProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: const TypedListConverter(
      converter: InternalTypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
  );

  @override
  List<bool> get value => _value;

  set value(List<bool> value) {
    if (value is! TypedDataList<bool> || value.internal is! MutableArray) {
      value = const TypedListConverter(
        converter: InternalTypedDataHelpers.boolConverter,
        isNullable: false,
        isCached: false,
      ).revive(MutableArray())
        ..addAll(value);
    }
    _value = value;
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: value,
      freezer: const TypedListConverter(
        converter: InternalTypedDataHelpers.boolConverter,
        isNullable: false,
        isCached: false,
      ),
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

  @override
  late final value = InternalTypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: const TypedListConverter(
      converter: InternalTypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
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

  late List<bool>? _value = InternalTypedDataHelpers.readNullableProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    reviver: const TypedListConverter(
      converter: InternalTypedDataHelpers.boolConverter,
      isNullable: false,
      isCached: false,
    ),
  );

  @override
  List<bool>? get value => _value;

  set value(List<bool>? value) {
    if (value != null &&
        (value is! TypedDataList<bool> || value.internal is! MutableArray)) {
      value = const TypedListConverter(
        converter: InternalTypedDataHelpers.boolConverter,
        isNullable: false,
        isCached: false,
      ).revive(MutableArray())
        ..addAll(value);
    }
    _value = value;
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: value,
      freezer: const TypedListConverter(
        converter: InternalTypedDataHelpers.boolConverter,
        isNullable: false,
        isCached: false,
      ),
    );
  }
}
