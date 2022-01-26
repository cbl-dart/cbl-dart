import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../tracing.dart';
import 'isolate.dart';

/// The tracing delegate for the current isolate, that is actually being used.
///
/// This can be different from the [TracingDelegate] in [IsolateContext],
/// so it can be temporarily overridden, for testing.
TracingDelegate effectiveTracingDelegate = const NoopTracingDelegate();

/// Sends trace data that is collected in this isolate to the main isolate.
typedef TraceDataHandler = void Function(Object? data);

/// The [TraceDataHandler] for the current isolate, if it is a secondary
/// isolate.
late final TraceDataHandler? onTraceData;

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

  return effectiveTracingDelegate.traceSyncOperation(
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

  return effectiveTracingDelegate.traceAsyncOperation(
    createOperation(),
    execute,
  );
}

T tracingDelegateTracedNativeCallHandler<T>(
  TracedNativeCall call,
  T Function() execute,
) {
  final info = NativeCallOp(call.symbol);
  return effectiveTracingDelegate.traceSyncOperation(info, execute);
}
