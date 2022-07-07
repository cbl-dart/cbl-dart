[![Version](https://badgen.net/pub/v/cbl_sentry)](https://pub.dev/packages/cbl_sentry)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

This package provides a Sentry integration for Couchbase Lite with support for
recording breadcrumbs and performance tracing.

The Couchbase Lite API is provided by [`cbl`][cbl], which you always need, to
use Couchbase Lite. Which other packages you need depends on the target platform
and features you want to use:

| Package          | Required when you want to:                                            | Pub                                          | Likes                                           | Points                                           | Popularity                                           |
| ---------------- | --------------------------------------------------------------------- | -------------------------------------------- | ----------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| [cbl]            | use Couchbase Lite.                                                   | ![](https://badgen.net/pub/v/cbl)            | ![](https://badgen.net/pub/likes/cbl)           | ![](https://badgen.net/pub/points/cbl)           | ![](https://badgen.net/pub/popularity/cbl)           |
| [cbl_dart]       | use Couchbase Lite in a Dart app (e.g. CLI) or in Flutter unit tests. | ![](https://badgen.net/pub/v/cbl_dart)       | ![](https://badgen.net/pub/likes/cbl_dart)      | ![](https://badgen.net/pub/points/cbl_dart)      | ![](https://badgen.net/pub/popularity/cbl_dart)      |
| [cbl_flutter]    | use Couchbase Lite in a Flutter app.                                  | ![](https://badgen.net/pub/v/cbl_flutter)    | ![](https://badgen.net/pub/likes/cbl_flutter)   | ![](https://badgen.net/pub/points/cbl_flutter)   | ![](https://badgen.net/pub/popularity/cbl_flutter)   |
| [cbl_flutter_ce] | use the Community Edition in a Flutter app.                           | ![](https://badgen.net/pub/v/cbl_flutter_ce) |                                                 |                                                  |                                                      |
| [cbl_flutter_ee] | use the Enterprise Edition in a Flutter app.                          | ![](https://badgen.net/pub/v/cbl_flutter_ee) |                                                 |                                                  |                                                      |
| [cbl_sentry]     | integrate Couchbase Lite with Sentry in a Dart or Flutter app.        | ![](https://badgen.net/pub/v/cbl_sentry)     | ![](https://badgen.net/pub/likes/cbl_sentry)    | ![](https://badgen.net/pub/points/cbl_sentry)    | ![](https://badgen.net/pub/popularity/cbl_sentry)    |
| [cbl_generator]  | generate Dart code to access data trough a typed data model.          | ![](https://badgen.net/pub/v/cbl_generator)  | ![](https://badgen.net/pub/likes/cbl_generator) | ![](https://badgen.net/pub/points/cbl_generator) | ![](https://badgen.net/pub/popularity/cbl_generator) |

### Table of contents

- [🤩 Features](#-features)
- [⛔ Limitations](#-limitations)
- [🔌 Getting started](#-getting-started)
  - [Performance tracing](#performance-tracing)
- [💡 Where to go next](#-where-to-go-next)
- [🤝 Contributing](#-contributing)
- [⚖️ Disclaimer](#️-disclaimer)

# 🤩 Features

- Record log messages as Sentry breadcrumbs
- Record CBL Dart API usage as Sentry breadcrumbs
- Record CBL Dart operations as Sentry transaction spans

# ⛔ Limitations

Sentry currently does not support binding transaction spans to zones. This means
there can only be one global transaction span that integrations can
transparently access. To support more advanced use cases, this package provides
a mechanism to bind transaction spans to zones. This mechanism will be removed
if and when Sentry supports this natively.

# 🔌 Getting started

To get started just add the `CouchbaseLiteIntegration` when configuring Sentry:

```dart
import 'package:cbl_sentry/cbl_sentry.dart';
import 'package:sentry/sentry.dart';

void main() {
  Sentry.init(
    (options) {
      options
        ..dsn = ...
        // While testing your Sentry configuration, make sure that all traces are sampled.
        ..tracesSampleRate = 1
        // Add the CBL Dart integration.
        ..addIntegration(CouchbaseLiteIntegration());
    },
    appRunner: () async {
      runApp(MyApp());
    }
  );
}
```

To find out about configurable options, see the documentation of
`CouchbaseLiteIntegration`.

**Note**: Make sure you don't install a `TracingDelegate` when using the
`CouchbaseLiteIntegration`. The integration has to be able to install a
`TracingDelegate` itself.

## Performance tracing

This integration only records transaction spans when a transaction has been
started and a child span of the transaction is available in the environment.

To find a span, the integration uses `cblSentrySpan`. This is a getter that
returns either a span that has been bound to the current zone or as a fallback
the result of `Sentry.getSpan()`. To bind a span to a zone use
`runWithCblSentrySpan`.

The following code snippet shows functions that are useful to trace the
performance of operations in an app:

```dart
Future<T> runAppTransaction<T>(String name, Future<T> Function() fn) =>
    _runAppSpan(Sentry.startTransaction(name, 'task'), fn);

Future<T> runAppOperation<T>(String name, Future<T> Function() fn) =>
    _runAppSpan(cblSentrySpan!.startChild(name), fn);

Future<T> _runAppSpan<T>(ISentrySpan span,Future<T> Function() fn) async {
  try {
    return await runWithCblSentrySpan(span, fn);
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    span
      ..throwable = e
      ..status = const SpanStatus.internalError();
    rethrow;
  } finally {
    span.status ??= const SpanStatus.ok();
    await span.finish();
  }
}
```

A app operation like the one below is traced as a transaction span, with CBL
Dart operations as child spans:

```dart
Future<void> queryDatabase() => runAppOperation('queryDatabase', () async {
      final query = await Query.fromN1ql(
        db,
        'SELECT * FROM example WHERE age >= 28 OR name LIKE "A%"',
      );
      final resultSet = await query.execute();
      final results = await resultSet
          .asStream()
          .map((result) => result.toPlainMap())
          .toList();

      prettyPrintJson(results);
    });
```

![Sentry Trace Example](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl_sentry/doc/img/sentry-trace-example.png?raw=true)

# 💡 Where to go next

- [cbl]: Couchbase Lite Dart API
- [cbl_dart]: Couchbase Lite for Dart apps
- [cbl_flutter]: Couchbase Lite for Flutter apps
- [sentry]: Sentry for Dart apps
- [sentry_flutter]: Sentry for Flutter apps

# 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[contributing]: https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md
[n1ql]: https://www.couchbase.com/products/n1ql
[n1ql language reference]:
  https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/index.html
[couchbase lite swift docs]:
  https://docs.couchbase.com/couchbase-lite/3.0/swift/quickstart.html
[cbl]: https://pub.dev/packages/cbl
[cbl_dart]: https://pub.dev/packages/cbl_dart
[cbl_flutter]: https://pub.dev/packages/cbl_flutter
[cbl_flutter_ce]: https://pub.dev/packages/cbl_flutter_ce
[cbl_flutter_ee]: https://pub.dev/packages/cbl_flutter_ee
[cbl_sentry]: https://pub.dev/packages/cbl_sentry
[cbl_generator]: https://pub.dev/packages/cbl_generator
[issues]: https://github.com/cbl-dart/cbl-dart/issues
[sync gateway]: https://www.couchbase.com/sync-gateway
[sync gateway docs]:
  https://docs.couchbase.com/sync-gateway/3.0/introduction.html
[sentry]: https://pub.dev/packages/sentry
[sentry_flutter]: https://pub.dev/packages/sentry_flutter
