// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments

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
}

class ImmutableTypedDataPropertyDoc extends _TypedDataPropertyDocImplBase {
  ImmutableTypedDataPropertyDoc.internal(Document internal) : super(internal);

  @override
  late final value = InternalTypedDataHelpers.typedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );
}

class MutableTypedDataPropertyDoc
    extends _TypedDataPropertyDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<TypedDataPropertyDoc,
            MutableTypedDataPropertyDoc> {
  MutableTypedDataPropertyDoc(
    BoolDict value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableTypedDataPropertyDoc.internal(MutableDocument internal)
      : super(internal);

  late BoolDict _value = InternalTypedDataHelpers.mutableTypedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );

  @override
  BoolDict get value => _value;

  set value(BoolDict value) {
    if (value is! MutableBoolDict) {
      value = value.toMutable();
    }
    _value = value;
    internal.setValue(value.internal, key: 'value');
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
}

class ImmutableOptionalTypedDataPropertyDoc
    extends _OptionalTypedDataPropertyDocImplBase {
  ImmutableOptionalTypedDataPropertyDoc.internal(Document internal)
      : super(internal);

  @override
  late final value = InternalTypedDataHelpers.nullableTypedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );
}

class MutableOptionalTypedDataPropertyDoc
    extends _OptionalTypedDataPropertyDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<OptionalTypedDataPropertyDoc,
            MutableOptionalTypedDataPropertyDoc> {
  MutableOptionalTypedDataPropertyDoc(
    BoolDict? value,
  ) : super(MutableDocument()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDoc.internal(MutableDocument internal)
      : super(internal);

  late BoolDict? _value =
      InternalTypedDataHelpers.mutableNullableTypedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );

  @override
  BoolDict? get value => _value;

  set value(BoolDict? value) {
    if (value != null) {
      if (value is! MutableBoolDict) {
        value = value.toMutable();
      }
      _value = value;
      internal.setValue(value.internal, key: 'value');
    } else {
      _value = null;
      internal.removeValue('value');
    }
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
}

class ImmutableTypedDataPropertyDict extends _TypedDataPropertyDictImplBase {
  ImmutableTypedDataPropertyDict.internal(Dictionary internal)
      : super(internal);

  @override
  late final value = InternalTypedDataHelpers.typedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );
}

class MutableTypedDataPropertyDict
    extends _TypedDataPropertyDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<TypedDataPropertyDict,
            MutableTypedDataPropertyDict> {
  MutableTypedDataPropertyDict(
    BoolDict value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableTypedDataPropertyDict.internal(MutableDictionary internal)
      : super(internal);

  late BoolDict _value = InternalTypedDataHelpers.mutableTypedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );

  @override
  BoolDict get value => _value;

  set value(BoolDict value) {
    if (value is! MutableBoolDict) {
      value = value.toMutable();
    }
    _value = value;
    internal.setValue(value.internal, key: 'value');
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
}

class ImmutableOptionalTypedDataPropertyDict
    extends _OptionalTypedDataPropertyDictImplBase {
  ImmutableOptionalTypedDataPropertyDict.internal(Dictionary internal)
      : super(internal);

  @override
  late final value = InternalTypedDataHelpers.nullableTypedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );
}

class MutableOptionalTypedDataPropertyDict
    extends _OptionalTypedDataPropertyDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<OptionalTypedDataPropertyDict,
            MutableOptionalTypedDataPropertyDict> {
  MutableOptionalTypedDataPropertyDict(
    BoolDict? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableOptionalTypedDataPropertyDict.internal(MutableDictionary internal)
      : super(internal);

  late BoolDict? _value =
      InternalTypedDataHelpers.mutableNullableTypedDataProperty(
    internal: internal,
    name: 'value',
    key: 'value',
    factory: ImmutableBoolDict.internal,
  );

  @override
  BoolDict? get value => _value;

  set value(BoolDict? value) {
    if (value != null) {
      if (value is! MutableBoolDict) {
        value = value.toMutable();
      }
      _value = value;
      internal.setValue(value.internal, key: 'value');
    } else {
      _value = null;
      internal.removeValue('value');
    }
  }
}
