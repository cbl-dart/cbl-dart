import 'package:cbl_ffi/cbl_ffi.dart' as ffi;

ffi.Libraries? libraries;

late final ffi.CBLBindings cblBindings = () {
  final bindings = ffi.CBLBindings.maybeInstance;
  if (bindings == null) {
    _throwCblNotInitializedError();
  }
  return bindings;
}();

Never _throwCblNotInitializedError() {
  throw StateError(
    'CouchbaseLite.init must be called before using the cbl library.',
  );
}
