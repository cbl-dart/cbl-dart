import 'dart:core' as core;

import 'array.dart';
import '../blob.dart';
import 'dictionary.dart';

/// Provides readonly access to the data value wrapped by a [Fragment] object.
abstract class FragmentAccessors {
  core.Object? get value;
  core.String? get string;
  core.int get int;
  core.double get double;
  core.num? get num;
  core.bool get bool;
  core.DateTime? get date;
  Blob? get blob;
  Array? get array;
  Dictionary? get dictionary;
  core.bool get exists;
}

/// Provides read and write access to the data value wrapped by [Fragment]
/// object.
abstract class MutableFragmentAccessors extends FragmentAccessors {
  set value(core.Object? value);
  set string(core.String? value);
  set int(core.int value);
  set double(core.double value);
  set num(core.num? value);
  set bool(core.bool value);
  set date(core.DateTime? value);
  set blob(Blob? value);
  set array(Array? value);
  set dictionary(Dictionary? value);
}

/// Provides subscript access to [Fragment] objects by index.
abstract class ArrayFragment {
  Fragment operator [](core.int index);
}

/// Provides subscript access to [MutableFragment] objects by index.
abstract class MutableArrayFragment {
  MutableFragment operator [](core.int index);
}

/// Provides subscript access to Fragment objects by key.
abstract class DictionaryFragment {
  Fragment operator [](core.String key);
}

/// Provides subscript access to [MutableFragment] objects by key.
abstract class MutableDictionaryFragment {
  MutableFragment operator [](core.String key);
}

/// Provides readonly access to data value. [Fragment] also provides subscript
/// access by either key or index to the nested values which are wrapped by
/// [Fragment] objects.
abstract class Fragment
    implements FragmentAccessors, ArrayFragment, DictionaryFragment {
  factory Fragment({
    required core.Object parent,
    required core.Object indexOrKey,
  }) {
    if (_Fragment.indexOrKeyIsValidForParent(
      parent: parent,
      indexOrKey: indexOrKey,
    )) {
      return _Fragment(parent: parent, indexOrKey: indexOrKey);
    }
    return _NullFragment();
  }

  Fragment operator [](core.Object indexOrKey);
}

/// Provides read and write access to data value. [MutableFragment] also provides
/// subscript access by either key or index to the nested values which are
/// wrapped by [MutableFragment] objects.
abstract class MutableFragment
    implements
        Fragment,
        MutableFragmentAccessors,
        MutableArrayFragment,
        MutableDictionaryFragment {
  factory MutableFragment({
    required core.Object parent,
    required core.Object indexOrKey,
  }) {
    if (_Fragment.indexOrKeyIsValidForParent(
      parent: parent,
      indexOrKey: indexOrKey,
    )) {
      return _MutableFragment(parent: parent, indexOrKey: indexOrKey);
    }
    return _MutableNullFragment();
  }

  MutableFragment operator [](core.Object indexOrKey);
}

class _Fragment implements Fragment {
  static core.bool indexOrKeyIsValidForParent({
    required core.Object parent,
    required core.Object indexOrKey,
  }) =>
      (parent is ArrayAccessors && indexOrKey is core.int) ||
      (parent is DictionaryAccessors && indexOrKey is core.String);

  _Fragment({
    required core.Object parent,
    required core.Object indexOrKey,
  })   : assert(parent is ArrayAccessors || parent is DictionaryAccessors),
        assert(indexOrKeyIsValidForParent(
          parent: parent,
          indexOrKey: indexOrKey,
        )),
        _parent = parent,
        _indexOrKey = indexOrKey;

  final core.Object _parent;
  final core.Object _indexOrKey;

  @core.override
  core.Object? get value {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).value(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).value(_indexOrKey as core.String);
  }

  @core.override
  core.String? get string {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).string(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).string(_indexOrKey as core.String);
  }

  @core.override
  core.int get int {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).int(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).int(_indexOrKey as core.String);
  }

  @core.override
  core.double get double {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).double(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).double(_indexOrKey as core.String);
  }

  @core.override
  core.num? get num {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).num(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).num(_indexOrKey as core.String);
  }

  @core.override
  core.bool get bool {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).bool(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).bool(_indexOrKey as core.String);
  }

  @core.override
  core.DateTime? get date {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).date(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).date(_indexOrKey as core.String);
  }

  @core.override
  Blob? get blob {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).blob(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).blob(_indexOrKey as core.String);
  }

  @core.override
  Array? get array {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).array(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors).array(_indexOrKey as core.String);
  }

  @core.override
  Dictionary? get dictionary {
    if (_parent is ArrayAccessors) {
      return (_parent as ArrayAccessors).dictionary(_indexOrKey as core.int);
    }

    return (_parent as DictionaryAccessors)
        .dictionary(_indexOrKey as core.String);
  }

  @core.override
  core.bool get exists => value != null;

  @core.override
  Fragment operator [](core.Object indexOrKey) {
    if (indexOrKey is! core.int && indexOrKey is! core.String) {
      throw core.ArgumentError.value(
        indexOrKey,
        'indexOrKey',
        'must be an int or String',
      );
    }

    final value = this.value;

    if (value == null) {
      return const _NullFragment();
    }

    // value is a container we can use as a parent for a new Fragment.
    if (value is ArrayAccessors || value is DictionaryAccessors) {
      return Fragment(parent: value, indexOrKey: indexOrKey);
    }

    // value is not a container.
    return const _NullFragment();
  }
}

