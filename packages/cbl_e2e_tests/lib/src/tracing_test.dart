import 'dart:async';

import 'package:cbl/cbl.dart';

import '../test_binding_impl.dart';
import 'test_binding.dart';
import 'utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('tracing', () {
    late TestDelegate delegate;

    setUp(() async {
      delegate = TestDelegate();
      await TracingDelegate.install(delegate);
    });

    tearDown(() async {
      await TracingDelegate.uninstall(delegate);
    });

    test(
      'hasBeenInstalled returns whether a delegate has been installed',
      () async {
        await TracingDelegate.uninstall(delegate);
        expect(TracingDelegate.hasBeenInstalled, isFalse);
        await TracingDelegate.install(delegate);
        expect(TracingDelegate.hasBeenInstalled, isTrue);
      },
    );

    test('install throws if another delegate is already installed', () async {
      expect(
        () => TracingDelegate.install(TestDelegate()),
        throwsA(isA<StateError>()),
      );
    });

    test('uninstall throws if the given delegate is not installed', () async {
      expect(
        () => TracingDelegate.uninstall(TestDelegate()),
        throwsA(isA<StateError>()),
      );
    });

    test('trace sync operation', () {
      openSyncTestDatabase();

      expect(
        delegate.syncOperations,
        [isA<OpenDatabaseOp>(), isA<NativeCallOp>()],
      );
      expect(delegate.asyncOperations, isEmpty);
    });

    test('trace async operation', () async {
      await openAsyncTestDatabase(usePublicApi: true);

      expect(delegate.syncOperations, isEmpty);
      expect(delegate.asyncOperations, [
        isA<OpenDatabaseOp>(),
        isA<ChannelCallOp>(), // Initialize worker
        isA<ChannelCallOp>(), // Install tracing delegate
        isA<ChannelCallOp>(), // Open database
      ]);
    });

    test('send and receive trace data', () async {
      delegate.workerDelegate.traceData = 'data';
      await openAsyncTestDatabase(usePublicApi: true);

      expect(delegate.traceData, ['data', 'data']);
    });

    test('worker delegate is initialized', () async {
      delegate.workerDelegate.initializeTraceData = 'init';

      await openAsyncTestDatabase(usePublicApi: true);

      expect(delegate.traceData, ['init']);
    });

    test('worker delegate is closed', () async {
      delegate.workerDelegate.closeTraceData = 'close';

      final db =
          await openAsyncTestDatabase(usePublicApi: true, tearDown: false);
      await db.close();

      expect(delegate.traceData, ['close']);
    });

    test('worker delegate can send trace data', () async {
      delegate.workerDelegate.traceData = 'data';
      await openAsyncTestDatabase(usePublicApi: true);

      expect(delegate.traceData, ['data', 'data']);
    });

    test('user delegate can provide tracing context', () async {
      delegate.tracingContext = 'context';
      await openAsyncTestDatabase(usePublicApi: true);

      expect(delegate.traceData, ['context', 'context']);
    });
  });
}

class TestDelegate extends TracingDelegate {
  TestWorkerDelegate workerDelegate = TestWorkerDelegate();

  @override
  TestWorkerDelegate createWorkerDelegate() => workerDelegate;

  final List<Object?> traceData = [];

  @override
  void onTraceData(Object? data) {
    traceData.add(data);
  }

  Object? tracingContext;

  @override
  Object? captureTracingContext() => tracingContext;

  final List<TracedOperation> syncOperations = [];
  final List<TracedOperation> asyncOperations = [];

  @override
  T traceSyncOperation<T>(TracedOperation operation, T Function() execute) {
    syncOperations.add(operation);
    return super.traceSyncOperation(operation, execute);
  }

  @override
  Future<T> traceAsyncOperation<T>(
    TracedOperation operation,
    Future<T> Function() execute,
  ) async {
    asyncOperations.add(operation);
    return super.traceAsyncOperation(operation, execute);
  }
}

class TestWorkerDelegate extends TracingDelegate {
  Object? initializeTraceData;
  Object? closeTraceData;

  Object? traceData;

  @override
  FutureOr<void> initialize() {
    if (initializeTraceData != null) {
      sendTraceData(initializeTraceData);
    }
  }

  @override
  FutureOr<void> close() {
    if (closeTraceData != null) {
      sendTraceData(closeTraceData);
    }
  }

  @override
  void restoreTracingContext(Object? context, void Function() restore) {
    if (context != null) {
      return runZoned(restore, zoneValues: {#tracingContext: context});
    }

    restore();
  }

  @override
  T traceSyncOperation<T>(TracedOperation operation, T Function() execute) {
    if (traceData != null) {
      sendTraceData(traceData);
    }
    final tracingContext = Zone.current[#tracingContext] as Object?;
    if (tracingContext != null) {
      sendTraceData(tracingContext);
    }
    return super.traceSyncOperation(operation, execute);
  }
}
