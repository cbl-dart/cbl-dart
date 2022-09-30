import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:sentry/sentry.dart';

import 'operation_debug_info.dart';
import 'zone_span.dart';

class SentryTracingDelegate extends TracingDelegate {
  SentryTracingDelegate({
    required this.sentryDsn,
    this.tracingEnabled = true,
    this.traceInternalOperations = false,
    this.operationBreadcrumbs = true,
    this.onInitialize,
    Hub? hub,
  })  : _hub = hub ?? HubAdapter(),
        _isWorkerDelegate = false;

  SentryTracingDelegate._workerDelegate(SentryTracingDelegate userDelegate)
      : sentryDsn = userDelegate.sentryDsn,
        tracingEnabled = userDelegate.tracingEnabled,
        traceInternalOperations = userDelegate.traceInternalOperations,
        operationBreadcrumbs = false,
        onInitialize = null,
        _hub = userDelegate._hub,
        _isWorkerDelegate = true;

  final String? sentryDsn;

  final bool tracingEnabled;

  final bool traceInternalOperations;

  final bool operationBreadcrumbs;

  final void Function()? onInitialize;

  final Hub _hub;

  final bool _isWorkerDelegate;

  final _operationSpans = <ISentrySpan>[];

  bool get _isInsideOperation {
    final parentSpan = cblSentrySpan;
    if (parentSpan != null) {
      return _operationSpans.contains(parentSpan);
    }

    if (_isInsideOperationWithoutSpan) {
      return true;
    }

    if (_currentSentryTraceHeader != null) {
      return true;
    }

    return false;
  }

  @override
  TracingDelegate createWorkerDelegate() =>
      SentryTracingDelegate._workerDelegate(this);

  @override
  Future<void> initialize() async {
    if (_isWorkerDelegate) {
      await Sentry.init((options) {
        options
          ..dsn = sentryDsn
          // Transactions are always started from the user delegate. In the
          // worker delegate we only sample a transaction if the user delegate
          // decided to sample it.
          ..tracesSampler = (trace) =>
              trace.transactionContext.parentSamplingDecision?.sampled ?? false
                  ? 1
                  : 0;
      });
    } else {
      onInitialize?.call();
    }
  }

  @override
  FutureOr<void> close() async {
    if (_isWorkerDelegate) {
      await Sentry.close();
    }
  }

  // === Tracing context =======================================================

  @override
  Object? captureTracingContext() {
    if (!tracingEnabled || !traceInternalOperations || !_isInsideOperation) {
      return null;
    }

    return cblSentrySpan?.toSentryTrace().value;
  }

  @override
  void restoreTracingContext(
    covariant String? context,
    void Function() restore,
  ) {
    if (context == null) {
      return restore();
    }

    final traceHeader = SentryTraceHeader.fromTraceHeader(context);
    _runWithSentryTraceHeader(traceHeader, restore);
  }

  // === Trace points ==========================================================

  @override
  T traceSyncOperation<T>(
    TracedOperation operation,
    T Function() execute,
  ) {
    _addOperationBreadcrumb(operation);

    final span = _startOperationSpan(operation);
    if (span == null) {
      return _runOperationWithoutSpan(execute);
    }

    try {
      return runWithCblSentrySpan(span, execute);
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      span
        ..throwable = error
        ..status = _spanStatusForException(error);
      rethrow;
    } finally {
      span.status ??= const SpanStatus.ok();
      _finishOperationSpan(span);
    }
  }

  @override
  Future<T> traceAsyncOperation<T>(
    TracedOperation operation,
    Future<T> Function() execute,
  ) async {
    _addOperationBreadcrumb(operation);

    final span = _startOperationSpan(operation);
    if (span == null) {
      return _runOperationWithoutSpan(execute);
    }

    try {
      return await runWithCblSentrySpan(span, execute);
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      span
        ..throwable = error
        ..status = _spanStatusForException(error);
      rethrow;
    } finally {
      span.status ??= const SpanStatus.ok();
      await _finishOperationSpan(span);
    }
  }

  // === Breadcrumbs ===========================================================

  bool _shouldAddBreadcrumbForOperation(TracedOperation operation) {
    if (!operationBreadcrumbs || _isInsideOperation) {
      return false;
    }

    if (operation is ChannelCallOp) {
      // All channel calls are traced through the ChannelCallOp trace point,
      // but not all of the CBL APIs are trace, yet. We don't want to
      // add breadcrumbs for these operations.
      return false;
    }

    return true;
  }

  void _addOperationBreadcrumb(TracedOperation operation) {
    if (!_shouldAddBreadcrumbForOperation(operation)) {
      return;
    }

    _hub.addBreadcrumb(_createBreadcrumbForOperationStart(operation));
  }

  Breadcrumb _createBreadcrumbForOperationStart(TracedOperation operation) =>
      Breadcrumb(
        type: operation is QueryOperationOp ? 'query' : 'info',
        category: operation.debugName(isInWorker: _isWorkerDelegate),
        message: operation.debugDescription,
        data: operation.debugDetails,
      );

  // === Performance tracing ===================================================

  bool _shouldStartSpanForOperation(TracedOperation operation) {
    if (!tracingEnabled) {
      return false;
    }

    final isInternalOperation = _isInsideOperation;
    if (isInternalOperation && !traceInternalOperations) {
      return false;
    }

    if (operation is ChannelCallOp && !isInternalOperation) {
      // All channel calls are traced through the ChannelCallOp trace point,
      // but not all of the CBL APIs are trace, yet. We don't want to
      // trace channel calls without the corresponding CBL API call.
      return false;
    }

    return true;
  }

