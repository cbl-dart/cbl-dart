<p align="center">
  <a href="https://cbl-dart.dev">
    <img src="https://raw.githubusercontent.com/cbl-dart/cbl-dart/main/docs/static/img/logo.png" width="100" alt="Couchbase Lite for Dart and Flutter">
  </a>
</p>

<p align="center">
  <strong>Sentry Integration for Couchbase Lite</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/cbl_sentry"><img src="https://badgen.net/pub/v/cbl_sentry" alt="Version"></a>
  <a href="https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml"><img src="https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg" alt="CI"></a>
  <a href="https://codecov.io/gh/cbl-dart/cbl-dart"><img src="https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39" alt="codecov"></a>
</p>

Supplements Sentry error reports with database context and gathers performance
metrics for [cbl](https://pub.dev/packages/cbl) operations.

## Features

- **Breadcrumbs** — Automatically records database operations as Sentry
  breadcrumbs for richer error context.
- **Performance Tracing** — Tracks database and data sync operations as Sentry
  transactions and spans.

## Getting Started

Add the package:

```bash
dart pub add cbl_sentry
```

Add the integration to your Sentry configuration:

```dart
import 'package:cbl_sentry/cbl_sentry.dart';
import 'package:sentry/sentry.dart';

await Sentry.init(
  (options) => options
    ..dsn = 'your-sentry-dsn'
    ..tracesSampleRate = 1
    ..addIntegration(CouchbaseLiteIntegration()),
  appRunner: () async {
    // ...
  },
);
```

**[Read the full documentation at cbl-dart.dev](https://cbl-dart.dev)**

## Contributing

Pull requests are welcome. For major changes, please open an
[issue](https://github.com/cbl-dart/cbl-dart/issues) first. Read
[CONTRIBUTING](https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md)
to get started.

## Disclaimer

This is not an official Couchbase product.
