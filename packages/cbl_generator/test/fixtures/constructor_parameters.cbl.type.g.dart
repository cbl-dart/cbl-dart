// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'constructor_parameters.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$ParamDoc {
  String get a;
}

abstract class ParamDocDocument
    implements ParamDoc, TypedDocumentObject<MutableParamDoc> {}

abstract class _ParamDocDocumentImplBase<I extends Document>
    with _$ParamDoc
    implements ParamDocDocument {
  _ParamDocDocumentImplBase(this.internal);

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
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableParamDoc extends _ParamDocDocumentImplBase {
  ImmutableParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [ParamDoc].
class MutableParamDoc extends _ParamDocDocumentImplBase<MutableDocument>
    implements TypedMutableDocumentObject<ParamDocDocument, MutableParamDoc> {
  /// Creates a new mutable [ParamDoc].
  MutableParamDoc(String a) : super(MutableDocument({})) {
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

mixin _$ParamDocDictionary
    implements TypedDictionaryObject<MutableParamDocDictionary> {
  String get a;
}

abstract class ParamDocDictionary
    with _$ParamDocDictionary
    implements ParamDoc {}

abstract class _ParamDocDictionaryImplBase<I extends Dictionary>
    with _$ParamDocDictionary
    implements ParamDocDictionary {
  _ParamDocDictionaryImplBase(this.internal);

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
  MutableParamDocDictionary toMutable() =>
      MutableParamDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'ParamDocDictionary',
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableParamDocDictionary extends _ParamDocDictionaryImplBase {
  ImmutableParamDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [ParamDocDictionary].
class MutableParamDocDictionary
    extends _ParamDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          ParamDocDictionary,
          MutableParamDocDictionary
        > {
  /// Creates a new mutable [ParamDocDictionary].
  MutableParamDocDictionary(String a) : super(MutableDictionary()) {
    this.a = a;
  }

  MutableParamDocDictionary.internal(super.internal);

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

mixin _$OptionalParamDoc {
  String? get a;
}

abstract class OptionalParamDocDocument
    implements OptionalParamDoc, TypedDocumentObject<MutableOptionalParamDoc> {}

abstract class _OptionalParamDocDocumentImplBase<I extends Document>
    with _$OptionalParamDoc
    implements OptionalParamDocDocument {
  _OptionalParamDocDocumentImplBase(this.internal);

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
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalParamDoc extends _OptionalParamDocDocumentImplBase {
  ImmutableOptionalParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionalParamDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalParamDoc].
class MutableOptionalParamDoc
    extends _OptionalParamDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          OptionalParamDocDocument,
          MutableOptionalParamDoc
        > {
  /// Creates a new mutable [OptionalParamDoc].
  MutableOptionalParamDoc([String? a]) : super(MutableDocument({})) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDoc.internal(super.internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$OptionalParamDocDictionary
    implements TypedDictionaryObject<MutableOptionalParamDocDictionary> {
  String? get a;
}

abstract class OptionalParamDocDictionary
    with _$OptionalParamDocDictionary
    implements OptionalParamDoc {}

abstract class _OptionalParamDocDictionaryImplBase<I extends Dictionary>
    with _$OptionalParamDocDictionary
    implements OptionalParamDocDictionary {
  _OptionalParamDocDictionaryImplBase(this.internal);

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
  MutableOptionalParamDocDictionary toMutable() =>
      MutableOptionalParamDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'OptionalParamDocDictionary',
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableOptionalParamDocDictionary
    extends _OptionalParamDocDictionaryImplBase {
  ImmutableOptionalParamDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptionalParamDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [OptionalParamDocDictionary].
class MutableOptionalParamDocDictionary
    extends _OptionalParamDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          OptionalParamDocDictionary,
          MutableOptionalParamDocDictionary
        > {
  /// Creates a new mutable [OptionalParamDocDictionary].
  MutableOptionalParamDocDictionary([String? a]) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDocDictionary.internal(super.internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$PositionalMixedParamDoc {
  String get a;

  String? get b;
}

abstract class PositionalMixedParamDocDocument
    implements
        PositionalMixedParamDoc,
        TypedDocumentObject<MutablePositionalMixedParamDoc> {}

abstract class _PositionalMixedParamDocDocumentImplBase<I extends Document>
    with _$PositionalMixedParamDoc
    implements PositionalMixedParamDocDocument {
  _PositionalMixedParamDocDocumentImplBase(this.internal);

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
    fields: {'a': a, 'b': b},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutablePositionalMixedParamDoc
    extends _PositionalMixedParamDocDocumentImplBase {
  ImmutablePositionalMixedParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionalMixedParamDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [PositionalMixedParamDoc].
class MutablePositionalMixedParamDoc
    extends _PositionalMixedParamDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          PositionalMixedParamDocDocument,
          MutablePositionalMixedParamDoc
        > {
  /// Creates a new mutable [PositionalMixedParamDoc].
  MutablePositionalMixedParamDoc(String a, [String? b])
    : super(MutableDocument({})) {
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
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$PositionalMixedParamDocDictionary
    implements TypedDictionaryObject<MutablePositionalMixedParamDocDictionary> {
  String get a;

  String? get b;
}

abstract class PositionalMixedParamDocDictionary
    with _$PositionalMixedParamDocDictionary
    implements PositionalMixedParamDoc {}

abstract class _PositionalMixedParamDocDictionaryImplBase<I extends Dictionary>
    with _$PositionalMixedParamDocDictionary
    implements PositionalMixedParamDocDictionary {
  _PositionalMixedParamDocDictionaryImplBase(this.internal);

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
  MutablePositionalMixedParamDocDictionary toMutable() =>
      MutablePositionalMixedParamDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'PositionalMixedParamDocDictionary',
    fields: {'a': a, 'b': b},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutablePositionalMixedParamDocDictionary
    extends _PositionalMixedParamDocDictionaryImplBase {
  ImmutablePositionalMixedParamDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionalMixedParamDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [PositionalMixedParamDocDictionary].
class MutablePositionalMixedParamDocDictionary
    extends _PositionalMixedParamDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          PositionalMixedParamDocDictionary,
          MutablePositionalMixedParamDocDictionary
        > {
  /// Creates a new mutable [PositionalMixedParamDocDictionary].
  MutablePositionalMixedParamDocDictionary(String a, [String? b])
    : super(MutableDictionary()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutablePositionalMixedParamDocDictionary.internal(super.internal);

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
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedParamDoc {
  String get a;
}

abstract class NamedParamDocDocument
    implements NamedParamDoc, TypedDocumentObject<MutableNamedParamDoc> {}

abstract class _NamedParamDocDocumentImplBase<I extends Document>
    with _$NamedParamDoc
    implements NamedParamDocDocument {
  _NamedParamDocDocumentImplBase(this.internal);

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
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedParamDoc extends _NamedParamDocDocumentImplBase {
  ImmutableNamedParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedParamDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedParamDoc].
class MutableNamedParamDoc
    extends _NamedParamDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          NamedParamDocDocument,
          MutableNamedParamDoc
        > {
  /// Creates a new mutable [NamedParamDoc].
  MutableNamedParamDoc({required String a}) : super(MutableDocument({})) {
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

mixin _$NamedParamDocDictionary
    implements TypedDictionaryObject<MutableNamedParamDocDictionary> {
  String get a;
}

abstract class NamedParamDocDictionary
    with _$NamedParamDocDictionary
    implements NamedParamDoc {}

abstract class _NamedParamDocDictionaryImplBase<I extends Dictionary>
    with _$NamedParamDocDictionary
    implements NamedParamDocDictionary {
  _NamedParamDocDictionaryImplBase(this.internal);

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
  MutableNamedParamDocDictionary toMutable() =>
      MutableNamedParamDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'NamedParamDocDictionary',
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedParamDocDictionary
    extends _NamedParamDocDictionaryImplBase {
  ImmutableNamedParamDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedParamDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedParamDocDictionary].
class MutableNamedParamDocDictionary
    extends _NamedParamDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          NamedParamDocDictionary,
          MutableNamedParamDocDictionary
        > {
  /// Creates a new mutable [NamedParamDocDictionary].
  MutableNamedParamDocDictionary({required String a})
    : super(MutableDictionary()) {
    this.a = a;
  }

  MutableNamedParamDocDictionary.internal(super.internal);

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

mixin _$NamedOptionalParamDoc {
  String? get a;
}

abstract class NamedOptionalParamDocDocument
    implements
        NamedOptionalParamDoc,
        TypedDocumentObject<MutableNamedOptionalParamDoc> {}

abstract class _NamedOptionalParamDocDocumentImplBase<I extends Document>
    with _$NamedOptionalParamDoc
    implements NamedOptionalParamDocDocument {
  _NamedOptionalParamDocDocumentImplBase(this.internal);

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
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedOptionalParamDoc
    extends _NamedOptionalParamDocDocumentImplBase {
  ImmutableNamedOptionalParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedOptionalParamDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedOptionalParamDoc].
class MutableNamedOptionalParamDoc
    extends _NamedOptionalParamDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          NamedOptionalParamDocDocument,
          MutableNamedOptionalParamDoc
        > {
  /// Creates a new mutable [NamedOptionalParamDoc].
  MutableNamedOptionalParamDoc({String? a}) : super(MutableDocument({})) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDoc.internal(super.internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedOptionalParamDocDictionary
    implements TypedDictionaryObject<MutableNamedOptionalParamDocDictionary> {
  String? get a;
}

abstract class NamedOptionalParamDocDictionary
    with _$NamedOptionalParamDocDictionary
    implements NamedOptionalParamDoc {}

abstract class _NamedOptionalParamDocDictionaryImplBase<I extends Dictionary>
    with _$NamedOptionalParamDocDictionary
    implements NamedOptionalParamDocDictionary {
  _NamedOptionalParamDocDictionaryImplBase(this.internal);

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
  MutableNamedOptionalParamDocDictionary toMutable() =>
      MutableNamedOptionalParamDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'NamedOptionalParamDocDictionary',
    fields: {'a': a},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedOptionalParamDocDictionary
    extends _NamedOptionalParamDocDictionaryImplBase {
  ImmutableNamedOptionalParamDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedOptionalParamDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedOptionalParamDocDictionary].
class MutableNamedOptionalParamDocDictionary
    extends _NamedOptionalParamDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          NamedOptionalParamDocDictionary,
          MutableNamedOptionalParamDocDictionary
        > {
  /// Creates a new mutable [NamedOptionalParamDocDictionary].
  MutableNamedOptionalParamDocDictionary({String? a})
    : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDocDictionary.internal(super.internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'a',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedMixedParamDoc {
  String get a;

  String? get b;
}

abstract class NamedMixedParamDocDocument
    implements
        NamedMixedParamDoc,
        TypedDocumentObject<MutableNamedMixedParamDoc> {}

abstract class _NamedMixedParamDocDocumentImplBase<I extends Document>
    with _$NamedMixedParamDoc
    implements NamedMixedParamDocDocument {
  _NamedMixedParamDocDocumentImplBase(this.internal);

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
    fields: {'a': a, 'b': b},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedMixedParamDoc extends _NamedMixedParamDocDocumentImplBase {
  ImmutableNamedMixedParamDoc.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedMixedParamDocDocument &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedMixedParamDoc].
class MutableNamedMixedParamDoc
    extends _NamedMixedParamDocDocumentImplBase<MutableDocument>
    implements
        TypedMutableDocumentObject<
          NamedMixedParamDocDocument,
          MutableNamedMixedParamDoc
        > {
  /// Creates a new mutable [NamedMixedParamDoc].
  MutableNamedMixedParamDoc(String a, {String? b})
    : super(MutableDocument({})) {
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
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}

mixin _$NamedMixedParamDocDictionary
    implements TypedDictionaryObject<MutableNamedMixedParamDocDictionary> {
  String get a;

  String? get b;
}

abstract class NamedMixedParamDocDictionary
    with _$NamedMixedParamDocDictionary
    implements NamedMixedParamDoc {}

abstract class _NamedMixedParamDocDictionaryImplBase<I extends Dictionary>
    with _$NamedMixedParamDocDictionary
    implements NamedMixedParamDocDictionary {
  _NamedMixedParamDocDictionaryImplBase(this.internal);

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
  MutableNamedMixedParamDocDictionary toMutable() =>
      MutableNamedMixedParamDocDictionary.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
    indent: indent,
    className: 'NamedMixedParamDocDictionary',
    fields: {'a': a, 'b': b},
  );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableNamedMixedParamDocDictionary
    extends _NamedMixedParamDocDictionaryImplBase {
  ImmutableNamedMixedParamDocDictionary.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NamedMixedParamDocDictionary &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [NamedMixedParamDocDictionary].
class MutableNamedMixedParamDocDictionary
    extends _NamedMixedParamDocDictionaryImplBase<MutableDictionary>
    implements
        TypedMutableDictionaryObject<
          NamedMixedParamDocDictionary,
          MutableNamedMixedParamDocDictionary
        > {
  /// Creates a new mutable [NamedMixedParamDocDictionary].
  MutableNamedMixedParamDocDictionary(String a, {String? b})
    : super(MutableDictionary()) {
    this.a = a;
    if (b != null) {
      this.b = b;
    }
  }

  MutableNamedMixedParamDocDictionary.internal(super.internal);

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
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
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
    fields: {'a': a},
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
  MutableParamDict(String a) : super(MutableDictionary()) {
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
    fields: {'a': a},
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
        TypedMutableDictionaryObject<
          OptionalParamDict,
          MutableOptionalParamDict
        > {
  /// Creates a new mutable [OptionalParamDict].
  MutableOptionalParamDict([String? a]) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableOptionalParamDict.internal(super.internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
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
    fields: {'a': a, 'b': b},
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
        TypedMutableDictionaryObject<
          PositionalMixedParamDict,
          MutablePositionalMixedParamDict
        > {
  /// Creates a new mutable [PositionalMixedParamDict].
  MutablePositionalMixedParamDict(String a, [String? b])
    : super(MutableDictionary()) {
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
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
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
    fields: {'a': a},
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
  MutableNamedParamDict({required String a}) : super(MutableDictionary()) {
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
    fields: {'a': a},
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
        TypedMutableDictionaryObject<
          NamedOptionalParamDict,
          MutableNamedOptionalParamDict
        > {
  /// Creates a new mutable [NamedOptionalParamDict].
  MutableNamedOptionalParamDict({String? a}) : super(MutableDictionary()) {
    if (a != null) {
      this.a = a;
    }
  }

  MutableNamedOptionalParamDict.internal(super.internal);

  set a(String? value) {
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
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
    fields: {'a': a, 'b': b},
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
        TypedMutableDictionaryObject<
          NamedMixedParamDict,
          MutableNamedMixedParamDict
        > {
  /// Creates a new mutable [NamedMixedParamDict].
  MutableNamedMixedParamDict(String a, {String? b})
    : super(MutableDictionary()) {
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
    final promoted = value == null
        ? null
        : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}
