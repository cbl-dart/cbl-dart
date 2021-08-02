[![Version](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)
[![License](https://badgen.net/pub/license/cbl)](https://github.com/cofu-app/cbl-dart/blob/main/packages/cbl/LICENSE)
[![CI](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml)

:warning: This is a beta prerelease of `v1.0.0`.

## Features - Couchbase Lite

- Schemaless JSON documents
- Blobs
  - A binary data value associated with a document
- Queries
  - Supports large subset of N1QL query language
  - `QueryBuilder` to build queries trough a typed API
  - Full text search
  - Indexes
  - Observable queries
- Replication
  - Synchronize with Couchbase Server through Sync Gateway

## Features - Dart API

- Synchronous and asynchronous API ([WIP][async-api])
- Streams for event based APIs
- Support for Flutter apps
- Support for standalone Dart (for example a CLI)
- Well documented

## Supported Platforms

| Platform | Minimum version |
| -------: | --------------- |
|      iOS | 11              |
|    macOS | 10.13           |
|  Android | 22              |

## Installation

This package only contains Dart code and requires binary libraries to be
packaged with any app that wants to use it. For Flutter apps, you need to add
[`cbl_flutter`](https://pub.dev/packages/cbl_flutter) as a dependency to include
those libraries in the build. `cbl_flutter` currently supports iOS, macOS and
Android.

```pubspec
dependencies:
    cbl: ...
    cbl_flutter: ...
```

## Getting started

Make sure you have set the required minimum target version in the build systems
of the platforms you support.

Before you access any part of the library, `CouchbaseLite` needs to be
initialized with a configuration of how to load the binary libraries.

```dart
import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';

void initCbl() {
  CouchbaseLite.init(libraries: flutterLibraries());
}
```

Now you can use `Database()` to open a database:

```dart
import 'package:cbl/cbl.dart';
import 'package:path_provider/path_provider.dart';

Future<void> useDatabase() async {
  final documentsDir = await getApplicationDocumentsDirectory();

  final db = Database(
      'my-first-db',
      DatabaseConfiguration(directory: documentsDir.path),
  );

  final doc = MutableDocument({
    'type': 'message',
    'body': 'Heyo',
    'from': 'Alice',
  });

  db.saveDocument(doc);

  await db.close();
}
```

## Sync vs Async API

:construction: The async API is not yet available and work is tracked in
[#109][async-api].

This package provides a synchronous and an asynchronous API.

The sync API is simpler to use and has less overhead than the async API. The
async API requires two [isolates][isolate] to communicate with each other and
async APIs have a slight overhead in general.

A caveat of the sync API is that it is blocking the calling isolate. UI apps,
such as Flutter apps, must not block the main UI thread to avoid jank or
unresponsiveness. To offload work from one isolate, other isolates can be
spawned, which execute concurrently. This is what the async API does. Each time
a database is opened, it creates a worker isolate, where all of the work of that
database is performed. The async API is convenient, because it transparently
handles all the communication between the two isolates.

When optimizing tasks that make many calls to the API, it might be advantageous
to avoid the overhead of the async API and handle offloading the work onto
another isolate manually.

The sync API is exported from `package:cbl/cbl.dart` and the async API from
`package:cbl/async.dart`.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# Disclaimer

:warning: This is not an official Couchbase product.

[async-api]: https://github.com/cofu-app/cbl-dart/issues/109
[isolate]: https://api.dart.dev/stable/2.12.4/dart-isolate/Isolate-class.html
[contributing]: https://github.com/cofu-app/cbl-dart/blob/main/CONTRIBUTING.md
