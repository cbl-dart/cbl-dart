// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments

part of 'builtin_types.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$StringDoc implements TypedDocumentObject<MutableStringDoc> {
  String get value;
}

abstract class _StringDocImplBase<I extends Document>
    with _$StringDoc
    implements StringDoc {
  _StringDocImplBase(this.internal);

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
  MutableStringDoc toMutable() =>
      MutableStringDoc.internal(internal.toMutable());
}

class ImmutableStringDoc extends _StringDocImplBase {
  ImmutableStringDoc.internal(Document internal) : super(internal);
}

class MutableStringDoc extends _StringDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<StringDoc, MutableStringDoc> {
  MutableStringDoc(
    String value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableStringDoc.internal(MutableDocument internal) : super(internal);

  set value(String value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.stringConverter,
      );
}

mixin _$IntDoc implements TypedDocumentObject<MutableIntDoc> {
  int get value;
}

abstract class _IntDocImplBase<I extends Document>
    with _$IntDoc
    implements IntDoc {
  _IntDocImplBase(this.internal);

  @override
  final I internal;

  @override
  int get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.intConverter,
      );

  @override
  MutableIntDoc toMutable() => MutableIntDoc.internal(internal.toMutable());
}

class ImmutableIntDoc extends _IntDocImplBase {
  ImmutableIntDoc.internal(Document internal) : super(internal);
}

class MutableIntDoc extends _IntDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<IntDoc, MutableIntDoc> {
  MutableIntDoc(
    int value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableIntDoc.internal(MutableDocument internal) : super(internal);

  set value(int value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.intConverter,
      );
}

mixin _$DoubleDoc implements TypedDocumentObject<MutableDoubleDoc> {
  double get value;
}

abstract class _DoubleDocImplBase<I extends Document>
    with _$DoubleDoc
    implements DoubleDoc {
  _DoubleDocImplBase(this.internal);

  @override
  final I internal;

  @override
  double get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.doubleConverter,
      );

  @override
  MutableDoubleDoc toMutable() =>
      MutableDoubleDoc.internal(internal.toMutable());
}

class ImmutableDoubleDoc extends _DoubleDocImplBase {
  ImmutableDoubleDoc.internal(Document internal) : super(internal);
}

class MutableDoubleDoc extends _DoubleDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<DoubleDoc, MutableDoubleDoc> {
  MutableDoubleDoc(
    double value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableDoubleDoc.internal(MutableDocument internal) : super(internal);

  set value(double value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.doubleConverter,
      );
}

mixin _$NumDoc implements TypedDocumentObject<MutableNumDoc> {
  num get value;
}

abstract class _NumDocImplBase<I extends Document>
    with _$NumDoc
    implements NumDoc {
  _NumDocImplBase(this.internal);

  @override
  final I internal;

  @override
  num get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.numConverter,
      );

  @override
  MutableNumDoc toMutable() => MutableNumDoc.internal(internal.toMutable());
}

class ImmutableNumDoc extends _NumDocImplBase {
  ImmutableNumDoc.internal(Document internal) : super(internal);
}

class MutableNumDoc extends _NumDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<NumDoc, MutableNumDoc> {
  MutableNumDoc(
    num value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableNumDoc.internal(MutableDocument internal) : super(internal);

  set value(num value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.numConverter,
      );
}

mixin _$BoolDoc implements TypedDocumentObject<MutableBoolDoc> {
  bool get value;
}

abstract class _BoolDocImplBase<I extends Document>
    with _$BoolDoc
    implements BoolDoc {
  _BoolDocImplBase(this.internal);

  @override
  final I internal;

  @override
  bool get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.boolConverter,
      );

  @override
  MutableBoolDoc toMutable() => MutableBoolDoc.internal(internal.toMutable());
}

class ImmutableBoolDoc extends _BoolDocImplBase {
  ImmutableBoolDoc.internal(Document internal) : super(internal);
}

class MutableBoolDoc extends _BoolDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<BoolDoc, MutableBoolDoc> {
  MutableBoolDoc(
    bool value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableBoolDoc.internal(MutableDocument internal) : super(internal);

  set value(bool value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.boolConverter,
      );
}

mixin _$BlobDoc implements TypedDocumentObject<MutableBlobDoc> {
  Blob get value;
}

abstract class _BlobDocImplBase<I extends Document>
    with _$BlobDoc
    implements BlobDoc {
  _BlobDocImplBase(this.internal);

  @override
  final I internal;

  @override
  Blob get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.blobConverter,
      );

  @override
  MutableBlobDoc toMutable() => MutableBlobDoc.internal(internal.toMutable());
}

class ImmutableBlobDoc extends _BlobDocImplBase {
  ImmutableBlobDoc.internal(Document internal) : super(internal);
}

