import 'dart:async';

import 'package:sentry/sentry.dart';

/// The sentry span that is associated with the current zone.
///
/// This getter will be removed once Sentry has support for zones.
///
/// Falls back to [Sentry.getSpan] if no span is associated with the current
/// zone.
///
/// See also:
///
/// - [runWithCblSentrySpan] for running a function with a new span.
ISentrySpan? get cblSentrySpan =>
    Zone.current[#_sentrySpan] as ISentrySpan? ?? Sentry.getSpan();

/// Runs a function in a zone in which the given span is the current
/// [cblSentrySpan].
///
/// This function will be removed once Sentry has support for zones.
T runWithCblSentrySpan<T>(ISentrySpan span, T Function() fn) =>
    runZoned(fn, zoneValues: {#_sentrySpan: span});
