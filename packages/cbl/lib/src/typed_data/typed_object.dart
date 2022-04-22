import 'package:meta/meta.dart' as meta;

abstract class TypedDictionaryObject<MD extends Object> {
  /// Internal field that you should never use.
  @meta.internal
  Object get internal;

  /// Returns a mutable copy of this object.
  MD toMutable();
}

abstract class TypedMutableDictionaryObject<D extends TypedDictionaryObject,
    MD extends TypedDictionaryObject> extends TypedDictionaryObject<MD> {}

abstract class TypedDocumentObject<MD extends Object> {
  /// Internal field that you should never use.
  @meta.internal
  Object get internal;

  /// Returns a mutable copy of this object.
  MD toMutable();
}

abstract class TypedMutableDocumentObject<D extends TypedDocumentObject,
    MD extends TypedDocumentObject> extends TypedDocumentObject<MD> {}
