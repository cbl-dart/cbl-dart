import 'dart:collection';
import 'dart:core' as core;
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../blob.dart';
import 'dictionary.dart';
import 'fragment.dart';
import 'utils.dart';

abstract class ArrayAccessors implements ArrayFragment {
  core.int get length;
  core.Object? value(core.int index);
  core.String? string(core.int index);
  core.int int(core.int index);
  core.double double(core.int index);
  core.num? num(core.int index);
  core.bool bool(core.int index);
  core.DateTime? date(core.int index);
  Blob? blob(core.int index);
  Array? array(core.int index);
  Dictionary? dictionary(core.int index);
  core.List<core.Object?> toList();
}

abstract class MutableArrayAccessors<Self extends MutableArrayAccessors<void>>
    implements ArrayAccessors, MutableArrayFragment {
  Self setValue(core.int index, core.Object? value);
  Self setString(core.int index, core.String? value);
  Self setInt(core.int index, core.int value);
  Self setDouble(core.int index, core.double value);
  Self setNum(core.int index, core.num? value);
  Self setBool(core.int index, core.bool value);
  Self setDate(core.int index, core.DateTime? value);
  Self setBlob(core.int index, Blob? value);
  Self setArray(core.int index, Array? value);
  Self setDictionary(core.int index, Dictionary? value);

  Self addValue(core.Object? value);
  Self addString(core.String? value);
  Self addInt(core.int value);
  Self addDouble(core.double value);
  Self addNum(core.num? value);
  Self addBool(core.bool value);
  Self addDate(core.DateTime? value);
  Self addBlob(Blob? value);
  Self addArray(Array? value);
  Self addDictionary(Dictionary? value);

  Self insertValue(core.int index, core.Object? value);
  Self insertString(core.int index, core.String? value);
  Self insertInt(core.int index, core.int value);
  Self insertDouble(core.int index, core.double value);
  Self insertNum(core.int index, core.num? value);
  Self insertBool(core.int index, core.bool value);
  Self insertDate(core.int index, core.DateTime? value);
  Self insertBlob(core.int index, Blob? value);
  Self insertArray(core.int index, Array? value);
  Self insertDictionary(core.int index, Dictionary? value);

  Self setData(core.Iterable<core.Object?> value);

  Self removeValue(core.int index);

  @core.override
  MutableArray? array(core.int index);

  @core.override
  MutableDictionary? dictionary(core.int index);
}

abstract class Array implements ArrayAccessors, core.Iterable<core.Object?> {
  MutableArray toMutable();
}

abstract class MutableArray
    implements Array, MutableArrayAccessors<MutableArray> {
  factory MutableArray([core.Iterable<core.Object?>? data]) =>
      MutableArrayImpl(data);
}

class ArrayImpl with IterableMixin<core.Object?> implements Array {
  ArrayImpl.fromPointer(
    this.pointer, {
    core.bool retain = true,
  }) {
    valueBinds.bindToDartObject(this, pointer.cast(), retain.toInt());
  }

  final Pointer<FLArray> pointer;

  // TODO: eliminate this call by creating methods on the native side which can
  // do the operation in one call
  Pointer<FLValue> _getValue(core.int index) => arrayBinds.get(pointer, index);

  // === ArrayAccessors ========================================================
  //
  @core.override
  core.int get length => arrayBinds.count(pointer);

  @core.override
  core.Object? value(core.int index) => _getValue(index).value;

  @core.override
  core.String? string(core.int index) => _getValue(index).string;

  @core.override
  core.int int(core.int index) => _getValue(index).intNumber;

  @core.override
  core.double double(core.int index) => _getValue(index).doubleNumber;

  @core.override
  core.num? num(core.int index) => _getValue(index).number;

  @core.override
  core.bool bool(core.int index) => _getValue(index).boolean;

  @core.override
  core.DateTime? date(core.int index) => _getValue(index).date;

  @core.override
  Blob? blob(core.int index) => _getValue(index).blob;

  @core.override
  Array? array(core.int index) => _getValue(index).array;

