import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import '../document.dart';

/// Annotation for classes that declare a statically typed [Dictionary].
@Target({TargetKind.classType})
class TypedDictionary {
  /// Creates an annotation for a class that declares a statically typed
  /// [Dictionary].
  const TypedDictionary();
}

/// Annotation for classes that declare a statically typed [Document].
@Target({TargetKind.classType})
class TypedDocument {
  /// Creates an annotation for class that declares a statically typed
  /// [Document].
  const TypedDocument({
    this.typeMatcher = const ValueTypeMatcher(),
  });

  /// The type matcher to use for this typed document.
  final TypeMatcher? typeMatcher;
}

/// Determines whether a [TypedDictionary] or [TypedDocument] can be
/// used for a given [Dictionary] or [Document], respectively.
@sealed
abstract class TypeMatcher {
  /// Const constructor to allow subclasses to be const.
  const TypeMatcher();
}

/// A [TypeMatcher] that matches a [Dictionary] or [Document] if it contains a
/// fixed [value] at a fixed [path].
class ValueTypeMatcher extends TypeMatcher {
  /// Creates a [TypeMatcher] that matches a [Dictionary] or [Document] if it
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
  /// | Description | Path                           |
  /// | :---------- | :----------------------------- |
  /// | Root        | `['type']`                     |
  /// | Nested      | `['metaData', 'type']`         |
  /// | Array       | `['typeDescriptors', 0, 'id']` |
  final List<Object> path;

  /// The value that the [Dictionary] or [Document] must contain at
  /// [path] to match.
  ///
  /// If this is `null`, the name of the class annotated with [TypedDictionary]
  /// or [TypedDocument] is used.
  final String? value;
}

/// Annotation for the field of a typed document that is the document id.
@Target({TargetKind.parameter, TargetKind.getter})
class DocumentId {
  /// Creates an annotation for the field of a typed document that is the
  /// document id.
  const DocumentId();
}

@Target({TargetKind.getter})
class DocumentSequence {
  const DocumentSequence();
}

@Target({TargetKind.getter})
class DocumentRevisionId {
  const DocumentRevisionId();
}

@Target({TargetKind.classType})
class TypedDatabase {
  const TypedDatabase({required this.types});

  final Set<Type> types;
}
