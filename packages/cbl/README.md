[![Version](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)
[![License](https://badgen.net/pub/license/cbl)](https://github.com/cofu-app/cbl-dart/blob/main/packages/cbl/LICENSE)
[![CI](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml)

> :warning: This project has not yet reached a stable production release.

## Features - Couchbase Lite

- Schemaless JSON documents
- Binary JSON format (Fleece)
  - Reading without parsing
- Blobs
  - A binary data value associated with a document
- Queries
  - Supports large subset of N1QL query language
  - Machine readable representation of queries as JSON
  - Full text search
  - Indexes
  - Observable queries
- Replication
  - Synchronize with Couchbase Server through Sync Gateway

## Features - Dart API

- Async and sync APIs
- Streams for event based APIs
- Support for Flutter apps
- Support for standalone Dart (for example a CLI)
- Well documented

## Supported Platforms

| Platform | Version                |
| -------: | ---------------------- |
|      iOS | >= 11                  |
|    macOS | >= 10.15               |
|  Android | >= 22                  |
|    Linux | == Ubuntu 20.04 x86_64 |

## Getting started on Flutter

You need to add `cbl` and [`cbl_flutter`](https://pub.dev/packages/cbl_flutter)
as dependencies. `cbl_flutter` currently supports iOS, macOS and Android.

```pubspec
dependencies:
    cbl: ...
    cbl_flutter: ...
```

Make sure you have set the required minimum target version in the build systems
of the platforms you support.

Couchbase Lite needs to be initialized, before it can be used:

```dart
import 'package:cbl_flutter/cbl_flutter.dart';

Future<void> initCouchbaseLite() async {
  await CouchbaseLiteFlutter.init();
}
```

Now you can use `Database.open` to open a database:

```dart
import 'package:cbl/cbl.dart';

Future<void> useCouchbaseLite() async {
  final db = await Database.openAsync('chat-messages');

  final doc = MutableDocument({
    'type': 'message',
    'body': 'Heyo',
    'from': 'Alice',
  });

  await db.saveDocument(doc);

  await db.close();
}
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# Disclaimer

> **Warning:** This is not an official Couchbase product.

[contributing]: https://github.com/cofu-app/cbl-dart/blob/main/CONTRIBUTING.md