  @core.override
  Dictionary? dictionary(core.int index) => _getValue(index).dictionary;

  @core.override
  core.List<core.Object?> toList({core.bool growable = true}) =>
      map(convertContainersToPrimitives).toList(growable: growable);

  // === ArrayFragment =========================================================

  @core.override
  Fragment operator [](core.int index) =>
      Fragment(parent: this, indexOrKey: index);

  // === Array =================================================================

  @core.override
  MutableArray toMutable() {
    final core.Object self = this;
    if (self is MutableArray) {
      return self;
    }

    var mutableValue = arrayBinds.asMutable(pointer);
    if (mutableValue != nullptr) {
      return MutableArrayImpl.fromPointer(mutableValue);
    }

    mutableValue = mutArrayBinds.mutableCopy(pointer, 0);
    return MutableArrayImpl.fromPointer(mutableValue, retain: false);
  }

  // === Iterable ==============================================================

  @core.override
  core.Iterator<core.Object?> get iterator =>
      core.Iterable.generate(length, value).iterator;

  // === Object ================================================================

  @core.override
  core.bool operator ==(core.Object other) =>
      core.identical(this, other) ||
      other is ArrayImpl &&
          valueBinds.isEqual(pointer.cast(), other.pointer.cast()).toBool();

  @core.override
  core.int get hashCode =>
      fold(31, (hashCode, element) => hashCode ^ element.hashCode);

  @core.override
  core.String toString() => 'Array${toList()}';
}

class MutableArrayImpl extends ArrayImpl implements MutableArray {
  MutableArrayImpl.fromPointer(
    Pointer<FLMutableArray> pointer, {
    core.bool retain = true,
  }) : super.fromPointer(pointer.cast(), retain: retain);

  factory MutableArrayImpl([core.Iterable<core.Object?>? data]) {
    final array = MutableArrayImpl.fromPointer(
      mutArrayBinds.makeNew(),
      retain: false,
    );

    if (data != null) {
      array.setData(data);
    }

    return array;
  }

  Pointer<FLMutableArray> get _mutablePointer => pointer.cast();

  Pointer<FLSlot> _setSlot(core.int index) {
    core.RangeError.checkValidIndex(index, this);

    return mutArrayBinds.set(_mutablePointer, index);
  }

  Pointer<FLSlot> _addSlot() => mutArrayBinds.append(_mutablePointer);

  Pointer<FLSlot> _insertSlot(core.int index) {
    core.RangeError.checkValidIndex(index, this);

    mutArrayBinds.insert(_mutablePointer, index, 1);
    return _setSlot(index);
  }

  // === Set Values ============================================================

  @core.override
  MutableArray setValue(core.int index, core.Object? value) {
    _setSlot(index).value = value;
    return this;
  }

  @core.override
  MutableArray setString(core.int index, core.String? value) {
    _setSlot(index).string = value;
    return this;
  }

  @core.override
  MutableArray setInt(core.int index, core.int value) {
    _setSlot(index).intNum = value;
    return this;
  }

  @core.override
  MutableArray setDouble(core.int index, core.double value) {
    _setSlot(index).doubleNum = value;
    return this;
  }

  @core.override
  MutableArray setNum(core.int index, core.num? value) {
    _setSlot(index).number = value;
    return this;
  }

  @core.override
  MutableArray setBool(core.int index, core.bool value) {
    _setSlot(index).boolean = value;
    return this;
  }

  @core.override
  MutableArray setDate(core.int index, core.DateTime? value) {
    _setSlot(index).date = value;
    return this;
  }

  @core.override
  MutableArray setBlob(core.int index, Blob? value) {
    _setSlot(index).blob = value;
    return this;
  }

  @core.override
  MutableArray setArray(core.int index, Array? value) {
    _setSlot(index).array = value;
    return this;
  }

  @core.override
  MutableArray setDictionary(core.int index, Dictionary? value) {
    _setSlot(index).dictionary = value;
    return this;
  }

  // === Append Values =========================================================

