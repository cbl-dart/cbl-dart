import 'dart:collection';

class ObjectRegistry {
  int _nextId = 0;

  final _idToObject = HashMap<int, Object>();
  final _objectToId = HashMap<Object, int>.identity();

  T? getObject<T>(int id) {
    final object = _idToObject[id];
    if (object is! T) {
      return null;
    }
    return object;
  }

  int? getObjectId(Object object) => _objectToId[object];

  List<Object> getObjects() => _objectToId.keys.toList().cast();

  int addObject(Object object) {
    if (_objectToId.containsKey(object)) {
      throw ArgumentError.value(object, 'object', 'has already been added');
    }

    final id = _createId();
    _idToObject[id] = object;
    _objectToId[object] = id;
    return id;
  }

  int addObjectIfAbsent(Object object) => _objectToId.putIfAbsent(object, () {
        final id = _createId();
        _idToObject[id] = object;
        return id;
      });

  void removeObject(Object object) {
    final id = _objectToId.remove(object);

    if (id == null) {
      throw ArgumentError.value(object, 'object', 'is not registered');
    }

    _idToObject.remove(id);
  }

  T removeObjectById<T extends Object>(int id) {
    final object = getObject<T>(id);

    if (object == null) {
      throw ArgumentError.value(
        id,
        'id',
        'object with this type $T and id $id is not registered',
      );
    }

    _objectToId.remove(object);
    return object;
  }

  void clear() {
    _idToObject.clear();
    _objectToId.clear();
  }

  int _createId() => _nextId++;
}
