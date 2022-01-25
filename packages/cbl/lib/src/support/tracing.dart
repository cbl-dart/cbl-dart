import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../tracing.dart';

/// The tracing delegate for the current isolate.
TracingDelegate tracingDelegate = const _NoopTracingDelegate();

/// Sends trace data that is collected in this isolate to the main isolate.
typedef TraceDataHandler = void Function(Object? data);

/// The [TraceDataHandler] for the current isolate, if it is a secondary
/// isolate.
late final TraceDataHandler? onTraceData;

class _NoopTracingDelegate extends TracingDelegate {
  const _NoopTracingDelegate();
}

@pragma('vm:prefer-inline')
T syncOperationTracePoint<T>(
  TracedOperation operation,
  T Function() execute,
) {
  if (!cblIncludeTracePoints) {
    return execute();
  }

  return tracingDelegate.traceSyncOperation(operation, execute);
}

@pragma('vm:prefer-inline')
Future<T> asyncOperationTracePoint<T>(
  TracedOperation operation,
  Future<T> Function() execute,
) {
  if (!cblIncludeTracePoints) {
    return execute();
  }

  return tracingDelegate.traceAsyncOperation(operation, execute);
}

T tracingDelegateTracedNativeCallHandler<T>(
  TracedNativeCall call,
  T Function() execute,
) {
  final info = NativeCallOp(call.symbol);
  return tracingDelegate.traceSyncOperation(info, execute);
}
