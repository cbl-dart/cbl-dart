import 'package:cbl_ffi/cbl_ffi.dart' as ffi;

/// The native libraries used by worker isolates.
late ffi.Libraries workerLibraries;

/// Convenience accessor for `CBLBindings.instance`, which throws an informative
/// error when used before the bindings are initialized.
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
