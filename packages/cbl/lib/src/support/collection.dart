import 'dart:collection';
import 'dart:math';

/// Mixin for an unmodifiable [List] class.
///
/// This overrides all mutating methods with methods that throw.
/// This mixin is intended to be mixed in on top of [ListMixin] on
/// unmodifiable lists.
mixin UnmodifiableListMixin<E> on List<E> {
  /// This operation is not supported by an unmodifiable list. */
  @override
  void operator []=(int index, E value) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot change the length of an unmodifiable list');
  }

  @override
  set first(E element) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  @override
  set last(E element) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void setAll(int at, Iterable<E> iterable) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void add(E value) {
    throw UnsupportedError('Cannot add to an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void insert(int index, E element) {
    throw UnsupportedError('Cannot add to an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void insertAll(int at, Iterable<E> iterable) {
    throw UnsupportedError('Cannot add to an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError('Cannot add to an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  bool remove(Object? element) {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void removeWhere(bool Function(E element) test) {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void retainWhere(bool Function(E element) test) {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void sort([Comparator<E>? compare]) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void shuffle([Random? random]) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void clear() {
    throw UnsupportedError('Cannot clear an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  E removeAt(int index) {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  E removeLast() {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void removeRange(int start, int end) {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw UnsupportedError('Cannot remove from an unmodifiable list');
  }

  /// This operation is not supported by an unmodifiable list. */
  @override
  void fillRange(int start, int end, [E? fillValue]) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }
}
