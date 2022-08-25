import 'package:cbl/cbl.dart';
import 'package:cbl_sentry/cbl_sentry.dart';
import 'package:cbl_sentry/src/couchbase_lite_integration.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

import 'utils/cbl.dart';
import 'utils/mock_hub.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  late MockHub hub;
  late SentryOptions options;

  setUp(() {
    hub = MockHub();
    options = SentryOptions();
  });

  Future<CouchbaseLiteIntegration> callTestIntegration(
    CouchbaseLiteIntegration integration,
  ) async {
    await integration(hub, options);
    addTearDown(integration.close);
    return integration;
  }

  group('tracing delegate', () {
    test('installs SentryTracingDelegate', () async {
      final integration = CouchbaseLiteIntegration();

      expect(TracingDelegate.hasBeenInstalled, isFalse);
      expect(integration.tracingDelegate, isNull);

      await integration(hub, options);
      addTearDown(integration.close);

      expect(TracingDelegate.hasBeenInstalled, isTrue);
      expect(integration.tracingDelegate, isNotNull);
    });

    test('removes SentryTracingDelegate when closed', () async {
      final integration = CouchbaseLiteIntegration();
      await integration(hub, options);

      expect(TracingDelegate.hasBeenInstalled, isTrue);
      expect(integration.tracingDelegate, isNotNull);

      await integration.close();

      expect(TracingDelegate.hasBeenInstalled, isFalse);
      expect(integration.tracingDelegate, isNull);
    });

    test('passes sentry dsn to delegate', () async {
      options.dsn = 'a';
      final integration = await callTestIntegration(CouchbaseLiteIntegration());

      expect(integration.tracingDelegate?.sentryDsn, 'a');
    });

    test('disables tracing if not enabled for Sentry', () async {
      final integration = await callTestIntegration(CouchbaseLiteIntegration());

      expect(integration.tracingDelegate?.tracingEnabled, false);
    });

    test('enables tracing if enabled for Sentry', () async {
      options.tracesSampleRate = 1;
      final integration = await callTestIntegration(CouchbaseLiteIntegration());

      expect(integration.tracingDelegate?.tracingEnabled, true);
    });

    test('allows overriding enabling of tracing', () async {
      options.tracesSampleRate = 1;
      final integration = await callTestIntegration(CouchbaseLiteIntegration(
        tracingEnabled: false,
      ));

      expect(integration.tracingDelegate?.tracingEnabled, false);
    });

    test('defaults traceInternalOperations to false', () async {
      final integration = await callTestIntegration(CouchbaseLiteIntegration());

      expect(integration.tracingDelegate?.traceInternalOperations, false);
    });

    test('passes traceInternalOperations option to delegate', () async {
      final integration = await callTestIntegration(CouchbaseLiteIntegration(
        traceInternalOperations: true,
      ));

      expect(integration.tracingDelegate?.traceInternalOperations, true);
    });

    test('defaults operationBreadcrumbs to false', () async {
      final integration = await callTestIntegration(CouchbaseLiteIntegration());

      expect(integration.tracingDelegate?.operationBreadcrumbs, true);
    });

    test('passes operationBreadcrumbs option to delegate', () async {
      final integration = await callTestIntegration(CouchbaseLiteIntegration(
        operationBreadcrumbs: false,
      ));

      expect(integration.tracingDelegate?.operationBreadcrumbs, false);
    });
  });

  group('logging', () {
    test('defaults breadcrumb logger log level to warning', () {
      final integration = CouchbaseLiteIntegration();
      expect(integration.breadcrumbLogLevel, LogLevel.warning);
    });

    test('installs breadcrumb logger with correct log level', () async {
      await callTestIntegration(CouchbaseLiteIntegration(
        breadcrumbLogLevel: LogLevel.debug,
      ));

      final logger = Database.log.custom;
      expect(logger, isA<BreadcrumbLogger>());
      expect(logger?.level, LogLevel.debug);
    });

    test('installs no logger is breadcrumb log level is none', () async {
      await callTestIntegration(CouchbaseLiteIntegration(
        breadcrumbLogLevel: LogLevel.none,
      ));

      expect(Database.log.custom, isNull);
    });

    test('removes breadcrumb logger when closed', () async {
      final integration = await callTestIntegration(CouchbaseLiteIntegration());
      expect(Database.log.custom, isNotNull);
      await integration.close();
      expect(Database.log.custom, isNull);
    });
  });
}
