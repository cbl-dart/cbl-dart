[![Version](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter)
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

This package allows you to use Couchbase Lite in a Flutter app.

To get started, go to the [**documentation**][docs].

Below is a sneak peak of what it's like to use Couchbase Lite.

```dart
import 'package:cbl/cbl.dart';

Future<void> run() async {
  // Open the database (creating it if it doesn’t exist).
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

# 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[repository]: https://github.com/cbl-dart/cbl-dart
[contributing]: https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md
[sql++]: https://www.couchbase.com/products/n1ql
[cbl]: https://pub.dev/packages/cbl
[issues]: https://github.com/cbl-dart/cbl-dart/issues
[discussions]: https://github.com/cbl-dart/cbl-dart/discussions
[docs]: https://cbl-dart.dev/
