// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableStringDoc extends _StringDocImplBase {
  ImmutableStringDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [StringDoc].
class MutableStringDoc extends _StringDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<StringDoc, MutableStringDoc> {
  /// Creates a new mutable [StringDoc].
  MutableStringDoc(
    String value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableStringDoc.internal(MutableDocument internal) : super(internal);

  set value(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableIntDoc extends _IntDocImplBase {
  ImmutableIntDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [IntDoc].
class MutableIntDoc extends _IntDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<IntDoc, MutableIntDoc> {
  /// Creates a new mutable [IntDoc].
  MutableIntDoc(
    int value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableIntDoc.internal(MutableDocument internal) : super(internal);

  set value(int value) {
    final promoted = InternalTypedDataHelpers.intConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.intConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDoubleDoc extends _DoubleDocImplBase {
  ImmutableDoubleDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DoubleDoc].
class MutableDoubleDoc extends _DoubleDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<DoubleDoc, MutableDoubleDoc> {
  /// Creates a new mutable [DoubleDoc].
  MutableDoubleDoc(
    double value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableDoubleDoc.internal(MutableDocument internal) : super(internal);

  set value(double value) {
    final promoted = InternalTypedDataHelpers.doubleConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.doubleConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNumDoc extends _NumDocImplBase {
  ImmutableNumDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NumDoc].
class MutableNumDoc extends _NumDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<NumDoc, MutableNumDoc> {
  /// Creates a new mutable [NumDoc].
  MutableNumDoc(
    num value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableNumDoc.internal(MutableDocument internal) : super(internal);

  set value(num value) {
    final promoted = InternalTypedDataHelpers.numConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.numConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBoolDoc extends _BoolDocImplBase {
  ImmutableBoolDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoolDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BoolDoc].
class MutableBoolDoc extends _BoolDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<BoolDoc, MutableBoolDoc> {
  /// Creates a new mutable [BoolDoc].
  MutableBoolDoc(
    bool value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableBoolDoc.internal(MutableDocument internal) : super(internal);

  set value(bool value) {
    final promoted = InternalTypedDataHelpers.boolConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.boolConverter,
    );
  }
}

mixin _$DateTimeDoc implements TypedDocumentObject<MutableDateTimeDoc> {
  DateTime get value;
}

abstract class _DateTimeDocImplBase<I extends Document>
    with _$DateTimeDoc
    implements DateTimeDoc {
  _DateTimeDocImplBase(this.internal);

  @override
  final I internal;

  @override
  DateTime get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.dateTimeConverter,
      );

  @override
  MutableDateTimeDoc toMutable() =>
      MutableDateTimeDoc.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDateTimeDoc extends _DateTimeDocImplBase {
  ImmutableDateTimeDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DateTimeDoc].
class MutableDateTimeDoc extends _DateTimeDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<DateTimeDoc, MutableDateTimeDoc> {
  /// Creates a new mutable [DateTimeDoc].
  MutableDateTimeDoc(
    DateTime value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableDateTimeDoc.internal(MutableDocument internal) : super(internal);

  set value(DateTime value) {
    final promoted = InternalTypedDataHelpers.dateTimeConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.dateTimeConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBlobDoc extends _BlobDocImplBase {
  ImmutableBlobDoc.internal(Document internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlobDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BlobDoc].
class MutableBlobDoc extends _BlobDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<BlobDoc, MutableBlobDoc> {
  /// Creates a new mutable [BlobDoc].
  MutableBlobDoc(
    Blob value,
  ) : super(MutableDocument()) {
    this.value = value;
  }

  MutableBlobDoc.internal(MutableDocument internal) : super(internal);

  set value(Blob value) {
    final promoted = InternalTypedDataHelpers.blobConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.blobConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableStringDict extends _StringDictImplBase {
  ImmutableStringDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [StringDict].
class MutableStringDict extends _StringDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<StringDict, MutableStringDict> {
  /// Creates a new mutable [StringDict].
  MutableStringDict(
    String value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableStringDict.internal(MutableDictionary internal) : super(internal);

  set value(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableIntDict extends _IntDictImplBase {
  ImmutableIntDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [IntDict].
class MutableIntDict extends _IntDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<IntDict, MutableIntDict> {
  /// Creates a new mutable [IntDict].
  MutableIntDict(
    int value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableIntDict.internal(MutableDictionary internal) : super(internal);

  set value(int value) {
    final promoted = InternalTypedDataHelpers.intConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.intConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDoubleDict extends _DoubleDictImplBase {
  ImmutableDoubleDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DoubleDict].
class MutableDoubleDict extends _DoubleDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<DoubleDict, MutableDoubleDict> {
  /// Creates a new mutable [DoubleDict].
  MutableDoubleDict(
    double value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableDoubleDict.internal(MutableDictionary internal) : super(internal);

  set value(double value) {
    final promoted = InternalTypedDataHelpers.doubleConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.doubleConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNumDict extends _NumDictImplBase {
  ImmutableNumDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NumDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NumDict].
class MutableNumDict extends _NumDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<NumDict, MutableNumDict> {
  /// Creates a new mutable [NumDict].
  MutableNumDict(
    num value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableNumDict.internal(MutableDictionary internal) : super(internal);

  set value(num value) {
    final promoted = InternalTypedDataHelpers.numConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.numConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBoolDict extends _BoolDictImplBase {
  ImmutableBoolDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoolDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BoolDict].
class MutableBoolDict extends _BoolDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<BoolDict, MutableBoolDict> {
  /// Creates a new mutable [BoolDict].
  MutableBoolDict(
    bool value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBoolDict.internal(MutableDictionary internal) : super(internal);

  set value(bool value) {
    final promoted = InternalTypedDataHelpers.boolConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.boolConverter,
    );
  }
}

mixin _$DateTimeDict implements TypedDictionaryObject<MutableDateTimeDict> {
  DateTime get value;
}

abstract class _DateTimeDictImplBase<I extends Dictionary>
    with _$DateTimeDict
    implements DateTimeDict {
  _DateTimeDictImplBase(this.internal);

  @override
  final I internal;

  @override
  DateTime get value => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'value',
        key: 'value',
        reviver: InternalTypedDataHelpers.dateTimeConverter,
      );

  @override
  MutableDateTimeDict toMutable() =>
      MutableDateTimeDict.internal(internal.toMutable());
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableDateTimeDict extends _DateTimeDictImplBase {
  ImmutableDateTimeDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [DateTimeDict].
class MutableDateTimeDict extends _DateTimeDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<DateTimeDict, MutableDateTimeDict> {
  /// Creates a new mutable [DateTimeDict].
  MutableDateTimeDict(
    DateTime value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableDateTimeDict.internal(MutableDictionary internal) : super(internal);

  set value(DateTime value) {
    final promoted = InternalTypedDataHelpers.dateTimeConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.dateTimeConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableBlobDict extends _BlobDictImplBase {
  ImmutableBlobDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlobDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [BlobDict].
class MutableBlobDict extends _BlobDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<BlobDict, MutableBlobDict> {
  /// Creates a new mutable [BlobDict].
  MutableBlobDict(
    Blob value,
  ) : super(MutableDictionary()) {
    this.value = value;
  }

  MutableBlobDict.internal(MutableDictionary internal) : super(internal);

  set value(Blob value) {
    final promoted = InternalTypedDataHelpers.blobConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.blobConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNullableIntDict extends _NullableIntDictImplBase {
  ImmutableNullableIntDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NullableIntDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NullableIntDict].
class MutableNullableIntDict extends _NullableIntDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableIntDict, MutableNullableIntDict> {
  /// Creates a new mutable [NullableIntDict].
  MutableNullableIntDict(
    int? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableIntDict.internal(MutableDictionary internal) : super(internal);

  set value(int? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.intConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.intConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNullableDoubleDict extends _NullableDoubleDictImplBase {
  ImmutableNullableDoubleDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NullableDoubleDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NullableDoubleDict].
class MutableNullableDoubleDict
    extends _NullableDoubleDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableDoubleDict,
            MutableNullableDoubleDict> {
  /// Creates a new mutable [NullableDoubleDict].
  MutableNullableDoubleDict(
    double? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableDoubleDict.internal(MutableDictionary internal)
      : super(internal);

  set value(double? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.doubleConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.doubleConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNullableNumDict extends _NullableNumDictImplBase {
  ImmutableNullableNumDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NullableNumDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NullableNumDict].
class MutableNullableNumDict extends _NullableNumDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableNumDict, MutableNullableNumDict> {
  /// Creates a new mutable [NullableNumDict].
  MutableNullableNumDict(
    num? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableNumDict.internal(MutableDictionary internal) : super(internal);

  set value(num? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.numConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.numConverter,
    );
  }
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

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNullableBoolDict extends _NullableBoolDictImplBase {
  ImmutableNullableBoolDict.internal(Dictionary internal) : super(internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NullableBoolDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NullableBoolDict].
class MutableNullableBoolDict
    extends _NullableBoolDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NullableBoolDict,
            MutableNullableBoolDict> {
  /// Creates a new mutable [NullableBoolDict].
  MutableNullableBoolDict(
    bool? value,
  ) : super(MutableDictionary()) {
    if (value != null) {
      this.value = value;
    }
  }

  MutableNullableBoolDict.internal(MutableDictionary internal)
      : super(internal);

  set value(bool? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.boolConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'value',
      value: promoted,
      freezer: InternalTypedDataHelpers.boolConverter,
    );
  }
}
