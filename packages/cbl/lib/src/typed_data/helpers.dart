import 'package:meta/meta.dart';

import '../document.dart';
import '../errors.dart';
import 'collection.dart';
import 'conversion.dart';
import 'typed_object.dart';

// ignore: avoid_classes_with_only_static_members
/// Helper functions for use by generated code.
///
/// @nodoc
class TypedDataHelpers {
  TypedDataHelpers._();

  @internal
  static const stringConverter = IdentityConverter<String>();
  @internal
  static const intConverter = IdentityConverter<int>();
  @internal
  static const doubleConverter = IdentityConverter<double>();
  @internal
  static const numConverter = IdentityConverter<num>();
  @internal
  static const boolConverter = IdentityConverter<bool>();
  @internal
  static const blobConverter = IdentityConverter<Blob>();
  @internal
  static const dateTimeConverter = DateTimeConverter();

  @internal
  static T readProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required ToTyped<T> converter,
  }) {
    final value = internal.value(key);
    if (value == null) {
      if (!internal.contains(key)) {
        throw TypedDataException(
          'Expected a value for property "$name" but there is none in the '
          'underlying data at key "$key".',
          TypedDataErrorCode.dataMismatch,
        );
      } else {
        throw TypedDataException(
          'Expected a value for property "$name" but found "null" in the '
          'underlying data at key "$key".',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }

    try {
      return converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'Type error for property "$name" at key "$key": $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }

  @internal
  static T? readNullableProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required ToTyped<T> converter,
  }) {
    final value = internal.value(key);
    if (value == null) {
      return null;
    }

    try {
      return converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'Type error for property "$name" at key "$key": $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }

  @internal
  static void writeProperty<T>({
    required MutableDictionaryInterface internal,
    required T value,
    required String key,
    required ToUntyped<T> converter,
  }) {
    internal.setValue(converter.toUntyped(value), key: key);
  }

  @internal
  static void writeNullableProperty<T>({
    required MutableDictionaryInterface internal,
    required T? value,
    required String key,
    required ToUntyped<T> converter,
  }) {
    if (value == null) {
      internal.removeValue(key);
    } else {
      internal.setValue(converter.toUntyped(value), key: key);
    }
  }

  @internal
  static String renderString({
    required String? indent,
    required String className,
    required Map<String, Object?> fields,
  }) {
    if (indent == null) {
      return [
        className,
        '(',
        [for (final entry in fields.entries) '${entry.key}: ${entry.value}']
            .join(', '),
        ')',
      ].join();
    } else {
      final buffer = StringBuffer()
        ..write(className)
        ..write('(');
      for (final entry in fields.entries) {
        buffer
          ..writeln()
          ..write(indent)
          ..write(entry.key)
          ..write(': ');

        final lines = entry.value.renderStringIndented(indent);

        buffer.write(lines[0]);
        for (final line in lines.skip(1)) {
          buffer
            ..writeln()
            ..write(indent)
            ..write(line);
        }
        buffer.writeln(',');
      }
      buffer.write(')');
      return buffer.toString();
    }
  }
}

extension RenderStringExt on Object? {
  List<String> renderStringIndented(String indent) {
    final value = this;
    final String valueString;
    if (value == null) {
      valueString = 'null';
    } else if (value is TypedDictionaryObject) {
      valueString = value.toString(indent: indent);
    } else if (value is TypedDataList) {
      valueString = value.toString(indent: indent);
    } else {
      valueString = value.toString();
    }
    return valueString.split('\n');
  }
}
