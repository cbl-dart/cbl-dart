import 'package:cbl_ffi/cbl_ffi.dart' as ffi;

import '../couchbase_lite.dart';

Libraries? _libraries;

Libraries get libraries {
  if (_libraries == null) {
    _throwCblNotInitializedError();
  }
  return _libraries!;
}

set libraries(Libraries value) => _libraries = value;

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