class _MutableFragment extends _Fragment implements MutableFragment {
  _MutableFragment({
    required core.Object parent,
    required core.Object indexOrKey,
  })   : assert(parent is MutableArrayAccessors ||
            parent is MutableDictionaryAccessors),
        super(parent: parent, indexOrKey: indexOrKey);

  @core.override
  set value(core.Object? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setValue(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setValue(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set string(core.String? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setString(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setString(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set int(core.int value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors).setInt(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setInt(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set double(core.double value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setDouble(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setDouble(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set num(core.num? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors).setNum(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setNum(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set bool(core.bool value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setBool(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setBool(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set date(core.DateTime? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setDate(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setDate(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set blob(Blob? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setBlob(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setBlob(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set array(Array? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setArray(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setArray(_indexOrKey as core.String, value);
    }
  }

  @core.override
  set dictionary(Dictionary? value) {
    if (_parent is MutableArrayAccessors) {
      (_parent as MutableArrayAccessors)
          .setDictionary(_indexOrKey as core.int, value);
    } else {
      (_parent as MutableDictionaryAccessors)
          .setDictionary(_indexOrKey as core.String, value);
    }
  }

  @core.override
  MutableFragment operator [](core.Object indexOrKey) {
    if (indexOrKey is! core.int && indexOrKey is! core.String) {
      throw core.ArgumentError.value(
        indexOrKey,
        'indexOrKey',
        'must be an int or String',
      );
    }

    var value = this.value;

    // parent container does not have a value for this fragment so we can
    // add a container which is compatible with `indexOrKey`.
    if (value == null) {
      if (indexOrKey is core.int) {
        value = MutableArray();
      } else {
        value = MutableDictionary();
      }
      _insertIntoParent(value);
    }

    // value is a container we can use as a parent for a new Fragment.
    if (value is MutableArrayAccessors || value is MutableDictionaryAccessors) {
      return MutableFragment(parent: value, indexOrKey: indexOrKey);
    }

    // value is not a container.
    return const _MutableNullFragment();
  }

  void _insertIntoParent(core.Object value) {
    final parent = _parent;
    if (parent is MutableArrayAccessors) {
      parent.insertValue(_indexOrKey as core.int, value);
    }
    if (parent is MutableDictionaryAccessors) {
      parent.setValue(_indexOrKey as core.String, value);
    }
  }
}

class _NullFragment implements Fragment {
  const _NullFragment();

  @core.override
  core.Object? get value => null;

  @core.override
  core.String? get string => null;

  @core.override
  core.int get int => 0;

  @core.override
  core.double get double => 0;

  @core.override
  core.num? get num => null;

  @core.override
  core.bool get bool => false;

  @core.override
  core.DateTime? get date => null;

  @core.override
  Blob? get blob => null;

  @core.override
  Array? get array => null;

  @core.override
  Dictionary? get dictionary => null;

  @core.override
  core.bool get exists => false;

  @core.override
  Fragment operator [](core.Object indexOrKey) => const _NullFragment();
}

class _MutableNullFragment extends _NullFragment implements MutableFragment {
  const _MutableNullFragment();
  @core.override
  set value(core.Object? value) {}

  @core.override
  set string(core.String? value) {}

  @core.override
  set int(core.int value) {}

  @core.override
  set double(core.double value) {}

  @core.override
  set num(core.num? value) {}

  @core.override
  set bool(core.bool value) {}

  @core.override
  set date(core.DateTime? value) {}

  @core.override
  set blob(Blob? value) {}

  @core.override
  set array(Array? value) {}

  @core.override
  set dictionary(Dictionary? value) {}

  @core.override
  MutableFragment operator [](core.Object indexOrKey) =>
      const _MutableNullFragment();
}
