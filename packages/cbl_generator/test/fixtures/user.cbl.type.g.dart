// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars, invalid_use_of_internal_member, parameter_assignments, unnecessary_const, prefer_relative_imports, avoid_equals_and_hash_code_on_mutable_classes

part of 'user.dart';

// **************************************************************************
// TypedDocumentGenerator
// **************************************************************************

mixin _$User implements TypedDocumentObject<MutableUser> {
  String get id;

  PersonalName get name;

  String? get email;

  String get username;

  DateTime get createdAt;
}

abstract class _UserImplBase<I extends Document> with _$User implements User {
  _UserImplBase(this.internal);

  @override
  final I internal;

  @override
  String get id => internal.id;

  @override
  String? get email => TypedDataHelpers.readNullableProperty(
        internal: internal,
        name: 'email',
        key: 'email',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String get username => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'username',
        key: 'username',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  DateTime get createdAt => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'createdAt',
        key: 'createdAt',
        converter: TypedDataHelpers.dateTimeConverter,
      );

  @override
  MutableUser toMutable() => MutableUser.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'User',
        fields: {
          'id': id,
          'name': name,
          'email': email,
          'username': username,
          'createdAt': createdAt,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableUser extends _UserImplBase {
  ImmutableUser.internal(super.internal);

  static const _nameConverter = const TypedDictionaryConverter<
      Dictionary,
      PersonalName,
      TypedDictionaryObject<PersonalName>>(ImmutablePersonalName.internal);

  @override
  late final name = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'name',
    key: 'name',
    converter: _nameConverter,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [User].
class MutableUser extends _UserImplBase<MutableDocument>
    implements TypedMutableDocumentObject<User, MutableUser> {
  /// Creates a new mutable [User].
  MutableUser({
    String? id,
    required PersonalName name,
    String? email,
    required String username,
    required DateTime createdAt,
  }) : super(id == null ? MutableDocument() : MutableDocument.withId(id)) {
    this.name = name;
    if (email != null) {
      this.email = email;
    }
    this.username = username;
    this.createdAt = createdAt;
  }

  MutableUser.internal(super.internal);

  static const _nameConverter = const TypedDictionaryConverter<
      MutableDictionary,
      MutablePersonalName,
      PersonalName>(MutablePersonalName.internal);

  late MutablePersonalName _name = TypedDataHelpers.readProperty(
    internal: internal,
    name: 'name',
    key: 'name',
    converter: _nameConverter,
  );

  @override
  MutablePersonalName get name => _name;

  set name(PersonalName value) {
    final promoted = _nameConverter.promote(value);
    _name = promoted;
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'name',
      value: promoted,
      converter: _nameConverter,
    );
  }

  set email(String? value) {
    final promoted =
        value == null ? null : TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeNullableProperty(
      internal: internal,
      key: 'email',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set username(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'username',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set createdAt(DateTime value) {
    final promoted = TypedDataHelpers.dateTimeConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'createdAt',
      value: promoted,
      converter: TypedDataHelpers.dateTimeConverter,
    );
  }
}

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

mixin _$PersonalName implements TypedDictionaryObject<MutablePersonalName> {
  String get first;

  String get last;
}

abstract class _PersonalNameImplBase<I extends Dictionary>
    with _$PersonalName
    implements PersonalName {
  _PersonalNameImplBase(this.internal);

  @override
  final I internal;

  @override
  String get first => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'first',
        key: 'first',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  String get last => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'last',
        key: 'last',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutablePersonalName toMutable() =>
      MutablePersonalName.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'PersonalName',
        fields: {
          'first': first,
          'last': last,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutablePersonalName extends _PersonalNameImplBase {
  ImmutablePersonalName.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalName &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [PersonalName].
class MutablePersonalName extends _PersonalNameImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<PersonalName, MutablePersonalName> {
  /// Creates a new mutable [PersonalName].
  MutablePersonalName({
    required String first,
    required String last,
  }) : super(MutableDictionary()) {
    this.first = first;
    this.last = last;
  }

  MutablePersonalName.internal(super.internal);

  set first(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'first',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }

  set last(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'last',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}
