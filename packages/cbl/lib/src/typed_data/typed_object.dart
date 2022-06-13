import 'package:meta/meta.dart' as meta;

/// The type that is implemented by all typed dictionaries.
///
/// All typed dictionaries have a mutable subtype that has the type [MD].
///
/// {@category Typed Data}
@meta.experimental
abstract class TypedDictionaryObject<MD extends Object> {
  /// Internal field that end users should never access.
  ///
  /// @nodoc
  @meta.internal
  Object get internal;

  /// Returns a mutable copy of this object.
  MD toMutable();

  /// Returns a string representation of this object.
  ///
  /// Per default, the string representation is in a single line. If [indent] is
  /// specified, the string representation is in multiple lines, each field
  /// indented by [indent].
  @override
  String toString({String? indent});
}

/// The type that is implemented by all typed mutable dictionaries.
///
/// All typed mutable dictionaries have an immutable supertype that has the type
/// [D]. [MD] is the self type of the mutable subtype.
///
/// {@category Typed Data}
@meta.experimental
abstract class TypedMutableDictionaryObject<D extends TypedDictionaryObject,
    MD extends TypedDictionaryObject> extends TypedDictionaryObject<MD> {}

/// The type that is implemented by all typed documents.
///
/// All typed documents have a mutable subtype that has the type [MD].
///
/// {@category Typed Data}
@meta.experimental
abstract class TypedDocumentObject<MD extends Object>
    implements TypedDictionaryObject<MD> {}

/// The type that is implemented by all typed mutable documents.
///
/// All typed mutable documents have an immutable supertype that has the type
/// [D]. [MD] is the self type of the mutable subtype.
///
/// {@category Typed Data}
@meta.experimental
abstract class TypedMutableDocumentObject<D extends TypedDocumentObject,
        MD extends TypedDocumentObject> extends TypedDocumentObject<MD>
    implements TypedMutableDictionaryObject<D, MD> {}
