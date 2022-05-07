import 'package:meta/meta.dart' as meta;

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
  // Converters
  @meta.internal
  static const stringConverter = IdentityConverter<String>();
  @meta.internal
  static const intConverter = IdentityConverter<int>();
  @meta.internal
  static const doubleConverter = IdentityConverter<double>();
  @meta.internal
  static const numConverter = IdentityConverter<num>();
  @meta.internal
  static const boolConverter = IdentityConverter<bool>();
  @meta.internal
  static const blobConverter = IdentityConverter<Blob>();
  @meta.internal
  static const dateTimeConverter = DateTimeConverter();

  // Read helpers
  @meta.internal
  static T readProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required ToTyped<T> converter,
  }) {
    final value = internal.value(key);
    if (value == null) {
      if (!internal.contains(name)) {
        throw TypedDataException(
          'Expected a value for property "$name" but there is none in the '
          'underlying data.',
          TypedDataErrorCode.dataMismatch,
        );
      } else {
        throw TypedDataException(
          'Expected a value for property "$name" but found "null" in the '
          'underlying data.',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }

    try {
      return converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'At property "$name": $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }

  @meta.internal
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
        'At property "$name": $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }

  // Write helpers
  @meta.internal
  static void writeProperty<T>({
    required MutableDictionaryInterface internal,
    required T value,
    required String key,
    required ToUntyped<T> converter,
  }) {
    internal.setValue(converter.toUntyped(value), key: key);
  }

  @meta.internal
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
        ..writeln('(');
      for (final entry in fields.entries) {
        buffer
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