  @core.override
  MutableArray addValue(core.Object? value) {
    _addSlot().value = value;
    return this;
  }

  @core.override
  MutableArray addString(core.String? value) {
    _addSlot().string = value;
    return this;
  }

  @core.override
  MutableArray addInt(core.int value) {
    _addSlot().intNum = value;
    return this;
  }

  @core.override
  MutableArray addDouble(core.double value) {
    _addSlot().doubleNum = value;
    return this;
  }

  @core.override
  MutableArray addNum(core.num? value) {
    _addSlot().number = value;
    return this;
  }

  @core.override
  MutableArray addBool(core.bool value) {
    _addSlot().boolean = value;
    return this;
  }

  @core.override
  MutableArray addDate(core.DateTime? value) {
    _addSlot().date = value;
    return this;
  }

  @core.override
  MutableArray addBlob(Blob? value) {
    _addSlot().blob = value;
    return this;
  }

  @core.override
  MutableArray addArray(Array? value) {
    _addSlot().array = value;
    return this;
  }

  @core.override
  MutableArray addDictionary(Dictionary? value) {
    _addSlot().dictionary = value;
    return this;
  }

  // === Insert Values =========================================================

  @core.override
  MutableArray insertValue(core.int index, core.Object? value) {
    _insertSlot(index).value = value;
    return this;
  }

  @core.override
  MutableArray insertString(core.int index, core.String? value) {
    _insertSlot(index).string = value;
    return this;
  }

  @core.override
  MutableArray insertInt(core.int index, core.int value) {
    _insertSlot(index).intNum = value;
    return this;
  }

  @core.override
  MutableArray insertDouble(core.int index, core.double value) {
    _insertSlot(index).doubleNum = value;
    return this;
  }

  @core.override
  MutableArray insertNum(core.int index, core.num? value) {
    _insertSlot(index).number = value;
    return this;
  }

  @core.override
  MutableArray insertBool(core.int index, core.bool value) {
    _insertSlot(index).boolean = value;
    return this;
  }

  @core.override
  MutableArray insertDate(core.int index, core.DateTime? value) {
    _insertSlot(index).date = value;
    return this;
  }

  @core.override
  MutableArray insertBlob(core.int index, Blob? value) {
    _insertSlot(index).blob = value;
    return this;
  }

  @core.override
  MutableArray insertArray(core.int index, Array? value) {
    _insertSlot(index).array = value;
    return this;
  }

  @core.override
  MutableArray insertDictionary(core.int index, Dictionary? value) {
    _insertSlot(index).dictionary = value;
    return this;
  }

  // === Set Data ==============================================================

  @core.override
  MutableArray setData(core.Iterable<core.Object?> value) {
    final oldLength = length;
    var index = 0;

    for (final element in value) {
      if (index < oldLength) {
        setValue(index, element);
      } else {
        addValue(element);
      }
      index++;
    }

    if (oldLength > index) mutArrayBinds.resize(_mutablePointer, index);

    return this;
  }

  // === Remove Values =========================================================

  @core.override
  MutableArray removeValue(core.int index) {
    mutArrayBinds.remove(_mutablePointer, index, 1);
    return this;
  }

  // === Container Accessors ===================================================

  @core.override
  MutableArray? array(core.int index) {
    var array = super.array(index);
    if (array == null) return null;

    if (array is! MutableArray) {
      array = array.toMutable();
      setArray(index, array);
    }

    return array;
  }

  @core.override
  MutableDictionary? dictionary(core.int index) {
    var dictionary = super.dictionary(index);
    if (dictionary == null) return null;

    if (dictionary is! MutableDictionary) {
      dictionary = dictionary.toMutable();
      setDictionary(index, dictionary);
    }

    return dictionary;
  }

  // === MutableArrayFragment ==================================================

  @core.override
  MutableFragment operator [](core.int index) =>
      MutableFragment(parent: this, indexOrKey: index);

  // === Object ================================================================

  @core.override
  core.String toString() => 'MutableArray${toList()}';
}
