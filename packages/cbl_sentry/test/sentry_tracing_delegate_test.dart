// ignore_for_file: cascade_invocations

import 'package:cbl/cbl.dart';
import 'package:cbl_sentry/cbl_sentry.dart';
import 'package:cbl_sentry/src/sentry_tracing_delegate.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

import 'utils/cbl.dart';
import 'utils/mock_collection.dart';
import 'utils/mock_hub.dart';
import 'utils/mock_query.dart';
import 'utils/mock_span.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  late MockHub hub;

  setUp(() {
    hub = MockHub();
  });

  group('operation breadcrumbs', () {
    test('adds breadcrumb at start of sync operations', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      delegate.traceSyncOperation(
        SaveDocumentOp(MockCollection(name: 'a'), MutableDocument.withId('b')),
        () {
          expect(hub.breadcrumbs, hasLength(1));
        },
      );

      expect(hub.breadcrumbs, hasLength(1));

      final breadcrumb = hub.breadcrumbs.first;
      expect(breadcrumb.type, 'info');
      expect(breadcrumb.category, 'cbl.saveDocument');
      expect(breadcrumb.level, SentryLevel.info);
      expect(breadcrumb.message, 'b');
      expect(breadcrumb.data, {'withConflictHandler': true});
    });

    test('adds breadcrumb at start of async operations', () async {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      await delegate.traceAsyncOperation(
        SaveDocumentOp(MockCollection(name: 'a'), MutableDocument.withId('b')),
        () async {
          expect(hub.breadcrumbs, hasLength(1));
        },
      );

      expect(hub.breadcrumbs, hasLength(1));

      final breadcrumb = hub.breadcrumbs.first;
      expect(breadcrumb.type, 'info');
      expect(breadcrumb.category, 'cbl.saveDocument');
      expect(breadcrumb.level, SentryLevel.info);
      expect(breadcrumb.message, 'b');
      expect(breadcrumb.data, {'withConflictHandler': true});
    });

    test("doesn't add sync operation breadcrumbs if disabled", () {
      final delegate = SentryTracingDelegate(
        sentryDsn: '',
        operationBreadcrumbs: false,
        hub: hub,
      );
      delegate.traceSyncOperation(
        InitializeOp(),
        () => expect(hub.breadcrumbs, isEmpty),
      );

      expect(hub.breadcrumbs, isEmpty);
    });

    test("doesn't add async operation breadcrumbs if disabled", () async {
      final delegate = SentryTracingDelegate(
        sentryDsn: '',
        operationBreadcrumbs: false,
        hub: hub,
      );
      await delegate.traceAsyncOperation(
        InitializeOp(),
        () async => expect(hub.breadcrumbs, isEmpty),
      );

      expect(hub.breadcrumbs, isEmpty);
    });

    test('adds query operations with breadcrumb type query', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      delegate.traceSyncOperation(
        PrepareQueryOp(MockQuery()),
        () {},
      );

      final breadcrumb = hub.breadcrumbs.first;
      expect(breadcrumb.type, 'query');
    });

    test('does not add breadcrumb for sync ChannelCallOp', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      delegate.traceSyncOperation(
        ChannelCallOp('a'),
        () {},
      );

      expect(hub.breadcrumbs, isEmpty);
    });

    test('does not add breadcrumb for async ChannelCallOp', () async {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      await delegate.traceAsyncOperation(
        ChannelCallOp('a'),
        () async {},
      );

      expect(hub.breadcrumbs, isEmpty);
    });

    test('does not add breadcrumb for sync internal operation', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      delegate.traceSyncOperation(
        InitializeOp(),
        () {
          delegate.traceSyncOperation(
            InitializeOp(),
            () {},
          );
        },
      );

      expect(hub.breadcrumbs, hasLength(1));
    });

    test('does not add breadcrumb for async internal operation', () async {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      await delegate.traceAsyncOperation(
        InitializeOp(),
        () async {
          await delegate.traceAsyncOperation(
            InitializeOp(),
            () async {},
          );
        },
      );

      expect(hub.breadcrumbs, hasLength(1));
    });
  });

  group('performance tracing', () {
    test('traces sync api usage', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      final root = MockSpan('root');

      runWithCblSentrySpan(root, () {
        delegate.traceSyncOperation(
          SaveDocumentOp(
            MockCollection(name: 'a'),
            MutableDocument.withId('b'),
          ),
          () {},
        );
      });

      expect(root.children, hasLength(1));
      final child = root.children.first;
      expect(child.children, isEmpty);
      expect(child.operation, 'cbl.saveDocument');
      expect(child.description, 'b');
      expect(child.data, {'withConflictHandler': true});
      expect(child.finished, isTrue);
    });

    test('traces async api usage', () async {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      final root = MockSpan('root');

      await runWithCblSentrySpan(root, () async {
        await delegate.traceAsyncOperation(
          SaveDocumentOp(
            MockCollection(name: 'a'),
            MutableDocument.withId('b'),
          ),
          () async {},
        );
      });

      expect(root.children, hasLength(1));
      final child = root.children.first;
      expect(child.children, isEmpty);
      expect(child.operation, 'cbl.saveDocument');
      expect(child.description, 'b');
      expect(child.data, {'withConflictHandler': true});
      expect(child.finished, isTrue);
    });

    test('does not trace sync operations when tracing is disabled', () {
      final delegate = SentryTracingDelegate(
        sentryDsn: '',
        tracingEnabled: false,
        hub: hub,
      );
      final root = MockSpan('root');

      runWithCblSentrySpan(root, () {
        delegate.traceSyncOperation(
          InitializeOp(),
          () {},
        );
      });

      expect(root.children, isEmpty);
    });

    test('does not trace async operations when tracing is disabled', () async {
      final delegate = SentryTracingDelegate(
        sentryDsn: '',
        tracingEnabled: false,
        hub: hub,
      );
      final root = MockSpan('root');

      await runWithCblSentrySpan(root, () async {
        await delegate.traceAsyncOperation(
          InitializeOp(),
          () async {},
        );
      });

      expect(root.children, isEmpty);
    });

    test('does not trace sync internal operations', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      final root = MockSpan('root');

      runWithCblSentrySpan(root, () {
        delegate.traceSyncOperation(
          InitializeOp(),
          () {
            delegate.traceSyncOperation(
              InitializeOp(),
              () {},
            );
          },
        );
      });

      expect(root.children, hasLength(1));
      final child = root.children.first;
      expect(child.children, isEmpty);
      expect(child.operation, 'cbl.initialize');
    });

    test('does not trace async internal operations', () async {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      final root = MockSpan('root');

      await runWithCblSentrySpan(root, () async {
        await delegate.traceAsyncOperation(
          InitializeOp(),
          () async {
            await delegate.traceAsyncOperation(
              InitializeOp(),
              () async {},
            );
          },
        );
      });

      expect(root.children, hasLength(1));
      final child = root.children.first;
      expect(child.children, isEmpty);
      expect(child.operation, 'cbl.initialize');
    });

    test('sets throwable and status of throwing sync operation', () {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      final root = MockSpan('root');
      final exception = DatabaseException('', DatabaseErrorCode.badDocId);

      expect(
        () => runWithCblSentrySpan(root, () {
          delegate.traceSyncOperation(
            InitializeOp(),
            () {
              throw exception;
            },
          );
        }),
        throwsException,
      );

      expect(root.children, hasLength(1));
      final child = root.children.first;
      expect(child.throwable, exception);
      expect(child.status, const SpanStatus.invalidArgument());
    });

    test('sets throwable and status of throwing async operation', () async {
      final delegate = SentryTracingDelegate(sentryDsn: '', hub: hub);
      final root = MockSpan('root');
      final exception = DatabaseException('', DatabaseErrorCode.badDocId);

      await expectLater(
        () => runWithCblSentrySpan(root, () async {
          await delegate.traceAsyncOperation(
            InitializeOp(),
            () async {
              throw exception;
            },
          );
        }),
        throwsException,
      );

      expect(root.children, hasLength(1));
      final child = root.children.first;
      expect(child.throwable, exception);
      expect(child.status, const SpanStatus.invalidArgument());
    });

    group('with traceInternalOperations', () {
      test('traces sync internal operations', () {
        final delegate = SentryTracingDelegate(
          sentryDsn: '',
          traceInternalOperations: true,
          hub: hub,
        );
        final root = MockSpan('root');

        runWithCblSentrySpan(root, () {
          delegate.traceSyncOperation(
            InitializeOp(),
            () {
              delegate.traceSyncOperation(
                InitializeOp(),
                () {},
              );
            },
          );
        });

        expect(root.children, hasLength(1));
        final child = root.children.first;
        expect(child.children, hasLength(1));
        expect(child.operation, 'cbl.initialize');
        final internalChild = child.children.first;
        expect(internalChild.children, isEmpty);
        expect(internalChild.operation, 'cbl.initialize');
      });

      test('traces async internal operations', () async {
        final delegate = SentryTracingDelegate(
          sentryDsn: '',
          traceInternalOperations: true,
          hub: hub,
        );
        final root = MockSpan('root');

        await runWithCblSentrySpan(root, () async {
          await delegate.traceAsyncOperation(
            InitializeOp(),
            () async {
              await delegate.traceAsyncOperation(
                InitializeOp(),
                () async {},
              );
            },
          );
        });

        expect(root.children, hasLength(1));
        final child = root.children.first;
        expect(child.children, hasLength(1));
        expect(child.operation, 'cbl.initialize');
        final internalChild = child.children.first;
        expect(internalChild.children, isEmpty);
        expect(internalChild.operation, 'cbl.initialize');
      });

      test('traces operations in worker', () {
        final delegate = SentryTracingDelegate(
          sentryDsn: '',
          traceInternalOperations: true,
          hub: hub,
        );
        final workerDelegate = delegate.createWorkerDelegate();
        final root = MockSpan('root');

        late final Object? tracingContext;

        runWithCblSentrySpan(root, () {
          delegate.traceSyncOperation(InitializeOp(), () {
            tracingContext = delegate.captureTracingContext();
          });
        });

        workerDelegate.restoreTracingContext(
          tracingContext,
          () {
            workerDelegate.traceSyncOperation(
              InitializeOp(),
              () {},
            );
          },
        );

        expect(hub.transactions, hasLength(1));
        final transaction = hub.transactions.first;
        expect(transaction.children, isEmpty);
        expect(transaction.operation, 'cbl.initialize.worker');
        expect(transaction.transactionParentSpanId, root.children.first.id);
      });
    });
  });
}