class MutableBlobDoc extends _BlobDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<BlobDoc, MutableBlobDoc> {
  MutableBlobDoc(
    Blob value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableBlobDoc.internal(MutableDocument internal) : super(internal);

  set value(Blob value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.blobConverter,
      );
}

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$StringDict implements TypedDictionaryObject<MutableStringDict> {
  String get value;
}

abstract class _StringDictImplBase<I extends Dictionary>
    with _$StringDict
    implements StringDict {
  _StringDictImplBase(this.internal);

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
  MutableStringDict toMutable() =>
      MutableStringDict.internal(internal.toMutable());
}

class ImmutableStringDict extends _StringDictImplBase {
  ImmutableStringDict.internal(Dictionary internal) : super(internal);
}

class MutableStringDict extends _StringDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<StringDict, MutableStringDict> {
  MutableStringDict(
    String value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableStringDict.internal(MutableDictionary internal) : super(internal);

  set value(String value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.stringConverter,
      );
}

mixin _$IntDict implements TypedDictionaryObject<MutableIntDict> {
  int get value;
}

abstract class _IntDictImplBase<I extends Dictionary>
    with _$IntDict
    implements IntDict {
  _IntDictImplBase(this.internal);

  @override
  final I internal;

  @override
  int get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.intConverter,
      );

  @override
  MutableIntDict toMutable() => MutableIntDict.internal(internal.toMutable());
}

class ImmutableIntDict extends _IntDictImplBase {
  ImmutableIntDict.internal(Dictionary internal) : super(internal);
}

class MutableIntDict extends _IntDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<IntDict, MutableIntDict> {
  MutableIntDict(
    int value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableIntDict.internal(MutableDictionary internal) : super(internal);

  set value(int value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.intConverter,
      );
}

mixin _$DoubleDict implements TypedDictionaryObject<MutableDoubleDict> {
  double get value;
}

abstract class _DoubleDictImplBase<I extends Dictionary>
    with _$DoubleDict
    implements DoubleDict {
  _DoubleDictImplBase(this.internal);

  @override
  final I internal;

  @override
  double get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.doubleConverter,
      );

  @override
  MutableDoubleDict toMutable() =>
      MutableDoubleDict.internal(internal.toMutable());
}

class ImmutableDoubleDict extends _DoubleDictImplBase {
  ImmutableDoubleDict.internal(Dictionary internal) : super(internal);
}

class MutableDoubleDict extends _DoubleDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<DoubleDict, MutableDoubleDict> {
  MutableDoubleDict(
    double value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableDoubleDict.internal(MutableDictionary internal) : super(internal);

  set value(double value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.doubleConverter,
      );
}

mixin _$NumDict implements TypedDictionaryObject<MutableNumDict> {
  num get value;
}

abstract class _NumDictImplBase<I extends Dictionary>
    with _$NumDict
    implements NumDict {
  _NumDictImplBase(this.internal);

  @override
  final I internal;

  @override
  num get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.numConverter,
      );

  @override
  MutableNumDict toMutable() => MutableNumDict.internal(internal.toMutable());
}

class ImmutableNumDict extends _NumDictImplBase {
  ImmutableNumDict.internal(Dictionary internal) : super(internal);
}

class MutableNumDict extends _NumDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<NumDict, MutableNumDict> {
  MutableNumDict(
    num value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableNumDict.internal(MutableDictionary internal) : super(internal);

  set value(num value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.numConverter,
      );
}

mixin _$BoolDict implements TypedDictionaryObject<MutableBoolDict> {
  bool get value;
}

abstract class _BoolDictImplBase<I extends Dictionary>
    with _$BoolDict
    implements BoolDict {
  _BoolDictImplBase(this.internal);

  @override
  final I internal;

  @override
  bool get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.boolConverter,
      );

  @override
  MutableBoolDict toMutable() => MutableBoolDict.internal(internal.toMutable());
}

class ImmutableBoolDict extends _BoolDictImplBase {
  ImmutableBoolDict.internal(Dictionary internal) : super(internal);
}

class MutableBoolDict extends _BoolDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<BoolDict, MutableBoolDict> {
  MutableBoolDict(
    bool value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolDict.internal(MutableDictionary internal) : super(internal);

  set value(bool value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.boolConverter,
      );
}

mixin _$BlobDict implements TypedDictionaryObject<MutableBlobDict> {
  Blob get value;
}

abstract class _BlobDictImplBase<I extends Dictionary>
    with _$BlobDict
    implements BlobDict {
  _BlobDictImplBase(this.internal);

  @override
  final I internal;

  @override
  Blob get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.blobConverter,
      );

