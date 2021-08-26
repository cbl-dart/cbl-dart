import 'package:cbl_ffi/cbl_ffi.dart';

import 'document/common.dart';
import 'fleece/integration/integration.dart';
import 'support/ffi.dart' as ffi;

/// Initializes this isolate for use of Couchbase Lite.
void initIsolate({required Libraries libraries}) {
  CBLBindings.init(libraries);
  MDelegate.instance = CblMDelegate();
}

/// Initializes this isolate for use of Couchbase Lite, by an end user of
/// the `cbl` library.
void initMainIsolate({
  required Libraries libraries,
  CBLInitContext? context,
  void Function()? onFirstInit,
}) {
  initIsolate(libraries: libraries);

  // Setup the native libraries used to in worker isolates.
  ffi.workerLibraries = libraries;

  // Initialize the native libraries.
  if (ffi.cblBindings.base.init(context: context)) {
    onFirstInit?.call();
  }
}
