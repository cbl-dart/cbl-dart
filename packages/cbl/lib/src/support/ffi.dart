import 'package:cbl_ffi/cbl_ffi.dart' as ffi;

import '../errors.dart';

/// Convenience accessor for `CBLBindings.instance`, which throws an informative
/// error when used before the bindings are initialized.
late final ffi.CBLBindings cblBindings = () {
  final bindings = ffi.CBLBindings.maybeInstance;
  if (bindings == null) {
    throwNotInitializedError();
  }
  return bindings;
}();
