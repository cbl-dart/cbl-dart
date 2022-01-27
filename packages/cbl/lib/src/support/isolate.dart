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
    this.tracingDelegate,
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

  final LibrariesConfiguration libraries;
  final InitContext? initContext;
  final TracingDelegate? tracingDelegate;

  IsolateContext createForWorkerIsolate() => IsolateContext(
        libraries: libraries,
        tracingDelegate: effectiveTracingDelegate.createWorkerDelegate(),
      );
}

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native libraries.
void initPrimaryIsolate(IsolateContext context) {
  _initIsolate(context);
  cblBindings.base.initializeNativeLibraries(context.initContext?.toCbl());
}

/// Initializes this isolate for use of Couchbase Lite, after another primary
/// isolate has been initialized.
void initSecondaryIsolate(IsolateContext context) {
  _initIsolate(context);
}

/// Initializes this isolate for use as a Couchbase Lite worker isolate.
Future<void> initWorkerIsolate(
  IsolateContext context, {
  required TraceDataHandler onTraceData,
}) async {
  _initIsolate(context, onTraceData: onTraceData);

  final tracingDelegate = context.tracingDelegate;
  if (tracingDelegate != null) {
    TracingDelegate.install(tracingDelegate);
    await tracingDelegate.initializeWorkerDelegate();
  }
}

void _initIsolate(IsolateContext context, {TraceDataHandler? onTraceData}) {
  IsolateContext.instance = context;

  CBLBindings.init(
    context.libraries.toCblFfi(),
    onTracedCall: tracingDelegateTracedNativeCallHandler,
  );

  MDelegate.instance = CblMDelegate();

  _onTraceData = onTraceData;
}

set _onTraceData(TraceDataHandler? value) => onTraceData = value;
