import '../document.dart';
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

class TypedDictionaryConverter<E extends Object,
    T extends TypedDictionaryObject> extends TypeConverter<T> {
  const TypedDictionaryConverter(this._factory);

  final Factory<E, T> _factory;

  @override
  T revive(Object value) =>
      value is E ? _factory(value) : throw CannotReviveTypeException<T>();

  @override
  Object freeze(T value) => value.internal;
}

class TypedListConverter<T> extends TypeConverter<TypedDataList<T>> {
  const TypedListConverter({
    required this.converter,
    required this.isNullable,
    required this.isCached,
  });

  final TypeConverter<T> converter;
  final bool isNullable;
  final bool isCached;

  @override
  TypedDataList<T> revive(Object value) {
    if (value is MutableArray) {
      final list = MutableTypedDataList(
        internal: value,
        converter: converter,
        isNullable: isNullable,
      );
      if (isCached) {
        return CachedTypedDataList(list, growable: true);
      }
      return list;
    } else if (value is Array) {
      final list = ImmutableTypedDataList(
        internal: value,
        converter: converter,
        isNullable: isNullable,
      );
      if (isCached) {
        return CachedTypedDataList(list, growable: false);
      }
      return list;
    }
    throw const CannotReviveTypeException<Array>();
  }

  @override
  Object freeze(TypedDataList<T> value) => value.internal;
}
