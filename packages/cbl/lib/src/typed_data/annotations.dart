import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import '../document.dart';
import 'conversion.dart';

/// Annotation for classes that are typed dictionaries.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.classType})
class TypedDictionary {
  /// Creates an annotation for a class that is a typed dictionary.
  /// [Dictionary].
  const TypedDictionary();
}

/// Annotation for classes that are typed documents.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.classType})
class TypedDocument {
  /// Creates an annotation for a class that is a typed document.
  const TypedDocument({
    this.typeMatcher = const ValueTypeMatcher(),
  });

  /// The type matcher to use for the typed document.
  final TypeMatcher? typeMatcher;
}

/// Determines whether a given dictionary or document can be instantiated as a
/// specific typed dictionary or document.
///
/// {@category Typed Data}
@experimental
@sealed
abstract class TypeMatcher {
  /// Const constructor to allow subclasses to be const.
  const TypeMatcher();
}

/// A [TypeMatcher] that matches a dictionary or document if it contains a fixed
/// [value] at a fixed [path].
///
/// {@category Typed Data}
@experimental
class ValueTypeMatcher extends TypeMatcher {
  /// Creates a [TypeMatcher] that matches a dictionary or document if it
  /// contains a fixed [value] at a fixed [path].
  const ValueTypeMatcher({this.path = const ['type'], this.value});

  /// The path to the [value] to match.
  ///
  /// The default value is `['type']`.
  ///
  /// Every element in the [List] is a path segment and must be a [String] or
  /// [int]. The [List] must not be empty. [String]s are interpreted as keys in
  /// dictionaries and [int]s are interpreted as indexes in arrays.
  ///
  /// # Examples
  ///
  /// | Description | Path                           |
  /// | :---------- | :----------------------------- |
  /// | Root        | `['type']`                     |
  /// | Nested      | `['metaData', 'type']`         |
  /// | Array       | `['typeDescriptors', 0, 'id']` |
  final List<Object> path;

  /// The value that the dictionary or document must contain at [path] to match.
  ///
  /// If this is `null`, the name of the class annotated with [TypedDictionary]
  /// or [TypedDocument] is used.
  final String? value;
}

/// Annotation for the property of a typed document that is the document id.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.parameter, TargetKind.getter})
class DocumentId {
  /// Creates an annotation for the property of a typed document that is the
  /// document id.
  const DocumentId();
}

/// Annotation for the property of a typed document that is the document
/// sequence.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.getter})
class DocumentSequence {
  /// Creates an annotation for the property of a typed document that is the
  /// document sequence.
  const DocumentSequence();
}

/// Annotation for the property of a typed document that is the document
/// revision id.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.getter})
class DocumentRevisionId {
  /// Creates an annotation for the property of a typed document that is the
  /// document revision id.
  const DocumentRevisionId();
}

/// Annotation for the property of a typed dictionary or document that is a
/// dictionary or document property.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.parameter})
class TypedProperty {
  /// Creates an annotation for the property of a typed dictionary or document
  /// that is a dictionary or document property.
  const TypedProperty({
    this.property,
    this.defaultValue,
    this.converter,
  });

  /// The name of the property in the underlying data.
  ///
  /// Per default, the name of the property in the typed object is used.
  final String? property;

  /// The Dart code of the default value for the property.
  final String? defaultValue;

  /// Converter for converting between the underlying data and the value of the
  /// property.
  final ScalarConverter? converter;
}

/// Annotation for classes that are typed databases.
///
/// {@category Typed Data}
@experimental
@Target({TargetKind.classType})
class TypedDatabase {
  /// Creates an annotation for a class that is a typed database.
  const TypedDatabase({required this.types});

  /// The typed dictionary and document types that are supported by the
  /// database.
  final Set<Type> types;
}
