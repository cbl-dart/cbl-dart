import '../database/database.dart';

Never throwNotInitializedError() {
  throw StateError('Couchbase Lite must be initialized before using it.');
}

Never throwAlreadyInitializedError() {
  throw StateError('Couchbase Lite has already been initialized.');
}

T assertArgumentType<T>(Object? value, String name) {
  if (value is! T) {
    throw ArgumentError.value(value, name, 'must be of type $T');
  }
  return value;
}

void assertIndexOrKey(Object? indexOrKey) {
  if (indexOrKey is! int && indexOrKey is! String) {
    throw ArgumentError.value(
      indexOrKey,
      'indexOrKey',
      'must be of type int or String',
    );
  }
}

String assertKey(Object? key) => assertArgumentType<String>(key, 'key');

bool assertMatchingDatabase(
  Database? current,
  Database target,
  String valueType,
) {
  if (current == null) {
    return true;
  }

  if (current == target) {
    return false;
  }

  throw StateError(
    '$valueType cannot be used with database ${target.name} because it '
    'already belongs to database ${current.name}.',
  );
}
