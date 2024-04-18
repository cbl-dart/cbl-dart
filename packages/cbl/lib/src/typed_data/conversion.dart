// ignore_for_file: one_member_abstracts

import 'package:meta/meta.dart';

import '../document.dart';
import 'adapter.dart';
import 'collection.dart';
import 'typed_object.dart';

// === API =====================================================================

abstract interface class ToTyped<T> {
  T toTyped(Object value);
}

abstract interface class ToUntyped<T> {
  Object toUntyped(T value);
}

abstract interface class Promoter<T extends E, E> {
  T promote(E value);
}

abstract base class DataConverter<T extends E, E>
    implements ToTyped<T>, ToUntyped<T>, Promoter<T, E> {
  const DataConverter();
}

abstract base class NonPromotingDataConverter<T> extends DataConverter<T, T> {
  const NonPromotingDataConverter();

  @override
  T promote(T value) => value;
}

/// An object that converts between untyped data and instances of type [T],
/// which must have value semantics.
///
/// Objects returned from [fromData] must be immutable. [toData] must return a
/// representation of the object, which recreates the object when given to
/// [fromData]. The data representation must only use:
///
/// - `null` (except for the data representation itself),
/// - [String],
/// - [int],
/// - [double],
/// - [bool],
/// - [List] (must only use types in this list),
/// - [Map] (must use [String] keys and only values of types in this list) and
/// - [Blob].
///
/// {@category Typed Data}
@experimental
abstract interface class ScalarConverter<T> {
  /// Recreates an object from the given data representation.
  ///
  /// If the [value] is not of the expected type, this must throw an
  /// [UnexpectedTypeException].
  T fromData(Object value);

  /// Returns the data representation of the object.
  Object toData(T value);
}

/// Exception thrown by [ScalarConverter.fromData] when the given value is not
/// of the expected type.
///
/// {@category Typed Data}
@experimental
final class UnexpectedTypeException implements Exception {
  const UnexpectedTypeException({
    required this.value,
    required this.expectedTypes,
  });

  final Object? value;
  final List<Type> expectedTypes;

  String get message => 'Expected a value of type $_expectedTypesPhrase, '
      'but got a ${value.runtimeType}.';

  @override
  String toString() => 'UnexpectedTypeException: $message';

  String get _expectedTypesPhrase {
    if (expectedTypes.length == 1) {
      return expectedTypes.first.toString();
    } else {
      return '${expectedTypes.take(expectedTypes.length - 1).join(', ')} '
          'or ${expectedTypes.last}';
    }
  }
}

/// === Implementations ========================================================

final class IdentityConverter<T extends Object>
    extends NonPromotingDataConverter<T> {
  const IdentityConverter();

  @override
  T toTyped(Object value) => value is T
      ? value
      : throw UnexpectedTypeException(value: value, expectedTypes: [T]);

  @override
  Object toUntyped(T value) => value;
}

final class DateTimeConverter extends NonPromotingDataConverter<DateTime> {
  const DateTimeConverter();

  @override
  DateTime toTyped(Object value) => value is String
      ? DateTime.parse(value)
      : throw UnexpectedTypeException(
          value: value,
          expectedTypes: [String],
        );

  @override
  Object toUntyped(DateTime value) => value.toIso8601String();
}

/// @nodoc
final class TypedDictionaryConverter<I extends Object, T extends E,
    E extends TypedDictionaryObject<T>> extends DataConverter<T, E> {
  const TypedDictionaryConverter(this._factory);

  final Factory<I, T> _factory;

  @override
  T toTyped(Object value) => value is I
      ? _factory(value)
      : throw UnexpectedTypeException(value: value, expectedTypes: [I]);

  @override
  Object toUntyped(T value) => value.internal;

  @override
  T promote(E value) {
    if (value is T) {
      return value;
    }
    return value.toMutable();
  }
}

/// @nodoc
final class TypedListConverter<T extends E, E>
    extends DataConverter<TypedDataList<T, E>, List<E>> {
  const TypedListConverter({
    required this.converter,
    required this.isNullable,
    required this.isCached,
  });

  final DataConverter<T, E> converter;
  final bool isNullable;
  final bool isCached;

  @override
  TypedDataList<T, E> toTyped(Object value) {
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
    throw UnexpectedTypeException(
      value: value,
      expectedTypes: [Array, MutableArray],
    );
  }

  @override
  Object toUntyped(covariant TypedDataList<T, E> value) => value.internal;

  @override
  TypedDataList<T, E> promote(List<E> value) {
    if (value is! TypedDataList<T, E> || value.internal is! MutableArray) {
      return toTyped(MutableArray())..addAll(value);
    }
    return value;
  }
}

/// @nodoc
final class ScalarConverterAdapter<T> extends NonPromotingDataConverter<T> {
  const ScalarConverterAdapter(this.converter);

  final ScalarConverter<T> converter;

  @override
  T toTyped(Object value) {
    if (value is Dictionary) {
      // ignore: parameter_assignments
      value = value.toPlainMap();
    } else if (value is Array) {
      // ignore: parameter_assignments
      value = value.toPlainList();
    }
    return converter.fromData(value);
  }

  @override
  Object toUntyped(T value) => converter.toData(value);
}

/// A [ScalarConverter] that encodes [Enum] values by their name.
///
/// {@category Typed Data}
@experimental
final class EnumNameConverter<T extends Enum> implements ScalarConverter<T> {
  /// Creates a [ScalarConverter] that encodes [Enum] values by their name.
  const EnumNameConverter(this.values);

  /// The list returned from `Enum.values`.
  final List<T> values;

  @override
  T fromData(Object value) {
    if (value is! String) {
      throw UnexpectedTypeException(value: value, expectedTypes: [String]);
    }
    for (final enumValue in values) {
      if (enumValue.name == value) {
        return enumValue;
      }
    }
    throw ArgumentError.value(value, 'value', 'not a valid enum name for $T');
  }

  @override
  Object toData(T value) => value.name;
}

/// A [ScalarConverter] that encodes [Enum] values by their index.
///
/// {@category Typed Data}
@experimental
final class EnumIndexConverter<T extends Enum> implements ScalarConverter<T> {
  /// Creates a [ScalarConverter] that encodes [Enum] values by their index.
  const EnumIndexConverter(this.values);

  /// The list returned from `Enum.values`.
  final List<T> values;

  @override
  T fromData(Object value) {
    if (value is! int) {
      throw UnexpectedTypeException(value: value, expectedTypes: [int]);
    }
    RangeError.checkValidIndex(
      value,
      values,
      'value',
      null,
      'not a valid enum index for $T',
    );
    return values[value];
  }

  @override
  Object toData(T value) => value.index;
}
