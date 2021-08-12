import 'dart:collection';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/database.dart';
import '../document/common.dart';
import '../fleece/fleece.dart' as fl;
import '../support/ffi.dart';
import '../support/native_object.dart';
import 'query.dart';
import 'result.dart';

/// An [Iterable] over the [Result]s of executing a [Query].
abstract class ResultSet implements Iterable<Result>, Iterator<Result> {}

late final _bindings = cblBindings.resultSet;

class ResultSetImpl with IterableMixin<Result> implements ResultSet {
  ResultSetImpl(
    Pointer<CBLResultSet> pointer, {
    required DatabaseImpl database,
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
  Iterator<Result> get iterator => this;

  @override
  Result get current => _current ??= ResultImpl.fromValuesArray(
        _iterator.current,
        context: _context,
        columnNames: _columnNames,
      );

  @override
  bool moveNext() {
    _current = null;
    return _iterator.moveNext();
  }

  @override
  String toString() => 'ResultSet()';
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
