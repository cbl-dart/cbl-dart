import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:sentry/sentry.dart';

import 'breadcrumb_logger.dart';
import 'sentry_tracing_delegate.dart';
import 'zone_span.dart';

/// A Sentry [Integration] that integrates CBL Dart with Sentry.
///
/// # Logging
///
/// CBL Dart emits log messages that can be used to record Sentry breadcrumbs.
/// Messages at [breadcrumbLogLevel] level or higher will be recorded as
/// breadcrumbs. [LogLevel.none] disables all recording of logging breadcrumbs.
/// The default is [LogLevel.warning].
///
/// This integration configures [Database.log.custom] to use a
/// [BreadcrumbLogger], which can also be used by itself.
///
/// # Operations
///
/// CBL Dart has support for tracing of operations through the [TracingDelegate]
/// API. This integration configures a [TracingDelegate] to record Sentry
/// breadcrumbs and transaction spans for [TracedOperation]s.
///
/// ## Breadcrumbs
///
/// For [TracedOperation]s that signify a direct interaction with the CBL Dart
/// API a breadcrumb is recorded at their start. This means that internal
/// operations are not recorded as breadcrumbs.
///
/// Recording of these types of breadcrumbs is enabled by default and can be
/// disabled by setting [operationBreadcrumbs] to `false`.
///
/// ## Transaction spans
///
/// Sentry transaction spans for [TracedOperation]s are recorded if a parent
/// span is available though [Sentry.getSpan] or [cblSentrySpan], when the
/// operation is executed.
///
/// Tracing of operations is by default enabled if Sentry has been configured
/// for tracing. This can be overridden by setting [tracingEnabled].
///
/// Whether or not internal operations are traced is controlled by the
/// [traceInternalOperations] option (defaults to `false`).
class CouchbaseLiteIntegration extends Integration {
  /// Creates a Sentry [Integration] that integrates CBL Dart with Sentry.
  CouchbaseLiteIntegration({
    this.tracingEnabled,
    this.traceInternalOperations = false,
    this.operationBreadcrumbs = true,
    this.breadcrumbLogLevel = LogLevel.warning,
  });

  /// Whether tracing of Couchbase Lite operations is enabled.
  ///
  /// If this property is not set, tracing is enabled if Sentry has been
  /// configured for tracing.
  final bool? tracingEnabled;

  /// Whether to trace internal operations.
  ///
  /// Activating this option can be useful to debug issues with CBL Dart itself.
  final bool traceInternalOperations;

  /// Whether to record breadcrumbs for direct interactions with the CBL Dart
  /// API.
  final bool operationBreadcrumbs;

  /// The log level at which Couchbase Lite logs are added as Sentry
  /// breadcrumbs.
  final LogLevel breadcrumbLogLevel;

  SentryTracingDelegate? _tracingDelegate;
  Logger? _breadcrumbLogger;

  @override
  FutureOr<void> call(Hub hub, SentryOptions options) {
    if (TracingDelegate.hasBeenInstalled) {
      Sentry.captureException(
        'CouchbaseLiteIntegration: Cannot install SentryTracingDelegate '
        'because another delegate has already been installed.',
        stackTrace: StackTrace.current,
      );
      return null;
    }

    final tracingDelegate = _tracingDelegate = SentryTracingDelegate(
      sentryDsn: options.dsn,
      tracingEnabled: tracingEnabled ?? options.isTracingEnabled(),
      traceInternalOperations: traceInternalOperations,
      operationBreadcrumbs: operationBreadcrumbs,
      onInitialize: () {
        if (breadcrumbLogLevel != LogLevel.none) {
          Database.log.custom =
              _breadcrumbLogger = BreadcrumbLogger(level: breadcrumbLogLevel);
        }
      },
    );
    TracingDelegate.install(tracingDelegate);

    options.sdk.addIntegration('couchbaseLiteIntegration');
  }

  @override
  FutureOr<void> close() async {
    if (_breadcrumbLogger != null) {
      if (Database.log.custom == _breadcrumbLogger) {
        Database.log.custom = null;
      }
      _breadcrumbLogger = null;
    }

    final tracingDelegate = _tracingDelegate;
    if (tracingDelegate != null) {
      await TracingDelegate.uninstall(tracingDelegate);
      _tracingDelegate = null;
    }
  }
}

extension TestingCouchbaseLiteIntegration on CouchbaseLiteIntegration {
  SentryTracingDelegate? get tracingDelegate => _tracingDelegate;
}
