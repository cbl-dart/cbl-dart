import 'package:meta/meta.dart' as meta;

abstract class TypedDictionaryObject<MD extends Object> {
  /// Internal field that you should never use.
  @meta.internal
  Object get internal;

  /// Returns a mutable copy of this object.
  MD toMutable();

  /// Returns a string representation of this dictionary.
  ///
  /// Per default, the string representation is in a single line.
  /// If [indent] is specified, the string representation is in multiple lines,
  /// each field indented by [indent].
  @override
  String toString({String? indent});
}

abstract class TypedMutableDictionaryObject<D extends TypedDictionaryObject,
    MD extends TypedDictionaryObject> extends TypedDictionaryObject<MD> {}

abstract class TypedDocumentObject<MD extends Object> {
  /// Internal field that you should never use.
  @meta.internal
  Object get internal;

  /// Returns a mutable copy of this object.
  MD toMutable();

  /// Returns a string representation of this document.
  ///
  /// Per default, the string representation is in a single line.
  /// If [indent] is specified, the string representation is in multiple lines,
  /// each field indented by [indent].
  @override
  String toString({String? indent});
}

abstract class TypedMutableDocumentObject<D extends TypedDocumentObject,
    MD extends TypedDocumentObject> extends TypedDocumentObject<MD> {}

abstract class TypedDataList<T extends E, E> implements List<T> {
  /// Internal field that you should never use.
  @meta.internal
  Object get internal;

  @override
  void add(E value);

  @override
  void addAll(Iterable<E> iterable);

  @override
  void fillRange(int start, int end, [E? fillValue]);

  @override
  void insert(int index, E element);

  @override
  void insertAll(int index, Iterable<E> iterable);

  @override
  void replaceRange(int start, int end, Iterable<E> replacements);

  @override
  void setAll(int index, Iterable<E> iterable);

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]);

  @override
  void operator []=(int index, E value);

  /// Returns a string representation of this list.
  ///
  /// Per default, the string representation is in a single line.
  /// If [indent] is specified, the string representation is in multiple lines,
  /// each element indented by [indent].
  @override
  String toString({String? indent});
}
