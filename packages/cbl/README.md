[![Version](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)
[![License](https://badgen.net/pub/license/cbl)](https://github.com/cofu-app/cbl-dart/blob/main/packages/cbl/LICENSE)
[![CI](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml)

# cbl

> **Warning:** This project has not yet reached a stable production release.

> **Warning:** This is not an official Couchbase product.

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

- Calls Couchbase Lite C API through FFI
- Expensive operations run in separate isolate
  - No blocking of calling isolate
- Streams for event based APIs
- Support for Flutter apps
- Support for standalone Dart (for example a CLI)
- Well documented

## Installation

This package only contains Dart code and requires binary libraries to be packaged
with any app that wants to use it. For Flutter apps, you need to add 
[`cbl_flutter`](https://pub.dev/packages/cbl_flutter) as a dependency to include 
those libraries in the build. `cbl_flutter` currently supports iOS, macOS and Android.

```pubspec
dependencies:
    cbl: ...
    cbl_flutter: ...
```

## Getting started

`CouchbaseLite` is the entry point to the API and needs to be initialized with a
configuration of how to load the binary libraries.

```dart
import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';

Future<void> initCbl() async {
    await CouchbaseLite.init(libraries: flutterLibraries());
}
```

Now you can use `CouchbaseLite.instance` to open a database:

```dart
import 'package:cbl/cbl.dart';
import 'package:path_provider/path_provider.dart';

Future<void> openDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();

    final db = await CouchbaseLite.instance.openDatabase(
        'MyFirstDB',
        config: DatabaseConfiguration(directory: documentsDir.path),
    )

    final doc = MutableDocument()..properties = {'message': 'Hello, World!'};
    final savedDoc = await db.saveDocument(doc)
}
```
