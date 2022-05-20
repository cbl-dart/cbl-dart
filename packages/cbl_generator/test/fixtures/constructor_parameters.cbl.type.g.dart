// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableParamDoc toMutable() => MutableParamDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'ParamDoc',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableParamDoc extends _ParamDocImplBase {
  ImmutableParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [ParamDoc].
class MutableParamDoc extends _ParamDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<ParamDoc, MutableParamDoc> {
  /// Creates a new mutable [ParamDoc].
  MutableParamDoc(
    String a,
  ) : super(MutableDocument()) {
    this.a = a;
  }

  MutableParamDoc.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String? get a => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableOptionalParamDoc toMutable() =>
      MutableOptionalParamDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'OptionalParamDoc',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalParamDoc extends _OptionalParamDocImplBase {
  ImmutableOptionalParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionalParamDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalParamDoc].
class MutableOptionalParamDoc extends _OptionalParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<OptionalParamDoc, MutableOptionalParamDoc> {
  /// Creates a new mutable [OptionalParamDoc].
  MutableOptionalParamDoc([
    String? a,
  ]) : super(MutableDocument()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDoc.internal(super.internal);

  set a(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String? get b => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutablePositionalMixedParamDoc toMutable() =>
      MutablePositionalMixedParamDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'PositionalMixedParamDoc',
        fields: {
          'a': a,
          'b': b,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutablePositionalMixedParamDoc
    extends _PositionalMixedParamDocImplBase {
  ImmutablePositionalMixedParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionalMixedParamDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [PositionalMixedParamDoc].
class MutablePositionalMixedParamDoc
    extends _PositionalMixedParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<PositionalMixedParamDoc,
            MutablePositionalMixedParamDoc> {
  /// Creates a new mutable [PositionalMixedParamDoc].
  MutablePositionalMixedParamDoc(
    String a, [
    String? b,
  ]) : super(MutableDocument()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutablePositionalMixedParamDoc.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedParamDoc toMutable() =>
      MutableNamedParamDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'NamedParamDoc',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedParamDoc extends _NamedParamDocImplBase {
  ImmutableNamedParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedParamDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedParamDoc].
class MutableNamedParamDoc extends _NamedParamDocImplBase<MutableDocument>
    implements TypedMutableDocumentObject<NamedParamDoc, MutableNamedParamDoc> {
  /// Creates a new mutable [NamedParamDoc].
  MutableNamedParamDoc({
    required String a,
  }) : super(MutableDocument()) {
    this.a = a;
  }

  MutableNamedParamDoc.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String? get a => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedOptionalParamDoc toMutable() =>
      MutableNamedOptionalParamDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'NamedOptionalParamDoc',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedOptionalParamDoc extends _NamedOptionalParamDocImplBase {
  ImmutableNamedOptionalParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedOptionalParamDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedOptionalParamDoc].
class MutableNamedOptionalParamDoc
    extends _NamedOptionalParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<NamedOptionalParamDoc,
            MutableNamedOptionalParamDoc> {
  /// Creates a new mutable [NamedOptionalParamDoc].
  MutableNamedOptionalParamDoc({
    String? a,
  }) : super(MutableDocument()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDoc.internal(super.internal);

  set a(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String? get b => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedMixedParamDoc toMutable() =>
      MutableNamedMixedParamDoc.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'NamedMixedParamDoc',
        fields: {
          'a': a,
          'b': b,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedMixedParamDoc extends _NamedMixedParamDocImplBase {
  ImmutableNamedMixedParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedMixedParamDoc &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedMixedParamDoc].
class MutableNamedMixedParamDoc
    extends _NamedMixedParamDocImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<NamedMixedParamDoc,
            MutableNamedMixedParamDoc> {
  /// Creates a new mutable [NamedMixedParamDoc].
  MutableNamedMixedParamDoc(
    String a, {
    String? b,
  }) : super(MutableDocument()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutableNamedMixedParamDoc.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableParamDict toMutable() =>
      MutableParamDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'ParamDict',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableParamDict extends _ParamDictImplBase {
  ImmutableParamDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [ParamDict].
class MutableParamDict extends _ParamDictImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<ParamDict, MutableParamDict> {
  /// Creates a new mutable [ParamDict].
  MutableParamDict(
    String a,
  ) : super(MutableDictionary()) {
    this.a = a;
  }

  MutableParamDict.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String? get a => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableOptionalParamDict toMutable() =>
      MutableOptionalParamDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'OptionalParamDict',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalParamDict extends _OptionalParamDictImplBase {
  ImmutableOptionalParamDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionalParamDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalParamDict].
class MutableOptionalParamDict
    extends _OptionalParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<OptionalParamDict,
            MutableOptionalParamDict> {
  /// Creates a new mutable [OptionalParamDict].
  MutableOptionalParamDict([
    String? a,
  ]) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDict.internal(super.internal);

  set a(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String? get b => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutablePositionalMixedParamDict toMutable() =>
      MutablePositionalMixedParamDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'PositionalMixedParamDict',
        fields: {
          'a': a,
          'b': b,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutablePositionalMixedParamDict
    extends _PositionalMixedParamDictImplBase {
  ImmutablePositionalMixedParamDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionalMixedParamDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [PositionalMixedParamDict].
class MutablePositionalMixedParamDict
    extends _PositionalMixedParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<PositionalMixedParamDict,
            MutablePositionalMixedParamDict> {
  /// Creates a new mutable [PositionalMixedParamDict].
  MutablePositionalMixedParamDict(
    String a, [
    String? b,
  ]) : super(MutableDictionary()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutablePositionalMixedParamDict.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedParamDict toMutable() =>
      MutableNamedParamDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'NamedParamDict',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedParamDict extends _NamedParamDictImplBase {
  ImmutableNamedParamDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedParamDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedParamDict].
class MutableNamedParamDict extends _NamedParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NamedParamDict, MutableNamedParamDict> {
  /// Creates a new mutable [NamedParamDict].
  MutableNamedParamDict({
    required String a,
  }) : super(MutableDictionary()) {
    this.a = a;
  }

  MutableNamedParamDict.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String? get a => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedOptionalParamDict toMutable() =>
      MutableNamedOptionalParamDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'NamedOptionalParamDict',
        fields: {
          'a': a,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedOptionalParamDict extends _NamedOptionalParamDictImplBase {
  ImmutableNamedOptionalParamDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedOptionalParamDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedOptionalParamDict].
class MutableNamedOptionalParamDict
    extends _NamedOptionalParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NamedOptionalParamDict,
            MutableNamedOptionalParamDict> {
  /// Creates a new mutable [NamedOptionalParamDict].
  MutableNamedOptionalParamDict({
    String? a,
  }) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDict.internal(super.internal);

  set a(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
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
  String get a => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'a',
        key: 'a',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String? get b => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableNamedMixedParamDict toMutable() =>
      MutableNamedMixedParamDict.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'NamedMixedParamDict',
        fields: {
          'a': a,
          'b': b,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedMixedParamDict extends _NamedMixedParamDictImplBase {
  ImmutableNamedMixedParamDict.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedMixedParamDict &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedMixedParamDict].
class MutableNamedMixedParamDict
    extends _NamedMixedParamDictImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<NamedMixedParamDict,
            MutableNamedMixedParamDict> {
  /// Creates a new mutable [NamedMixedParamDict].
  MutableNamedMixedParamDict(
    String a, {
    String? b,
  }) : super(MutableDictionary()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutableNamedMixedParamDict.internal(super.internal);

  set a(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set b(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}
