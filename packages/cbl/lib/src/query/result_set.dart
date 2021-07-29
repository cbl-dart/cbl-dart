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

class ResultSetImpl extends CblObject<CBLResultSet>
    with IterableMixin<Result>
    implements ResultSet {
  ResultSetImpl(
    Pointer<CBLResultSet> pointer, {
    required DatabaseImpl database,
    required List<String> columnNames,
    required String debugCreator,
  })  : _context = DatabaseMContext(database),
        _columnNames = columnNames,
        super(
          pointer,
          debugName: 'ResultSet(creator: $debugCreator)',
        );

  final DatabaseMContext _context;
  final List<String> _columnNames;
  var _isDone = false;
  Result? _current;

  @override
  Iterator<Result> get iterator => this;

  @override
  Result get current {
    assert(_current != null || !_isDone);
    return _current ??= ResultImpl(
      context: _context,
      columnValues: fl.Array.fromPointer(native.call(_bindings.resultArray)),
      columnNames: _columnNames,
    );
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

  @override
  String toString() => 'ResultSet()';
}
