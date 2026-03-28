<p align="center">
  <a href="https://cbl-dart.dev">
    <img src="https://raw.githubusercontent.com/cbl-dart/cbl-dart/main/docs/static/img/logo.png" width="100" alt="Couchbase Lite for Dart and Flutter">
  </a>
</p>

<p align="center">
  <strong>Couchbase Lite for Dart and Flutter</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/cbl"><img src="https://badgen.net/pub/v/cbl" alt="Version"></a>
  <a href="https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml"><img src="https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg" alt="CI"></a>
  <a href="https://codecov.io/gh/cbl-dart/cbl-dart"><img src="https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39" alt="codecov"></a>
</p>

> [!IMPORTANT]
> **Upgrading from v3?** See the [migration guide](https://cbl-dart.dev/migration-v3-to-v4).

## Features

- **SQL++ Queries** — A SQL superset designed for JSON documents, with JOINs,
  aggregations, and parameterized queries.
- **Full-Text Search** — Built-in full-text indexing and search.
- **Vector Search** — On-device similarity search using vector embeddings.
  _Enterprise Edition_
- **Live Queries** — Reactive, auto-updating query results.
- **Data Sync** — Bi-directional sync with Couchbase Server via Sync Gateway.
- **Peer-to-Peer Sync** — Sync directly between devices without a server.
  _Enterprise Edition_
- **Encryption** — AES-256 database encryption at rest. _Enterprise Edition_
- **Multi-Platform** — Android, iOS, macOS, Windows, Linux.

## Getting Started

Add the package:

```bash
dart pub add cbl
```

Open a database and run a query:

```dart
import 'package:cbl/cbl.dart';

Future<void> main() async {
  final database = await Database.openAsync('my-database');
  final collection = await database.createCollection('tasks');

  await collection.saveDocument(
    MutableDocument({'title': 'Learn Couchbase Lite', 'done': false}),
  );

  final query = await database.createQuery(
    "SELECT * FROM tasks WHERE done = false",
  );
  final results = await (await query.execute()).allResults();
  print('Pending tasks: ${results.length}');

  await database.close();
}
```

**[Read the full documentation at cbl-dart.dev](https://cbl-dart.dev/)**

## Enterprise Edition

By default, the Community Edition is used. To use the Enterprise Edition,
configure it in your `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    cbl:
      edition: enterprise
      debug_symbols: true
```

## Related Packages

- [cbl_sentry](https://pub.dev/packages/cbl_sentry) — Sentry integration for
  breadcrumbs and performance tracing.
- [cbl_generator](https://pub.dev/packages/cbl_generator) — Code generation for
  typed document model classes.

## Contributing

Pull requests are welcome. For major changes, please open an
[issue](https://github.com/cbl-dart/cbl-dart/issues) first. Read
[CONTRIBUTING](https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md)
to get started.

## Disclaimer

This is not an official Couchbase product.
