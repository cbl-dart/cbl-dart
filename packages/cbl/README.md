[![Version](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

Couchbase Lite is an embedded, NoSQL database:

- **Multi-Platform** - Android, iOS, macOS, Windows, Linux
- **Standalone Dart and Flutter** - No manual setup required, just add the
  package.
- **Fast and Compact** - Uses efficient persisted data structures.

It is fully featured:

- **JSON Style Documents** - No explicit schema and supports deep nesting.
- **Expressive Queries** - [SQL++] (SQL for JSON), QueryBuilder, Full-Text
  Search
- **Observable** - Get notified of changes in database, queries and data sync.
- **Data Sync** - Pull and push data from/to server with full control over
  synced data.
- **Peer-to-Peer Sync** - Sync directly between devices without a server.
  **Enterprise Edition**
- **Vector Search** - Perform similarity searches using vector embeddings.
  **Enterprise Edition**

---

❤️ If you find this package useful, please ⭐ us on [pub.dev][cbl] and
[GitHub][repository]. 🙏

🐛 & ✨ Did you find a bug or have a feature request? Please open a [GitHub
issue][issues].

👋 Do you you have a question or feedback? Let us know in a [GitHub
discussion][discussions].

## Proudly sponsored by

[![Lotum](https://raw.githubusercontent.com/cbl-dart/cbl-dart/main/packages/cbl/doc/img/lotum-logo.svg)](https://lotum.com/)

---

This is the single package for Couchbase Lite in Dart. It works for both
standalone Dart apps and Flutter apps - no additional platform packages are
needed. Native libraries are downloaded and compiled automatically via
[Dart native assets](https://dart.dev/interop/c-interop#native-assets).

For the full documentation, go to [**cbl-dart.dev**][docs].

> [!IMPORTANT]
> **Upgrading from v3?** See the [migration guide][migration-v3-to-v4] for upgrading to v4.

## Getting started

### Install

Add the package as a dependency:

```bash
dart pub add cbl
```

### Configure edition (optional)

By default, the Community edition is used. To use the Enterprise edition,
configure it in your package `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    cbl:
      edition: enterprise
```

> [!NOTE]
> If you are using a Dart pub workspace, `hooks.user_defines` are read from the
> workspace root `pubspec.yaml`, so put this configuration there instead.

### Initialize

Initialize Couchbase Lite before using it:

```dart
import 'package:cbl/cbl.dart';

Future<void> main() async {
  await CouchbaseLite.init();
  // Start using Couchbase Lite ...
}
```

If you enabled vector search in `pubspec.yaml`, call
`Extension.enableVectorSearch()` after initialization and before opening a
database that uses vector search.

### Example

```dart
import 'package:cbl/cbl.dart';

Future<void> main() async {
  await CouchbaseLite.init();

  // Open the database (creating it if it doesn't exist).
  final database = await Database.openAsync('database');

  // Create a collection, or return it if it already exists.
  final collection = await database.createCollection('components');

  // Create a new document.
  final mutableDocument = MutableDocument({'type': 'SDK', 'majorVersion': 2});
  await collection.saveDocument(mutableDocument);

  print(
    'Created document with id ${mutableDocument.id} and '
    'type ${mutableDocument.string('type')}.',
  );

  // Update the document.
  mutableDocument.setString('Dart', key: 'language');
  await collection.saveDocument(mutableDocument);

  print(
    'Updated document with id ${mutableDocument.id}, '
    'adding language ${mutableDocument.string("language")!}.',
  );

  // Read the document.
  final document = (await collection.document(mutableDocument.id))!;

  print(
    'Read document with id ${document.id}, '
    'type ${document.string('type')} and '
    'language ${document.string('language')}.',
  );

  // Create a query to fetch documents of type SDK.
  print('Querying Documents of type=SDK.');
  final query = await database.createQuery('''
    SELECT * FROM components
    WHERE type = 'SDK'
  ''');

  // Run the query.
  final result = await query.execute();
  final results = await result.allResults();
  print('Number of results: ${results.length}');

  // Close the database.
  await database.close();
}
```

## Integrations

- [**cbl_sentry**][cbl_sentry] -- Sentry integration for error reporting and
  performance tracing.

# 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# Prior work

Thanks to the authors of earlier Couchbase Lite packages. Those packages where
valuable references for making decisions about how to approach this project.

- [Luca Christille](https://github.com/lchristille) -
  [fluttercouch](https://github.com/fluttercouch/fluttercouch)
- [Bryan Welter](https://github.com/bawelter) -
  [couchbase_lite](https://github.com/SaltechSystems/couchbase_lite)
- [Rudolf Martincsek](https://github.com/Rudiksz) -
  [couchbase_lite_dart](https://github.com/Rudiksz/couchbase_lite_dart)

# ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[repository]: https://github.com/cbl-dart/cbl-dart
[contributing]: https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md
[sql++]: https://www.couchbase.com/products/n1ql
[cbl]: https://pub.dev/packages/cbl
[issues]: https://github.com/cbl-dart/cbl-dart/issues
[discussions]: https://github.com/cbl-dart/cbl-dart/discussions
[docs]: https://cbl-dart.dev/
[migration-v3-to-v4]: https://cbl-dart.dev/migration-v3-to-v4
[cbl_sentry]: https://pub.dev/packages/cbl_sentry
