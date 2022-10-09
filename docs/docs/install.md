---
description: Installing Couchbase Lite for Dart
---

# Install

:::info

Couchbase Lite for Dart supports most platforms, including Android, iOS, macOS,
Windows, and Linux. To learn more about supported platforms and supported
versions, see [Supported platforms](supported-platforms.md).

:::

If you want to use Couchbase Lite in a standalone Dart app, such as a CLI or
server, jump to [Standalone Dart](#standalone-dart).

## Flutter

1. Run the following command to add the `cbl` and `cbl_flutter` packages as
   dependencies:

   ```bash
   flutter pub add cbl cbl_flutter
   ```

2. Choose between the Community and Enterprise edition.

   :::info

   The Community edition is free and open source. The Enterprise edition is free
   for development and testing, but requires a license for production use. To
   learn more about the differences between the Community and Enterprise
   editions, see [Couchbase Lite editions].

   :::

   To use the **Community edition**, run the following command to add the
   `cbl_flutter_ce` package as a dependency:

   ```bash
   flutter pub add cbl_flutter_ce
   ```

   To use the **Enterprise edition**, run the following command to add the
   `cbl_flutter_ee` package as a dependency

   ```bash
   flutter pub add cbl_flutter_ee
   ```

3. Make sure that you have set the required
   [minimum target versions](supported-platforms.md) in the build systems of the
   platforms you want to support.

4. Initialize Couchbase Lite before using it:

   ```dart
   import 'package:cbl_flutter/cbl_flutter.dart';

   Future<void> main() async {
     await CouchbaseLiteFlutter.init();
     runApp(MyApp());
   }
   ```

### Unit Tests

You can use Couchbase Lite in Flutter unit tests but you need to use `cbl_dart`
in them. In integration tests, `cbl_flutter` works just fine.

1. Add `cbl_dart` as a development dependency.

   ```bash
   flutter pub add --dev cbl_dart
   ```

2. In your unit tests initialize Couchbase Lite though `CouchbaseLiteDart.init`
   instead of `CouchbaseLiteFlutter.init`:

   ```dart
   import 'dart:io';

   import 'package:cbl/cbl.dart';
   import 'package:cbl_dart/cbl_dart.dart';
   import 'package:flutter_test/flutter_test.dart';

   void setupCouchbaseLiteForUnitTests() {
     setUpAll(() async {
       // If no `filesDir` is specified when initializing CouchbaseLiteDart, the
       // working directory is used as the default database directory.
       // By specifying a `filesDir` here, we can ensure that the tests don't
       // create databases in the project directory.
       final tempFilesDir = await Directory.systemTemp.createTemp();
       await CouchbaseLiteDart.init(edition: Edition.enterprise, filesDir: tempFilesDir.path);
     });
   }

   void main() {
     setupCouchbaseLiteForUnitTests();

     test('use a database', () async {
       final db = await Database.openAsync('test');
       // ...
     });
   }
   ```

## Standalone Dart

1. Run the following command to add the `cbl` and `cbl_dart` packages as
   dependencies:

   ```bash
   flutter pub add cbl cbl_dart
   ```

2. Initialize Couchbase Lite before using it:

   ```dart
   import 'package:cbl_dart/cbl_dart.dart';

   Future<void> main() async {
     await CouchbaseLiteDart.init(edition: Edition.enterprise);
     // Start using Couchbase Lite ...
   }
   ```

   As part of initializing Couchbase Lite you need to select an edition.

   :::info

   The Community edition is free and open source. The Enterprise edition is free
   for development and testing, but requires a license for production use. To
   learn more about the differences between the Community and Enterprise
   editions, see [Couchbase Lite editions].

   :::

   :::note

   `CouchbaseLiteDart.init` downloads the needed native libraries if they have
   not already been cached. See its [documentation][couchbaselitedart.init] for
   for more information.

   :::

## Verify Installation

To verify that Couchbase Lite is installed correctly, add the following code to
your app and call `verify` after initializing Couchbase Lite:

```dart
import 'package:cbl/cbl.dart';

Future<void> verify() async {
  // Open the database (creating it if it doesn’t exist).
  final database = await Database.openAsync('my-database');

  // Create a new document.
  final mutableDocument = MutableDocument({'type': 'SDK', 'majorVersion': 2});
  await database.saveDocument(mutableDocument);

  print(
    'Created document with id ${mutableDocument.id} and '
    'type ${mutableDocument.string('type')}.',
  );

  // Update the document.
  mutableDocument.setString('Dart', key: 'language');
  await database.saveDocument(mutableDocument);

  print(
    'Updated document with id ${mutableDocument.id}, '
    'adding language ${mutableDocument.string("language")!}.',
  );

  // Read the document.
  final document = (await database.document(mutableDocument.id))!;

  print(
    'Read document with id ${document.id}, '
    'type ${document.string('type')} and '
    'language ${document.string('language')}.',
  );

  // Create a query to fetch documents of type SDK.
  print('Querying Documents of type=SDK.');
  final query = await Query.fromN1ql(database, '''
    SELECT * FROM _
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

[couchbase lite editions]: https://www.couchbase.com/products/editions#cmobile
[couchbaselitedart.init]:
  https://pub.dev/documentation/cbl_dart/latest/cbl_dart/CouchbaseLiteDart/init.html