  ISentrySpan? _startOperationSpan(TracedOperation operation) {
    if (!_shouldStartSpanForOperation(operation)) {
      return null;
    }

    ISentrySpan? startChildSpan() {
      final parentSpan = cblSentrySpan;
      if (parentSpan != null) {
        return parentSpan.startChild(
          operation.debugName(isInWorker: _isWorkerDelegate),
          description: operation.debugDescription,
        );
      }

      return null;
    }

    ISentrySpan? startChildTransaction() {
      final parentTraceHeader = _currentSentryTraceHeader;
      if (parentTraceHeader != null) {
        return _hub.startTransactionWithContext(
          SentryTransactionContext.fromSentryTrace(
            'CBLWorker',
            operation.debugName(isInWorker: _isWorkerDelegate),
            parentTraceHeader,
          ).copyWith(description: operation.debugDescription),
        );
      }

      return null;
    }

    final span = startChildSpan() ?? startChildTransaction();

    if (span != null) {
      span.debugDetails = operation;
      _operationSpans.add(span);
    }

    return span;
  }

  Future<void> _finishOperationSpan(ISentrySpan span) {
    _operationSpans.remove(span);
    return span.finish();
  }
}

bool get _isInsideOperationWithoutSpan =>
    Zone.current[#_operationWithoutSpan] as bool? ?? false;

T _runOperationWithoutSpan<T>(T Function() fn) =>
    runZoned(fn, zoneValues: {#_operationWithoutSpan: true});

SentryTraceHeader? get _currentSentryTraceHeader =>
    Zone.current[#_sentryTraceHeader] as SentryTraceHeader?;

T _runWithSentryTraceHeader<T>(SentryTraceHeader header, T Function() fn) =>
    runZoned(fn, zoneValues: {#_sentryTraceHeader: header});

extension _ISentrySpanExt on ISentrySpan {
  set debugDetails(TracedOperation operation) {
    final debugDetails = operation.debugDetails;
    if (debugDetails != null) {
      setAllData(debugDetails);
    }
  }

  void setAllData(Map<String, Object?> data) {
    for (final entry in data.entries) {
      setData(entry.key, entry.value);
    }
  }
}

SpanStatus? _spanStatusForException(Object exception) {
  if (exception is! CouchbaseLiteException) {
    // We don't expect any other errors than CouchbaseLiteException to be
    // thrown by the CBL API. So this is an internal error.
    return const SpanStatus.internalError();
  }

  final errorCode = exception.code;
  if (errorCode == null) {
    return null;
  }

  return _spanStatusByCblErrorCode[errorCode];
}

/// This is a mapping of CBL error codes to corresponding Sentry [SpanStatus]es.
///
/// For some CBL error codes there are no suitable [SpanStatus]es.
const _spanStatusByCblErrorCode = <Object, SpanStatus>{
  DatabaseErrorCode.assertionFailed: SpanStatus.unknown(),
  DatabaseErrorCode.unimplemented: SpanStatus.unimplemented(),
  DatabaseErrorCode.unsupportedEncryption: SpanStatus.unimplemented(),
  DatabaseErrorCode.badRevisionId: SpanStatus.invalidArgument(),
  DatabaseErrorCode.corruptRevisionData: SpanStatus.dataLoss(),
  DatabaseErrorCode.notOpen: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.notFound: SpanStatus.notFound(),
  DatabaseErrorCode.conflict: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.invalidParameter: SpanStatus.invalidArgument(),
  DatabaseErrorCode.unexpectedError: SpanStatus.unknownError(),
  DatabaseErrorCode.notWriteable: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.corruptData: SpanStatus.dataLoss(),
  DatabaseErrorCode.busy: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.notInTransaction: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.transactionNotClosed: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.unsupported: SpanStatus.unimplemented(),
  DatabaseErrorCode.notADatabaseFile: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.wrongFormat: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.invalidQuery: SpanStatus.invalidArgument(),
  DatabaseErrorCode.missingIndex: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.invalidQueryParam: SpanStatus.invalidArgument(),
  DatabaseErrorCode.databaseTooOld: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.databaseTooNew: SpanStatus.failedPrecondition(),
  DatabaseErrorCode.badDocId: SpanStatus.invalidArgument(),
  NetworkErrorCode.timeout: SpanStatus.aborted(),
  NetworkErrorCode.invalidURL: SpanStatus.invalidArgument(),
  NetworkErrorCode.tooManyRedirects: SpanStatus.outOfRange(),
  NetworkErrorCode.tlsCertExpired: SpanStatus.failedPrecondition(),
  NetworkErrorCode.unknown: SpanStatus.unknown(),
  NetworkErrorCode.tlsCertRevoked: SpanStatus.failedPrecondition(),
  NetworkErrorCode.tlsCertNameMismatch: SpanStatus.failedPrecondition(),
  HttpErrorCode.authRequired: SpanStatus.permissionDenied(),
  HttpErrorCode.forbidden: SpanStatus.permissionDenied(),
  HttpErrorCode.notFound: SpanStatus.notFound(),
  HttpErrorCode.conflict: SpanStatus.failedPrecondition(),
  HttpErrorCode.proxyAuthRequired: SpanStatus.permissionDenied(),
  HttpErrorCode.entityTooLarge: SpanStatus.outOfRange(),
  HttpErrorCode.internalServerError: SpanStatus.internalError(),
  HttpErrorCode.notImplemented: SpanStatus.unimplemented(),
  HttpErrorCode.serviceUnavailable: SpanStatus.unavailable(),
  WebSocketErrorCode.goingAway: SpanStatus.unavailable(),
  WebSocketErrorCode.messageTooBig: SpanStatus.resourceExhausted(),
};
