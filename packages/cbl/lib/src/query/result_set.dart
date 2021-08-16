import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/ffi_database.dart';
import '../document/common.dart';
import '../fleece/fleece.dart' as fl;
import '../support/ffi.dart';
import '../support/native_object.dart';
import 'query.dart';
import 'result.dart';

/// A set of [Result]s which is returned when executing a [Query].
// ignore: one_member_abstracts
abstract class ResultSet {
  /// Returns a stream which consumes this result set and emits its results.
  ///
  /// A result set can only be consumed once and listening to the returned
  /// stream counts as consuming it. Other methods for consuming this result set
  /// must not be used when using a stream.
  Stream<Result> asStream();
}

/// A [ResultSet] which can be iterated synchronously as well asynchronously.
abstract class SyncResultSet
    implements ResultSet, Iterable<Result>, Iterator<Result> {}

late final _bindings = cblBindings.resultSet;

class FfiResultSet
    with IterableMixin<Result>, ResultSetStreamMixin
    implements SyncResultSet {
  FfiResultSet(
    Pointer<CBLResultSet> pointer, {
    required FfiDatabase database,
    required List<String> columnNames,
    required String debugCreator,
  })  : _context = DatabaseMContext(database),
        _columnNames = columnNames,
        _iterator = ResultSetIterator(
          pointer,
          debugCreator: debugCreator,
        );

  final DatabaseMContext _context;
  final List<String> _columnNames;
  final ResultSetIterator _iterator;
  Result? _current;

  @override
  Stream<Result> asStream() {
    onCreateStream();
    return Stream.fromIterable(this);
  }

  @override
  Iterator<Result> get iterator {
    checkHasNotStream();
    return this;
  }

  @override
  Result get current {
    checkHasNotStream();
    return _current ??= ResultImpl.fromValuesArray(
      _iterator.current,
      context: _context,
      columnNames: _columnNames,
    );
  }

  @override
  bool moveNext() {
    checkHasNotStream();
    _current = null;
    return _iterator.moveNext();
  }

  @override
  String toString() => 'FfiResultSet()';
}

class ResultSetIterator extends CblObject<CBLResultSet>
    with IterableMixin<fl.Array>
    implements Iterator<fl.Array> {
  ResultSetIterator(
    Pointer<CBLResultSet> pointer, {
    this.encodeArray = false,
    required String debugCreator,
  }) : super(
          pointer,
          debugName: 'ResultSetIterator(creator: $debugCreator)',
        );

  final bool encodeArray;
  var _isDone = false;
  fl.Array? _current;

  @override
  Iterator<fl.Array> get iterator => this;

  @override
  fl.Array get current {
    assert(_current != null || !_isDone);
    return _current ??=
        fl.Array.fromPointer(native.call(_bindings.resultArray));
  }

  @override
  bool moveNext() {
    if (_isDone) {
      return false;
    }
    _current = null;
    _isDone = !native.call(_bindings.next);
    return !_isDone;
  }
}

mixin ResultSetStreamMixin {
  bool _hasStream = false;

  void checkHasNotStream() {
    if (_hasStream) {
      throw StateError('The result set is already being consumed by a stream.');
    }
  }

  void onCreateStream() {
    checkHasNotStream();
    _hasStream = true;
  }
}
