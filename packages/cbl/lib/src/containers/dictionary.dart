import 'dart:collection';
import 'dart:core' as core;
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../blob.dart';
import 'array.dart';
import 'fragment.dart';
import 'utils.dart';

abstract class DictionaryAccessors implements DictionaryFragment {
  core.int get length;
  core.List<core.String> get keys;
  core.Object? value(core.String key);
  core.String? string(core.String key);
  core.int int(core.String key);
  core.double double(core.String key);
  core.num? num(core.String key);
  core.bool bool(core.String key);
  core.DateTime? date(core.String key);
  Blob? blob(core.String key);
  Array? array(core.String key);
  Dictionary? dictionary(core.String key);
  core.bool contains(core.String key);
  core.Map<core.String, core.Object?> toMap();
}

abstract class MutableDictionaryAccessors<
        Self extends MutableDictionaryAccessors<void>>
    implements DictionaryAccessors, MutableDictionaryFragment {
  Self setValue(core.String key, core.Object? value);
  Self setString(core.String key, core.String? value);
  Self setInt(core.String key, core.int value);
  Self setDouble(core.String key, core.double value);
  Self setNum(core.String key, core.num? value);
  Self setBool(core.String key, core.bool value);
  Self setDate(core.String key, core.DateTime? value);
  Self setBlob(core.String key, Blob? value);
  Self setArray(core.String key, Array? value);
  Self setDictionary(core.String key, Dictionary? value);

  Self setData(core.Map<core.String, core.Object?> data);

  Self removeValue(core.String key);

  @core.override
  MutableArray? array(core.String key);
  @core.override
  MutableDictionary? dictionary(core.String key);
}

abstract class Dictionary
    implements DictionaryAccessors, core.Iterable<core.String> {
  MutableDictionary toMutable();
}

abstract class MutableDictionary
    implements Dictionary, MutableDictionaryAccessors<MutableDictionary> {
  factory MutableDictionary([core.Map<core.String, core.Object?>? data]) =>
      MutableDictionaryImpl(data);
}

class DictionaryImpl with IterableMixin<core.String> implements Dictionary {
  DictionaryImpl.fromPointer(
    this.pointer, {
    core.bool retain = true,
  }) {
    valueBinds.bindToDartObject(this, pointer.cast(), retain.toInt());
  }

  final Pointer<FLDict> pointer;

  Pointer<FLValue> _getValue(core.String key) =>
      runArena(() => dictBinds.get(pointer, key.toNativeUtf8().withScoped()));

  // === ArrayAccessors ========================================================

  @core.override
  core.int get length => dictBinds.count(pointer);

  @core.override
  core.List<core.String> get keys => toList();

  @core.override
  core.Object? value(core.String key) => _getValue(key).value;

  @core.override
  core.String? string(core.String key) => _getValue(key).string;

  @core.override
  core.int int(core.String key) => _getValue(key).intNumber;

  @core.override
  core.double double(core.String key) => _getValue(key).doubleNumber;

  @core.override
  core.num? num(core.String key) => _getValue(key).number;

  @core.override
  core.bool bool(core.String key) => _getValue(key).boolean;

  @core.override
  core.DateTime? date(core.String key) => _getValue(key).date;

  @core.override
  Blob? blob(core.String key) => _getValue(key).blob;

  @core.override
  Array? array(core.String key) => _getValue(key).array;

  @core.override
  Dictionary? dictionary(core.String key) => _getValue(key).dictionary;

  @core.override
  core.bool contains(core.Object? key) {
    if (key is! core.String) {
      throw core.ArgumentError.value(value, 'key', 'must be a String');
    }
    return _getValue(key) != nullptr;
  }

  @core.override
  core.Map<core.String, core.Object?> toMap() => <core.String, core.Object?>{
        for (final key in this) key: convertContainersToPrimitives(value(key)),
      };

  // === DictionaryFragment ====================================================

  @core.override
  Fragment operator [](core.String key) =>
      Fragment(parent: this, indexOrKey: key);

  // === Dictionary ============================================================

  @core.override
  MutableDictionary toMutable() {
    final core.Object self = this;
    if (self is MutableDictionary) {
      return self;
    }

    var mutableValue = dictBinds.asMutable(pointer);
    if (mutableValue != nullptr) {
      return MutableDictionaryImpl.fromPointer(mutableValue);
    }

    mutableValue = mutDictBinds.mutableCopy(pointer, 0);
    return MutableDictionaryImpl.fromPointer(mutableValue, retain: false);
  }

  // === Iterable ==============================================================

  @core.override
  core.Iterator<core.String> get iterator => _DictKeyIterator(this);

  // === Object ================================================================

  @core.override
  core.bool operator ==(core.Object other) =>
      core.identical(this, other) ||
      other is DictionaryImpl &&
          valueBinds.isEqual(pointer.cast(), other.pointer.cast()).toBool();

