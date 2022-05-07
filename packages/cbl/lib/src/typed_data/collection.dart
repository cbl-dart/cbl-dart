import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart' as meta;

import '../document.dart';
import '../errors.dart';
import 'conversion.dart';
import 'helpers.dart';

// === TypedDataList ===========================================================

abstract class TypedDataList<T extends E, E> implements List<T> {
  /// Internal field that end users should never access.
  ///
  /// @nodoc
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

abstract class _TypedDataListBase<T extends E, E, I extends Array>
    with ListMixin<T>, _TypedDataListToString
    implements TypedDataList<T, E> {
  _TypedDataListBase({
    required this.internal,
    required DataConverter<T, E> converter,
    required bool isNullable,
  })  : _converter = converter,
        _isNullable = isNullable;

  @override
  final I internal;
  final DataConverter<T, E> _converter;
  final bool _isNullable;

  @override
  int get length => internal.length;

  @override
  T operator [](int index) {
    final value = internal.value(index);
    if (value == null) {
      if (_isNullable) {
        return null as T;
      } else {
        throw TypedDataException(
          'Expected a value for element $index but found "null" in the '
          'underlying data.',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }

    try {
      return _converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'Type error at index $index: $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }
}

class ImmutableTypedDataList<T extends E, E>
    extends _TypedDataListBase<T, E, Array> {
  ImmutableTypedDataList({
    required Array internal,
    required DataConverter<T, E> converter,
    required bool isNullable,
  }) : super(internal: internal, converter: converter, isNullable: isNullable);

  @override
  void operator []=(int index, E value) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot change the length of an immutable list');
  }

  @override
  set first(E element) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  set last(E element) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void add(E element) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  void insert(int index, E element) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  bool remove(Object? element) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void removeWhere(bool Function(T element) test) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void retainWhere(bool Function(T element) test) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void sort([Comparator<T>? compare]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void shuffle([Random? random]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void clear() {
    throw UnsupportedError('Cannot clear an immutable list');
  }

  @override
  T removeAt(int index) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  T removeLast() {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void removeRange(int start, int end) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }
}

class MutableTypedDataList<T extends E, E>
    extends _TypedDataListBase<T, E, MutableArray> {
  MutableTypedDataList({
    required MutableArray internal,
    required DataConverter<T, E> converter,
    required bool isNullable,
  }) : super(internal: internal, converter: converter, isNullable: isNullable);

  T _promote(E value) => _converter.promote(value);

  @override
  set length(int newLength) {
    final oldLength = internal.length;
    final delta = oldLength - newLength;
    if (delta > 0) {
      for (var i = 0; i < delta; i++) {
        internal.removeValue(oldLength - 1 - i);
      }
    } else if (delta < 0) {
      if (!_isNullable) {
        throw UnsupportedError(
          'Cannot set the length of the list to $newLength because '
          'the list is not nullable.',
        );
      }
      for (var i = 0; i < delta; i++) {
        internal.addValue(null);
      }
    }
  }

  @override
  void operator []=(int index, E value) {
    internal.setValue(_converter.toUntyped(_promote(value)), at: index);
  }

  @override
  void add(E element) {
    internal.addValue(_converter.toUntyped(_promote(element)));
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      internal.addValue(_converter.toUntyped(_promote(element)));
    }
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    super.fillRange(start, end, fill == null ? null : _promote(fill));
  }

  @override
  void insert(int index, E element) {
    super.insert(index, _promote(element));
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    super.insertAll(index, iterable.map(_promote));
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    super.replaceRange(start, end, newContents.map(_promote));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    super.setAll(index, iterable.map(_promote));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    super.setRange(start, end, iterable.map(_promote), skipCount);
  }
}

class CachedTypedDataList<T extends E, E> extends DelegatingList<T>
    with _TypedDataListToString
    implements TypedDataList<T, E> {
  CachedTypedDataList(
    this._base, {
    required bool growable,
  })  : _cache = List.filled(_base.length, null, growable: growable),
        super(_base);

  final _TypedDataListBase<T, E, Array> _base;
  final List<T?> _cache;

  @override
  Object get internal => _base.internal;

  T _promote(E value) => _base._converter.promote(value);

  @override
  T operator [](int index) {
    final cachedValue = _cache[index];
    if (cachedValue != null) {
      return cachedValue;
    }

    final value = this[index];
    if (value != null) {
      // We must not store null in the cache, because we use it to detect if
      // a value has been cached or not.
      _cache[index] = value;
    }
    return value;
  }

  @override
  set length(int newLength) {
    super.length = newLength;
    _cache.length = newLength;
  }

  @override
  void operator []=(int index, E value) {
    final promoted = _promote(value);
    super[index] = promoted;
    _cache[index] = promoted;
  }

  @override
  void add(E value) {
    final promoted = _promote(value);
    super.add(promoted);
    _cache.add(promoted);
  }

  @override
  void addAll(Iterable<E> iterable) {
    final promoted = iterable.map(_promote).toList();
    super.addAll(promoted);
    _cache.addAll(promoted);
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    super.fillRange(start, end, fillValue == null ? null : _promote(fillValue));
  }

  @override
  void insert(int index, E element) {
    super.insert(index, _promote(element));
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    super.insertAll(index, iterable.map(_promote));
  }

  @override
  void replaceRange(int start, int end, Iterable<E> iterable) {
    super.replaceRange(start, end, iterable.map(_promote));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    super.setAll(index, iterable.map(_promote));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    super.setRange(start, end, iterable.map(_promote), skipCount);
  }
}

mixin _TypedDataListToString<T> on List<T> {
  @override
  String toString({String? indent}) {
    if (indent == null) {
      return super.toString();
    } else {
      final buffer = StringBuffer()..write('[');
      if (isNotEmpty) {
        buffer.writeln();
      }
      for (final entry in this) {
        final lines = entry.renderStringIndented(indent);

        buffer
          ..write(indent)
          ..write(lines[0]);
        for (final line in lines.skip(1)) {
          buffer
            ..writeln()
            ..write(indent)
            ..write(line);
        }
        buffer.writeln(',');
      }
      buffer.write(']');
      return buffer.toString();
    }
  }
}
