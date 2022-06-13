// ignore: lines_longer_than_80_chars
// ignore_for_file: cast_nullable_to_non_nullable, avoid_setters_without_getters, one_member_abstracts

import '../support/errors.dart';
import 'array.dart';
import 'blob.dart';
import 'dictionary.dart';
import 'document.dart';

/// Readonly access to the data value wrapped by a [Fragment] object.
///
/// {@category Document}
abstract class FragmentInterface {
  /// The value of this fragment as a value of type [T].
  T? valueAs<T extends Object>();

  /// The value of this fragment.
  Object? get value;

  /// The value of this fragment as a [String].
  String? get string;

  /// The value of this fragment as an integer number.
  int get integer;

  /// The value of this fragment as a floating point number.
  double get float;

  /// The value of this fragment as a [num].
  num? get number;

  /// The value of this fragment as a [bool].
  bool get boolean;

  /// The value of this fragment as a [DateTime].
  DateTime? get date;

  /// The value of this fragment as a [Blob].
  Blob? get blob;

  /// The value of this fragment as an [Array].
  Array? get array;

  /// The value of this fragment as a [Dictionary].
  Dictionary? get dictionary;

  /// Whether the value of this fragment exists.
  bool get exists;
}

/// Read and write access to the data value wrapped by a [Fragment] object.
///
/// {@category Document}
abstract class MutableFragmentInterface implements FragmentInterface {
  /// Sets the value of this fragment.
  ///
  /// {@macro cbl.MutableArray.allowedValueTypes}
  set value(Object? value);
  set string(String? value);
  set integer(int value);
  set float(double value);
  set number(num? value);
  set boolean(bool value);
  set date(DateTime? value);
  set blob(Blob? value);
  set array(Array? value);
  set dictionary(Dictionary? value);
}

/// Provides subscript access to [Fragment] objects by index.
///
/// {@category Document}
abstract class ArrayFragment {
  /// Returns a [Fragment] for the value at the given [index].
  Fragment operator [](int index);
}

/// Provides subscript access to [MutableFragment] objects by index.
///
/// {@category Document}
abstract class MutableArrayFragment {
  /// Returns a [MutableFragment] for the value at the given [index].
  MutableFragment operator [](int index);
}

/// Provides subscript access to [Fragment] objects by key.
///
/// {@category Document}
abstract class DictionaryFragment {
  /// Returns a [Fragment] for the value at the given [key].
  Fragment operator [](String key);
}

/// Provides subscript access to [MutableFragment] objects by key.
///
/// {@category Document}
abstract class MutableDictionaryFragment {
  /// Returns a [MutableFragment] for the value at the given [key].
  MutableFragment operator [](String key);
}

/// Provides readonly access to data value.
///
/// [Fragment] also provides subscript access by either key or index to the
/// nested values which are wrapped by [Fragment] objects.
///
/// {@category Document}
abstract class Fragment
    implements FragmentInterface, ArrayFragment, DictionaryFragment {
  Fragment operator [](Object indexOrKey);
}

/// Provides read and write access to data value.
///
/// [MutableFragment] also provides subscript access by either key or index to
/// the nested values which are wrapped by [MutableFragment] objects.
///
/// {@category Document}
abstract class MutableFragment
    implements
        Fragment,
        MutableFragmentInterface,
        MutableArrayFragment,
        MutableDictionaryFragment {
  MutableFragment operator [](Object indexOrKey);
}

/// Provides access to a [Document].
///
/// [DocumentFragment] also provides subscript access by either key to the data
/// values of the document which are wrapped by Fragment objects.
///
/// {@category Document}
abstract class DocumentFragment implements DictionaryFragment {
  /// Whether the document exists in the database or not.
  bool get exists;

  /// The [Document] wrapped by this fragment.
  Document? get document;
}

class FragmentImpl implements Fragment {
  FragmentImpl._empty();

  FragmentImpl.fromArray(Array array, {required int index})
      : _parent = array,
        _index = index;

  FragmentImpl.fromDictionary(Dictionary dictionary, {required String key})
      : _parent = dictionary,
        _key = key;

  static final Fragment _emptyInstance = FragmentImpl._empty();

  Object? _parent;
  int _index = 0;
  String? _key;

