import 'package:cbl_ffi/cbl_ffi.dart';

import 'document/common.dart';
import 'fleece/integration/integration.dart';
import 'support/ffi.dart' as ffi;

void initIsolate({required Libraries libraries}) {
  CBLBindings.init(libraries);
  MDelegate.instance = CblMDelegate();
}

void initMainIsolate({
  required Libraries libraries,
  CBLInitContext? context,
}) {
  initIsolate(libraries: libraries);

  ffi.libraries = libraries;
  ffi.cblBindings.base.init(context: context);
}
