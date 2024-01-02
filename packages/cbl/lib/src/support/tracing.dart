import 'dart:async';

import '../bindings.dart';
import '../tracing.dart';

/// The current tracing delegate.
TracingDelegate currentTracingDelegate = const NoopTracingDelegate();

/// Sends trace data that is collected in this isolate to the main isolate.
typedef TraceDataHandler = void Function(Object? data);

void _noopTraceDataHandler(Object? data) {}

/// The current trace data handler.
TraceDataHandler onTraceData = _noopTraceDataHandler;

class NoopTracingDelegate extends TracingDelegate {
  const NoopTracingDelegate();
}

@pragma('vm:prefer-inline')
T syncOperationTracePoint<T>(
  TracedOperation Function() createOperation,
  T Function() execute,
) {
  if (!cblIncludeTracePoints) {
    return execute();
  }

  return currentTracingDelegate.traceSyncOperation(
    createOperation(),
    execute,
  );
}

@pragma('vm:prefer-inline')
Future<T> asyncOperationTracePoint<T>(
  TracedOperation Function() createOperation,
  Future<T> Function() execute,
) {
  if (!cblIncludeTracePoints) {
    return execute();
  }

  return currentTracingDelegate.traceAsyncOperation(
    createOperation(),
    execute,
  );
}

T tracingDelegateTracedNativeCallHandler<T>(
  TracedNativeCall call,
  T Function() execute,
) {
  final info = NativeCallOp(call.symbol);
  return currentTracingDelegate.traceSyncOperation(info, execute);
}
