import 'package:cbl_ffi/cbl_ffi.dart';

import 'document/common.dart';
import 'fleece/integration/integration.dart';
import 'support/ffi.dart' as ffi;

/// Initializes this isolate for use of Couchbase Lite.
void initIsolate({required Libraries libraries}) {
  CBLBindings.init(libraries);
  MDelegate.instance = CblMDelegate();
  ffi.workerLibraries = libraries;
}

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native library.
void initMainIsolate({
  required Libraries libraries,
  CBLInitContext? context,
}) {
  initIsolate(libraries: libraries);
  ffi.cblBindings.base.init(context: context);
}
