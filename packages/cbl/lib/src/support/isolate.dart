import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/common.dart';
import '../errors.dart';
import '../fleece/integration/integration.dart';
import 'ffi.dart' as ffi;

class IsolateContext {
  IsolateContext({
    required this.libraries,
    this.cblInitContext,
  });

  static IsolateContext? _instance;

  static set instance(IsolateContext value) {
    if (_instance != null) {
      throwAlreadyInitializedError();
    }
    _instance = value;
  }

  static IsolateContext get instance {
    final config = _instance;
    if (config == null) {
      throwNotInitializedError();
    }
    return config;
  }

  final Libraries libraries;
  final CBLInitContext? cblInitContext;
}

/// Initializes this isolate for use of Couchbase Lite.
void initIsolate(IsolateContext context) {
  IsolateContext.instance = context;
  CBLBindings.init(context.libraries);
  MDelegate.instance = CblMDelegate();
}

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native libraries.
void initMainIsolate(IsolateContext context) {
  initIsolate(context);
  ffi.cblBindings.base.initializeNativeLibraries(context.cblInitContext);
}