  @override
  MutableBlobDict toMutable() => MutableBlobDict.internal(internal.toMutable());
}

class ImmutableBlobDict extends _BlobDictImplBase {
  ImmutableBlobDict.internal(Dictionary internal) : super(internal);
}

class MutableBlobDict extends _BlobDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<BlobDict, MutableBlobDict> {
  MutableBlobDict(
    Blob value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBlobDict.internal(MutableDictionary internal) : super(internal);

  set value(Blob value) => InternalTypedDataHelpers.writeProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.blobConverter,
      );
}

mixin _$NullableIntDict
    implements TypedDictionaryObject<MutableNullableIntDict> {
  int? get value;
}

abstract class _NullableIntDictImplBase<I extends Dictionary>
    with _$NullableIntDict
    implements NullableIntDict {
  _NullableIntDictImplBase(this.internal);

  @override
  final I internal;

  @override
  int? get value => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.intConverter,
      );

  @override
  MutableNullableIntDict toMutable() =>
      MutableNullableIntDict.internal(internal.toMutable());
}

class ImmutableNullableIntDict extends _NullableIntDictImplBase {
  ImmutableNullableIntDict.internal(Dictionary internal) : super(internal);
}

class MutableNullableIntDict extends _NullableIntDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableIntDict, MutableNullableIntDict> {
  MutableNullableIntDict(
    int? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableIntDict.internal(MutableDictionary internal) : super(internal);

  set value(int? value) => InternalTypedDataHelpers.writeNullableProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.intConverter,
      );
}

mixin _$NullableDoubleDict
    implements TypedDictionaryObject<MutableNullableDoubleDict> {
  double? get value;
}

abstract class _NullableDoubleDictImplBase<I extends Dictionary>
    with _$NullableDoubleDict
    implements NullableDoubleDict {
  _NullableDoubleDictImplBase(this.internal);

  @override
  final I internal;

  @override
  double? get value => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.doubleConverter,
      );

  @override
  MutableNullableDoubleDict toMutable() =>
      MutableNullableDoubleDict.internal(internal.toMutable());
}

class ImmutableNullableDoubleDict extends _NullableDoubleDictImplBase {
  ImmutableNullableDoubleDict.internal(Dictionary internal) : super(internal);
}

class MutableNullableDoubleDict
    extends _NullableDoubleDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableDoubleDict,
            MutableNullableDoubleDict> {
  MutableNullableDoubleDict(
    double? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableDoubleDict.internal(MutableDictionary internal)
      : super(internal);

  set value(double? value) => InternalTypedDataHelpers.writeNullableProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.doubleConverter,
      );
}

mixin _$NullableNumDict
    implements TypedDictionaryObject<MutableNullableNumDict> {
  num? get value;
}

abstract class _NullableNumDictImplBase<I extends Dictionary>
    with _$NullableNumDict
    implements NullableNumDict {
  _NullableNumDictImplBase(this.internal);

  @override
  final I internal;

  @override
  num? get value => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.numConverter,
      );

  @override
  MutableNullableNumDict toMutable() =>
      MutableNullableNumDict.internal(internal.toMutable());
}

class ImmutableNullableNumDict extends _NullableNumDictImplBase {
  ImmutableNullableNumDict.internal(Dictionary internal) : super(internal);
}

class MutableNullableNumDict extends _NullableNumDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableNumDict, MutableNullableNumDict> {
  MutableNullableNumDict(
    num? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableNumDict.internal(MutableDictionary internal) : super(internal);

  set value(num? value) => InternalTypedDataHelpers.writeNullableProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.numConverter,
      );
}

mixin _$NullableBoolDict
    implements TypedDictionaryObject<MutableNullableBoolDict> {
  bool? get value;
}

abstract class _NullableBoolDictImplBase<I extends Dictionary>
    with _$NullableBoolDict
    implements NullableBoolDict {
  _NullableBoolDictImplBase(this.internal);

  @override
  final I internal;

  @override
  bool? get value => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.boolConverter,
      );

  @override
  MutableNullableBoolDict toMutable() =>
      MutableNullableBoolDict.internal(internal.toMutable());
}

class ImmutableNullableBoolDict extends _NullableBoolDictImplBase {
  ImmutableNullableBoolDict.internal(Dictionary internal) : super(internal);
}

class MutableNullableBoolDict
    extends _NullableBoolDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableBoolDict,
            MutableNullableBoolDict> {
  MutableNullableBoolDict(
    bool? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableBoolDict.internal(MutableDictionary internal)
      : super(internal);

  set value(bool? value) => InternalTypedDataHelpers.writeNullableProperty(
        internal: internal,
        key: 'value',
        value: value,
        freezer: InternalTypedDataHelpers.boolConverter,
      );
}
