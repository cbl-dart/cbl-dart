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

abstract class Promoter<T extends E, E> {
  const Promoter();

  T promote(E value);
}

abstract class TypeConverter<T extends E, E>
    implements Reviver<T>, Freezer<T>, Promoter<T, E> {
  const TypeConverter();
}

abstract class NonPromotingTypeConverter<T> extends TypeConverter<T, T> {
  const NonPromotingTypeConverter();

  @override
  T promote(T value) => value;
}

class IdentityConverter<T extends Object> extends NonPromotingTypeConverter<T> {
  const IdentityConverter();

  @override
  T revive(Object value) =>
      value is T ? value : throw CannotReviveTypeException<T>();

  @override
  Object freeze(T value) => value;
}

class DateTimeConverter extends NonPromotingTypeConverter<DateTime> {
  const DateTimeConverter();

  @override
  DateTime revive(Object value) => value is String
      ? DateTime.parse(value)
      : throw const CannotReviveTypeException<String>();

  @override
  Object freeze(DateTime value) => value.toIso8601String();
}

class TypedDictionaryConverter<I extends Object, T extends E,
    E extends TypedDictionaryObject<T>> extends TypeConverter<T, E> {
  const TypedDictionaryConverter(this._factory);

  final Factory<I, T> _factory;

  @override
  T revive(Object value) =>
      value is I ? _factory(value) : throw CannotReviveTypeException<T>();

  @override
  Object freeze(T value) => value.internal;

  @override
  T promote(E value) {
    if (value is T) {
      return value;
    }
    return value.toMutable();
  }
}

class TypedListConverter<T extends E, E>
    extends TypeConverter<TypedDataList<T, E>, List<E>> {
  const TypedListConverter({
    required this.converter,
    required this.isNullable,
    required this.isCached,
  });

  final TypeConverter<T, E> converter;
  final bool isNullable;
  final bool isCached;

  @override
  TypedDataList<T, E> revive(Object value) {
    if (value is MutableArray) {
      final list = MutableTypedDataList<T, E>(
        internal: value,
        converter: converter,
        isNullable: isNullable,
      );
      if (isCached) {
        return CachedTypedDataList(list, growable: true);
      }
      return list;
    } else if (value is Array) {
      final list = ImmutableTypedDataList<T, E>(
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
  Object freeze(covariant TypedDataList<T, E> value) => value.internal;

  @override
  TypedDataList<T, E> promote(List<E> value) {
    if (value is! TypedDataList<T, E> || value.internal is! MutableArray) {
      return revive(MutableArray())..addAll(value);
    }
    return value;
  }
}
