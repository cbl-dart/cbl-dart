import 'package:cbl/cbl.dart';
import 'package:sentry/sentry.dart';

import 'utils.dart';

/// A [Logger] that adds a Sentry [Breadcrumb] for each log message.
///
/// This logger will add breadcrumbs of type `debug`, whose level corresponds to
/// a Couchbase Lite [LogLevel].
///
/// The [LogDomain] is used to build the category of the breadcrumb by prefixing
/// it with `cbl.`. For example, full category for a log message from the
/// [LogDomain.database] domain is `cbl.database`.
class BreadcrumbLogger extends Logger {
  /// Creates a [Logger] that adds a Sentry [Breadcrumb] for each log message.
  BreadcrumbLogger({LogLevel? level, Hub? hub})
      : _hub = hub ?? HubAdapter(),
        super(level);

  final Hub _hub;

  @override
  void log(LogLevel level, LogDomain domain, String message) {
    _hub.addBreadcrumb(Breadcrumb(
      message: message,
      type: 'debug',
      category: 'cbl.${domain.name}',
      level: level.toSentryLevel(),
    ));
  }
}

extension _LogLevelExt on LogLevel {
  SentryLevel toSentryLevel() {
    switch (this) {
      case LogLevel.debug:
      case LogLevel.verbose:
        return SentryLevel.debug;
      case LogLevel.info:
        return SentryLevel.info;
      case LogLevel.warning:
        return SentryLevel.warning;
      case LogLevel.error:
        return SentryLevel.error;
      // coverage:ignore-start
      case LogLevel.none:
        unreachable();
      // coverage:ignore-end
    }
  }
}
