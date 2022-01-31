import 'package:cbl/cbl.dart';
import 'package:cbl_sentry/cbl_sentry.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

import 'utils/mock_hub.dart';

void main() {
  test('adds breadcrumbs for each log message', () {
    final hub = MockHub();
    final logger = BreadcrumbLogger(hub: hub);

    // ignore: cascade_invocations
    logger.log(LogLevel.error, LogDomain.database, 'a');

    expect(hub.breadcrumbs.length, 1);
    final breadcrumb = hub.breadcrumbs.first;
    expect(breadcrumb.message, 'a');
    expect(breadcrumb.level, SentryLevel.error);
    expect(breadcrumb.type, 'debug');
    expect(breadcrumb.category, 'cbl.database');
  });
}
