import 'runtime_support.dart';
import 'typed_object.dart';

abstract class Reviver<T> {
  const Reviver();

  T revive(Object value);
}

class CannotReviveTypeException<T> implements Exception {
  const CannotReviveTypeException();

  Type get expectedType => T;
}

abstract class Freezer<T> {
  const Freezer();

  Object freeze(T value);
}

abstract class TypeConverter<T> implements Reviver<T>, Freezer<T> {
  const TypeConverter();
}

class FactoryReviver<E extends Object, T> extends Reviver<T> {
  const FactoryReviver(this._factory);

  final Factory<E, T> _factory;

  @override
  T revive(Object value) =>
      value is E ? _factory(value) : throw CannotReviveTypeException<T>();
}

class TypedDictionaryFreezer extends Freezer<TypedDictionaryObject> {
  const TypedDictionaryFreezer();

  @override
  Object freeze(TypedDictionaryObject value) => value.internal;
}

class IdentityConverter<T extends Object> extends TypeConverter<T> {
  const IdentityConverter();

  @override
  T revive(Object value) =>
      value is T ? value : throw CannotReviveTypeException<T>();

  @override
  Object freeze(T value) => value;
}

class DateTimeConverter extends TypeConverter<DateTime> {
  const DateTimeConverter();

  @override
  DateTime revive(Object value) => value is String
      ? DateTime.parse(value)
      : throw const CannotReviveTypeException<String>();

  @override
  Object freeze(DateTime value) => value.toIso8601String();
}
