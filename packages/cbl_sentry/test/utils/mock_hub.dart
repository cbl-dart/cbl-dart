import 'package:sentry/sentry.dart';
import 'package:sentry/src/profiling.dart';

import 'mock_span.dart';

class MockHub implements Hub {
  final breadcrumbs = <Breadcrumb>[];
  final transactions = <MockSpan>[];

  @override
  SentryOptions get options => SentryOptions();

  @override
  Scope get scope => throw UnimplementedError();

  @override
  // ignore: invalid_use_of_internal_member
  SentryProfilerFactory? profilerFactory;

  @override
  Future<void> addBreadcrumb(Breadcrumb crumb, {Object? hint}) async =>
      breadcrumbs.add(crumb);

  @override
  void bindClient(SentryClient client) {}

  @override
  Future<SentryId> captureEvent(
    SentryEvent event, {
    Object? stackTrace,
    Object? hint,
    ScopeCallback? withScope,
  }) async =>
      const SentryId.empty();

  @override
  Future<SentryId> captureException(
    Object? throwable, {
    Object? stackTrace,
    Object? hint,
    ScopeCallback? withScope,
  }) async =>
      const SentryId.empty();

  @override
  Future<SentryId> captureMessage(
    String? message, {
    SentryLevel? level,
    String? template,
    List? params,
    Object? hint,
    ScopeCallback? withScope,
  }) async =>
      const SentryId.empty();

  @override
  Future<SentryId> captureTransaction(
    SentryTransaction transaction, {
    SentryTraceContextHeader? traceContext,
  }) async =>
      const SentryId.empty();

  @override
  Future<void> captureUserFeedback(SentryUserFeedback userFeedback) async {}

  @override
  Hub clone() => this;

  @override
  Future<void> close() async {}

  @override
  void configureScope(ScopeCallback callback) {}

  @override
  ISentrySpan? getSpan() => null;

  @override
  bool get isEnabled => throw UnimplementedError();

  @override
  SentryId get lastEventId => throw UnimplementedError();

  @override
  void setSpanContext(
    Object? throwable,
    ISentrySpan span,
    String transaction,
  ) {}

  @override
  ISentrySpan startTransaction(
    String name,
    String operation, {
    String? description,
    DateTime? startTimestamp,
    bool? bindToScope,
    bool? waitForChildren,
    Duration? autoFinishAfter,
    bool? trimEnd,
    OnTransactionFinish? onFinish,
    Map<String, dynamic>? customSamplingContext,
  }) =>
      startTransactionWithContext(
        SentryTransactionContext(
          name,
          operation,
          description: description,
        ),
        customSamplingContext: customSamplingContext,
        startTimestamp: startTimestamp,
        bindToScope: bindToScope,
        waitForChildren: waitForChildren,
        autoFinishAfter: autoFinishAfter,
        trimEnd: trimEnd,
      );

  @override
  ISentrySpan startTransactionWithContext(
    SentryTransactionContext transactionContext, {
    Map<String, dynamic>? customSamplingContext,
    DateTime? startTimestamp,
    bool? bindToScope,
    bool? waitForChildren,
    Duration? autoFinishAfter,
    bool? trimEnd,
    OnTransactionFinish? onFinish,
  }) {
    final span = MockSpan(
      transactionContext.operation,
      description: transactionContext.description,
      startTimestamp: startTimestamp,
      transactionParentSpanId: transactionContext.parentSpanId,
    );
    transactions.add(span);
    return span;
  }
}
