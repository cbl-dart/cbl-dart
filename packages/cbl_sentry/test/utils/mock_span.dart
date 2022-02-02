import 'package:sentry/sentry.dart';

class MockSpan implements ISentrySpan {
  MockSpan(this.operation, {this.description, this.transactionParentSpanId});

  final id = SpanId.newId();

  final SpanId? transactionParentSpanId;

  @override
  bool finished = false;

  final String operation;

  final String? description;

  final Map<String, Object?> data = {};

  @override
  SpanStatus? status;

  @override
  Object? throwable;

  final children = <MockSpan>[];

  @override
  ISentrySpan startChild(String operation, {String? description}) {
    final span = MockSpan(operation, description: description);
    children.add(span);
    return span;
  }

  @override
  Future<void> finish({SpanStatus? status}) async {
    if (status != null) {
      this.status = status;
    }
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
