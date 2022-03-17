import 'package:sentry/sentry.dart';

class MockSpan implements ISentrySpan {
  MockSpan(
    this.operation, {
    this.description,
    DateTime? startTimestamp,
    this.transactionParentSpanId,
  }) : startTimestamp = startTimestamp ?? DateTime.now();

  final id = SpanId.newId();

  final SpanId? transactionParentSpanId;

  @override
  bool finished = false;

  final String operation;

  final String? description;

  @override
  DateTime startTimestamp;

  @override
  DateTime? endTimestamp;

  final Map<String, Object?> data = {};

  @override
  SpanStatus? status;

  @override
  Object? throwable;

  final children = <MockSpan>[];

  @override
  ISentrySpan startChild(
    String operation, {
    String? description,
    DateTime? startTimestamp,
  }) {
    final span = MockSpan(
      operation,
      description: description,
      startTimestamp: startTimestamp,
    );
    children.add(span);
    return span;
  }

  @override
  Future<void> finish({SpanStatus? status, DateTime? endTimestamp}) async {
    if (status != null) {
      this.status = status;
    }
    this.endTimestamp = endTimestamp ?? DateTime.now();
    finished = true;
  }

  @override
  void setData(String key, Object? value) {
    data[key] = value;
  }

  @override
  SentryTraceHeader toSentryTrace() =>
      SentryTraceHeader(SentryId.fromId('test'), id, sampled: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
