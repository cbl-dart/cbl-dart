import 'package:cbl_ffi/cbl_ffi.dart' hide Libraries;

import '../document/common.dart';
import '../fleece/integration/integration.dart';
import 'errors.dart';
import 'ffi.dart';

class InitContext {
  InitContext({required this.filesDir, required this.tempDir});

  final String filesDir;
  final String tempDir;

  CBLInitContext toCbl() =>
      CBLInitContext(filesDir: filesDir, tempDir: tempDir);
}

class IsolateContext {
  IsolateContext({
    required this.libraries,
    this.initContext,
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
  final InitContext? initContext;
}

/// Initializes this isolate for use of Couchbase Lite.
void initIsolate(IsolateContext context) {
  IsolateContext.instance = context;
  CBLBindings.init(context.libraries.toCblFfi());
  MDelegate.instance = CblMDelegate();
}

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native libraries.
void initMainIsolate(IsolateContext context) {
  initIsolate(context);
  cblBindings.base.initializeNativeLibraries(context.initContext?.toCbl());
}
