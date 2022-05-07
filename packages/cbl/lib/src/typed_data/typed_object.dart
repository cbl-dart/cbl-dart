import 'package:meta/meta.dart' as meta;

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
  /// Per default, the string representation is in a single line.
  /// If [indent] is specified, the string representation is in multiple lines,
  /// each field indented by [indent].
  @override
  String toString({String? indent});
}

abstract class TypedMutableDictionaryObject<D extends TypedDictionaryObject,
    MD extends TypedDictionaryObject> extends TypedDictionaryObject<MD> {}

abstract class TypedDocumentObject<MD extends Object>
    implements TypedDictionaryObject<MD> {}

abstract class TypedMutableDocumentObject<D extends TypedDocumentObject,
        MD extends TypedDocumentObject> extends TypedDocumentObject<MD>
    implements TypedMutableDictionaryObject<D, MD> {}
