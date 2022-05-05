// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports

part of 'constructor_parameters.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$ParamDoc implements TypedDocumentObject<MutableParamDoc> {
  String get a;
}

abstract class _ParamDocImplBase<I extends Document>
    with _$ParamDoc
    implements ParamDoc {
  _ParamDocImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableParamDoc toMutable() => MutableParamDoc.internal(internal.toMutable());
}

class ImmutableParamDoc extends _ParamDocImplBase {
  ImmutableParamDoc.internal(Document internal) : super(internal);
}

class MutableParamDoc extends _ParamDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<ParamDoc, MutableParamDoc> {
  MutableParamDoc(
    String a,
  ) : super(MutableDocument()) {
    this.a = a;
  }

  MutableParamDoc.internal(MutableDocument internal) : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$OptionalParamDoc
    implements TypedDocumentObject<MutableOptionalParamDoc> {
  String? get a;
}

abstract class _OptionalParamDocImplBase<I extends Document>
    with _$OptionalParamDoc
    implements OptionalParamDoc {
  _OptionalParamDocImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get a => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableOptionalParamDoc toMutable() =>
      MutableOptionalParamDoc.internal(internal.toMutable());
}

class ImmutableOptionalParamDoc extends _OptionalParamDocImplBase {
  ImmutableOptionalParamDoc.internal(Document internal) : super(internal);
}

class MutableOptionalParamDoc extends _OptionalParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<OptionalParamDoc, MutableOptionalParamDoc> {
  MutableOptionalParamDoc([
    String? a,
  ]) : super(MutableDocument()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDoc.internal(MutableDocument internal) : super(internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$PositionalMixedParamDoc
    implements TypedDocumentObject<MutablePositionalMixedParamDoc> {
  String get a;

  String? get b;
}

abstract class _PositionalMixedParamDocImplBase<I extends Document>
    with _$PositionalMixedParamDoc
    implements PositionalMixedParamDoc {
  _PositionalMixedParamDocImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  String? get b => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutablePositionalMixedParamDoc toMutable() =>
      MutablePositionalMixedParamDoc.internal(internal.toMutable());
}

class ImmutablePositionalMixedParamDoc
    extends _PositionalMixedParamDocImplBase {
  ImmutablePositionalMixedParamDoc.internal(Document internal)
      : super(internal);
}

class MutablePositionalMixedParamDoc
    extends _PositionalMixedParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<PositionalMixedParamDoc,
            MutablePositionalMixedParamDoc> {
  MutablePositionalMixedParamDoc(
    String a, [
    String? b,
  ]) : super(MutableDocument()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutablePositionalMixedParamDoc.internal(MutableDocument internal)
      : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedParamDoc implements TypedDocumentObject<MutableNamedParamDoc> {
  String get a;
}

abstract class _NamedParamDocImplBase<I extends Document>
    with _$NamedParamDoc
    implements NamedParamDoc {
  _NamedParamDocImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedParamDoc toMutable() =>
      MutableNamedParamDoc.internal(internal.toMutable());
}

class ImmutableNamedParamDoc extends _NamedParamDocImplBase {
  ImmutableNamedParamDoc.internal(Document internal) : super(internal);
}

class MutableNamedParamDoc extends _NamedParamDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<NamedParamDoc, MutableNamedParamDoc> {
  MutableNamedParamDoc({
    required String a,
  }) : super(MutableDocument()) {
    this.a = a;
  }

  MutableNamedParamDoc.internal(MutableDocument internal) : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedOptionalParamDoc
    implements TypedDocumentObject<MutableNamedOptionalParamDoc> {
  String? get a;
}

abstract class _NamedOptionalParamDocImplBase<I extends Document>
    with _$NamedOptionalParamDoc
    implements NamedOptionalParamDoc {
  _NamedOptionalParamDocImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get a => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedOptionalParamDoc toMutable() =>
      MutableNamedOptionalParamDoc.internal(internal.toMutable());
}

class ImmutableNamedOptionalParamDoc extends _NamedOptionalParamDocImplBase {
  ImmutableNamedOptionalParamDoc.internal(Document internal) : super(internal);
}

class MutableNamedOptionalParamDoc
    extends _NamedOptionalParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<NamedOptionalParamDoc,
            MutableNamedOptionalParamDoc> {
  MutableNamedOptionalParamDoc({
    String? a,
  }) : super(MutableDocument()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDoc.internal(MutableDocument internal)
      : super(internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedMixedParamDoc
    implements TypedDocumentObject<MutableNamedMixedParamDoc> {
  String get a;

  String? get b;
}

abstract class _NamedMixedParamDocImplBase<I extends Document>
    with _$NamedMixedParamDoc
    implements NamedMixedParamDoc {
  _NamedMixedParamDocImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  String? get b => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedMixedParamDoc toMutable() =>
      MutableNamedMixedParamDoc.internal(internal.toMutable());
}

class ImmutableNamedMixedParamDoc extends _NamedMixedParamDocImplBase {
  ImmutableNamedMixedParamDoc.internal(Document internal) : super(internal);
}

class MutableNamedMixedParamDoc
    extends _NamedMixedParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<NamedMixedParamDoc,
            MutableNamedMixedParamDoc> {
  MutableNamedMixedParamDoc(
    String a, {
    String? b,
  }) : super(MutableDocument()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutableNamedMixedParamDoc.internal(MutableDocument internal)
      : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$ParamDict implements TypedDictionaryObject<MutableParamDict> {
  String get a;
}

abstract class _ParamDictImplBase<I extends Dictionary>
    with _$ParamDict
    implements ParamDict {
  _ParamDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableParamDict toMutable() =>
      MutableParamDict.internal(internal.toMutable());
}

class ImmutableParamDict extends _ParamDictImplBase {
  ImmutableParamDict.internal(Dictionary internal) : super(internal);
}

class MutableParamDict extends _ParamDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<ParamDict, MutableParamDict> {
  MutableParamDict(
    String a,
  ) : super(MutableDictionary()) {
    this.a = a;
  }

  MutableParamDict.internal(MutableDictionary internal) : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$OptionalParamDict
    implements TypedDictionaryObject<MutableOptionalParamDict> {
  String? get a;
}

abstract class _OptionalParamDictImplBase<I extends Dictionary>
    with _$OptionalParamDict
    implements OptionalParamDict {
  _OptionalParamDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get a => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableOptionalParamDict toMutable() =>
      MutableOptionalParamDict.internal(internal.toMutable());
}

class ImmutableOptionalParamDict extends _OptionalParamDictImplBase {
  ImmutableOptionalParamDict.internal(Dictionary internal) : super(internal);
}

class MutableOptionalParamDict
    extends _OptionalParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<OptionalParamDict,
            MutableOptionalParamDict> {
  MutableOptionalParamDict([
    String? a,
  ]) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDict.internal(MutableDictionary internal)
      : super(internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$PositionalMixedParamDict
    implements TypedDictionaryObject<MutablePositionalMixedParamDict> {
  String get a;

  String? get b;
}

abstract class _PositionalMixedParamDictImplBase<I extends Dictionary>
    with _$PositionalMixedParamDict
    implements PositionalMixedParamDict {
  _PositionalMixedParamDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  String? get b => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutablePositionalMixedParamDict toMutable() =>
      MutablePositionalMixedParamDict.internal(internal.toMutable());
}

class ImmutablePositionalMixedParamDict
    extends _PositionalMixedParamDictImplBase {
  ImmutablePositionalMixedParamDict.internal(Dictionary internal)
      : super(internal);
}

class MutablePositionalMixedParamDict
    extends _PositionalMixedParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<PositionalMixedParamDict,
            MutablePositionalMixedParamDict> {
  MutablePositionalMixedParamDict(
    String a, [
    String? b,
  ]) : super(MutableDictionary()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutablePositionalMixedParamDict.internal(MutableDictionary internal)
      : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedParamDict implements TypedDictionaryObject<MutableNamedParamDict> {
  String get a;
}

abstract class _NamedParamDictImplBase<I extends Dictionary>
    with _$NamedParamDict
    implements NamedParamDict {
  _NamedParamDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedParamDict toMutable() =>
      MutableNamedParamDict.internal(internal.toMutable());
}

class ImmutableNamedParamDict extends _NamedParamDictImplBase {
  ImmutableNamedParamDict.internal(Dictionary internal) : super(internal);
}

class MutableNamedParamDict extends _NamedParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NamedParamDict, MutableNamedParamDict> {
  MutableNamedParamDict({
    required String a,
  }) : super(MutableDictionary()) {
    this.a = a;
  }

  MutableNamedParamDict.internal(MutableDictionary internal) : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedOptionalParamDict
    implements TypedDictionaryObject<MutableNamedOptionalParamDict> {
  String? get a;
}

abstract class _NamedOptionalParamDictImplBase<I extends Dictionary>
    with _$NamedOptionalParamDict
    implements NamedOptionalParamDict {
  _NamedOptionalParamDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String? get a => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedOptionalParamDict toMutable() =>
      MutableNamedOptionalParamDict.internal(internal.toMutable());
}

class ImmutableNamedOptionalParamDict extends _NamedOptionalParamDictImplBase {
  ImmutableNamedOptionalParamDict.internal(Dictionary internal)
      : super(internal);
}

class MutableNamedOptionalParamDict
    extends _NamedOptionalParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NamedOptionalParamDict,
            MutableNamedOptionalParamDict> {
  MutableNamedOptionalParamDict({
    String? a,
  }) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDict.internal(MutableDictionary internal)
      : super(internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedMixedParamDict
    implements TypedDictionaryObject<MutableNamedMixedParamDict> {
  String get a;

  String? get b;
}

abstract class _NamedMixedParamDictImplBase<I extends Dictionary>
    with _$NamedMixedParamDict
    implements NamedMixedParamDict {
  _NamedMixedParamDictImplBase(this.internal);

  @override
  final I internal;

  @override
  String get a => InternalTypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  String? get b => InternalTypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        reviver: InternalTypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedMixedParamDict toMutable() =>
      MutableNamedMixedParamDict.internal(internal.toMutable());
}

class ImmutableNamedMixedParamDict extends _NamedMixedParamDictImplBase {
  ImmutableNamedMixedParamDict.internal(Dictionary internal) : super(internal);
}

class MutableNamedMixedParamDict
    extends _NamedMixedParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NamedMixedParamDict,
            MutableNamedMixedParamDict> {
  MutableNamedMixedParamDict(
    String a, {
    String? b,
  }) : super(MutableDictionary()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutableNamedMixedParamDict.internal(MutableDictionary internal)
      : super(internal);

  set a(String value) {
    final promoted = InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted = value == null
        ? null
        : InternalTypedDataHelpers.stringConverter.promote(value);
    InternalTypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      freezer: InternalTypedDataHelpers.stringConverter,
    );
  }
}