  @override
  T? valueAs<T extends Object>() {
    if (_key != null) {
      return (_parent as Dictionary?)?.value(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.value(_index);
    }
    return null;
  }

  @override
  Object? get value {
    if (_key != null) {
      return (_parent as Dictionary?)?.value(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.value(_index);
    }
    return null;
  }

  @override
  String? get string {
    if (_key != null) {
      return (_parent as Dictionary?)?.string(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.string(_index);
    }
    return null;
  }

  @override
  int get integer {
    int? result;
    if (_key != null) {
      result = (_parent as Dictionary?)?.integer(_key!);
    } else if (_isValidIndex()) {
      result = (_parent as Array?)?.integer(_index);
    }
    return result ?? 0;
  }

  @override
  double get float {
    double? result;
    if (_key != null) {
      result = (_parent as Dictionary?)?.float(_key!);
    } else if (_isValidIndex()) {
      result = (_parent as Array?)?.float(_index);
    }
    return result ?? 0;
  }

  @override
  num? get number {
    if (_key != null) {
      return (_parent as Dictionary?)?.number(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.number(_index);
    }
    return null;
  }

  @override
  bool get boolean {
    bool? result;
    if (_key != null) {
      result = (_parent as Dictionary?)?.boolean(_key!);
    } else if (_isValidIndex()) {
      result = (_parent as Array?)?.boolean(_index);
    }
    return result ?? false;
  }

  @override
  DateTime? get date {
    if (_key != null) {
      return (_parent as Dictionary?)?.date(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.date(_index);
    }
    return null;
  }

  @override
  Blob? get blob {
    if (_key != null) {
      return (_parent as Dictionary?)?.blob(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.blob(_index);
    }
    return null;
  }

  @override
  Array? get array {
    if (_key != null) {
      return (_parent as Dictionary?)?.array(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.array(_index);
    }
    return null;
  }

  @override
  Dictionary? get dictionary {
    if (_key != null) {
      return (_parent as Dictionary?)?.dictionary(_key!);
    } else if (_isValidIndex()) {
      return (_parent as Array?)?.dictionary(_index);
    }
    return null;
  }

  @override
  bool get exists {
    final parent = _parent;
    if (parent == null) {
      return false;
    }

    if (_key != null) {
      return (_parent as Dictionary).contains(_key);
    } else {
      return (_parent as Array).length > _index;
    }
  }

  @override
  Fragment operator [](Object indexOrKey) =>
      _updateSubscript(indexOrKey) ? this : _emptyInstance;

  bool _updateSubscript(Object indexOrKey) {
    assertIndexOrKey(indexOrKey);

    final value = this.value;

    if (value is Array && indexOrKey is int) {
      if (indexOrKey >= value.length) {
        return false;
      }
      _parent = value;
      _index = indexOrKey;
      _key = null;
      return true;
    }

    if (value is Dictionary && indexOrKey is String) {
      _parent = value;
      _key = indexOrKey;
      return true;
    }

    return false;
  }

  bool _isValidIndex() {
    assert(_key == null);
    final parent = _parent as Array?;
    if (parent == null) {
      return true;
    }
    return parent.length > _index;
  }
}

class MutableFragmentImpl extends FragmentImpl implements MutableFragment {
  MutableFragmentImpl._empty() : super._empty();

  MutableFragmentImpl.fromArray(
    MutableArray super.array, {
    required super.index,
  }) : super.fromArray();

  MutableFragmentImpl.fromDictionary(
    MutableDictionary super.dictionary, {
    required super.key,
  }) : super.fromDictionary();

  static final _emptyInstance = MutableFragmentImpl._empty();

  @override
  set value(Object? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setValue(value, key: _key!);
    } else {
      (_parent as MutableArray).setValue(value, at: _index);
    }
  }

  @override
  set string(String? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setString(value, key: _key!);
    } else {
      (_parent as MutableArray).setString(value, at: _index);
    }
  }

  @override
  set integer(int value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setInteger(value, key: _key!);
    } else {
      (_parent as MutableArray).setInteger(value, at: _index);
    }
  }

  @override
  set float(double value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setFloat(value, key: _key!);
    } else {
      (_parent as MutableArray).setFloat(value, at: _index);
    }
  }

  @override
  set number(num? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setNumber(value, key: _key!);
    } else {
      (_parent as MutableArray).setNumber(value, at: _index);
    }
  }

  @override
  set boolean(bool value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setBoolean(value, key: _key!);
    } else {
      (_parent as MutableArray).setBoolean(value, at: _index);
    }
  }

  @override
  set date(DateTime? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setDate(value, key: _key!);
    } else {
      (_parent as MutableArray).setDate(value, at: _index);
    }
  }

  @override
  set blob(Blob? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setBlob(value, key: _key!);
    } else {
      (_parent as MutableArray).setBlob(value, at: _index);
    }
  }

  @override
  set array(Array? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setArray(value, key: _key!);
    } else {
      (_parent as MutableArray).setArray(value, at: _index);
    }
  }

  @override
  set dictionary(Dictionary? value) {
    _checkHasParent();

    if (_key != null) {
      (_parent as MutableDictionary).setDictionary(value, key: _key!);
    } else {
      (_parent as MutableArray).setDictionary(value, at: _index);
    }
  }

  @override
  MutableFragment operator [](Object indexOrKey) =>
      _updateSubscript(indexOrKey) ? this : _emptyInstance;

  void _checkHasParent() {
    if (_parent == null) {
      throw StateError(
        'The value of a Fragment cannot be set if it references a path outside '
        'an existing collection.',
      );
    }
  }
}

class DocumentFragmentImpl implements DocumentFragment {
  DocumentFragmentImpl(this.document);

  @override
  final Document? document;

  @override
  bool get exists => document != null;

  @override
  Fragment operator [](String key) =>
      document?[key] ?? FragmentImpl._emptyInstance;
}