  @core.override
  core.int get hashCode => fold(31, (hashCode, key) {
        return hashCode ^ key.hashCode ^ value(key).hashCode;
      });

  @core.override
  core.String toString() => 'Dictionary${toMap()}';
}

/// Iterator which iterates over the keys of a [Dictionary].
class _DictKeyIterator extends core.Iterator<core.String> {
  _DictKeyIterator(this.dictionary);

  final DictionaryImpl dictionary;

  Pointer<DictIterator>? iterator;

  @core.override
  late core.String current;

  @core.override
  core.bool moveNext() {
    // Create the iterator if it does not exist yet.
    iterator ??= dictIterBinds.begin(this, dictionary.pointer.cast());

    // The iterator has no more elements.
    if (iterator!.ref.done.toBool()) return false;

    // Advance to the next item.
    dictIterBinds.next(iterator!);

    final slice = iterator!.ref.keyString;

    // If iterator has no elements at all, slice is the kNullSlice.
    if (slice.isNull) return false;

    // Update current with keyString.
    current = slice.toDartString()!;

    return true;
  }
}

class MutableDictionaryImpl extends DictionaryImpl
    implements MutableDictionary {
  MutableDictionaryImpl.fromPointer(
    Pointer<FLMutableDict> pointer, {
    core.bool retain = true,
  }) : super.fromPointer(pointer.cast(), retain: retain);

  factory MutableDictionaryImpl([core.Map<core.String, core.Object?>? data]) {
    final dictionary = MutableDictionaryImpl.fromPointer(
      mutDictBinds.makeNew(),
      retain: false,
    );

    if (data != null) {
      dictionary.setData(data);
    }

    return dictionary;
  }

  Pointer<FLMutableDict> get _mutablePointer => pointer.cast();

  Pointer<FLSlot> _setSlot(core.String key) => runArena(
      () => mutDictBinds.set(_mutablePointer, key.toNativeUtf8().withScoped()));

  // === Set Values ============================================================

  @core.override
  MutableDictionary setValue(core.String key, core.Object? value) {
    _setSlot(key).value = value;
    return this;
  }

  @core.override
  MutableDictionary setString(core.String key, core.String? value) {
    _setSlot(key).string = value;
    return this;
  }

  @core.override
  MutableDictionary setInt(core.String key, core.int value) {
    _setSlot(key).intNum = value;
    return this;
  }

  @core.override
  MutableDictionary setDouble(core.String key, core.double value) {
    _setSlot(key).doubleNum = value;
    return this;
  }

  @core.override
  MutableDictionary setNum(core.String key, core.num? value) {
    _setSlot(key).number = value;
    return this;
  }

  @core.override
  MutableDictionary setBool(core.String key, core.bool value) {
    _setSlot(key).boolean = value;
    return this;
  }

  @core.override
  MutableDictionary setDate(core.String key, core.DateTime? value) {
    _setSlot(key).date = value;
    return this;
  }

  @core.override
  MutableDictionary setBlob(core.String key, Blob? value) {
    _setSlot(key).blob = value;
    return this;
  }

  @core.override
  MutableDictionary setArray(core.String key, Array? value) {
    _setSlot(key).array = value;
    return this;
  }

  @core.override
  MutableDictionary setDictionary(core.String key, Dictionary? value) {
    _setSlot(key).dictionary = value;
    return this;
  }

  // === Set Data ==============================================================

  @core.override
  MutableDictionary setData(core.Map<core.String, core.Object?>? data) {
    final keysToRemove = keys;

    for (final entry in (data ?? {}).entries) {
      keysToRemove.remove(entry.key);
      setValue(entry.key, entry.value);
    }

    for (final key in keysToRemove) {
      removeValue(key);
    }

    return this;
  }

  // === Remove Values =========================================================

  @core.override
  MutableDictionary removeValue(core.String key) {
    runArena(() {
      mutDictBinds.remove(_mutablePointer, key.toNativeUtf8().withScoped());
    });
    return this;
  }

  // === Container Accessors ===================================================

  @core.override
  MutableArray? array(core.String key) {
    var array = super.array(key);
    if (array == null) return null;

    if (array is! MutableArray) {
      array = array.toMutable();
      setArray(key, array);
    }

    return array;
  }

  @core.override
  MutableDictionary? dictionary(core.String key) {
    var dictionary = super.dictionary(key);
    if (dictionary == null) return null;

    if (dictionary is! MutableDictionary) {
      dictionary = dictionary.toMutable();
      setDictionary(key, dictionary);
    }

    return dictionary;
  }

  // === MutableDictionaryFragment =============================================

  @core.override
  MutableFragment operator [](core.String key) =>
      MutableFragment(parent: this, indexOrKey: key);

  // === MutableDictionaryFragment =============================================

  @core.override
  core.String toString() => 'MutableDictionary${toMap()}';
}
