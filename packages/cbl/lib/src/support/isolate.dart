import 'package:cbl_ffi/cbl_ffi.dart' hide LibrariesConfiguration;

import '../document/common.dart';
import '../fleece/integration/integration.dart';
import '../tracing.dart';
import 'errors.dart';
import 'ffi.dart';
import 'tracing.dart';

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
    TracingDelegate? tracingDelegate,
  }) : tracingDelegate = tracingDelegate ?? const NoopTracingDelegate();

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

  final LibrariesConfiguration libraries;
  final InitContext? initContext;
  final TracingDelegate tracingDelegate;

  IsolateContext createSecondaryIsolateContext() => IsolateContext(
        libraries: libraries,
        tracingDelegate:
            effectiveTracingDelegate.createSecondaryIsolateDelegate(),
      );
}

/// Initializes this isolate for use of Couchbase Lite.
void initIsolate(IsolateContext context, {TraceDataHandler? onTraceData}) {
  IsolateContext.instance = context;
  CBLBindings.init(
    context.libraries.toCblFfi(),
    onTracedCall: tracingDelegateTracedNativeCallHandler,
  );
  MDelegate.instance = CblMDelegate();
  effectiveTracingDelegate = context.tracingDelegate;
  _onTraceData = onTraceData;
}

set _onTraceData(TraceDataHandler? value) => onTraceData = value;

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native libraries.
void initMainIsolate(IsolateContext context) {
  initIsolate(context);
  cblBindings.base.initializeNativeLibraries(context.initContext?.toCbl());
}
