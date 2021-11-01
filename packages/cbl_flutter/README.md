[![Version](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter)
[![License](https://badgen.net/pub/license/cbl_flutter)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl_flutter/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

# cbl_flutter

This is the Flutter plugin for Couchbase Lite.

It allows your Flutter app to make use of the [`cbl`][cbl] package, through
which you access Couchbase Lite.

## Supported Platforms

| Platform | Version                |
| -------: | ---------------------- |
|      iOS | >= 10.0                |
|    macOS | >= 10.14               |
|  Android | >= 22                  |
|    Linux | == Ubuntu 20.04 x86_64 |

:zap: Linux is currently broken because of a
[bug in the Flutter](https://github.com/flutter/flutter/issues/66575). Most
notably, operations trying to return an error crash the app.

## Getting started

1. You need to add [`cbl`][cbl] and `cbl_flutter` as dependencies:

```pubspec
dependencies:
    cbl: ^1.0.0-beta.7
    cbl_flutter: ^1.0.0-beta.7
```

1. Select the edition of Couchbase Lite you want to use, by adding as a
   dependency either [`cbl_flutter_ce`](https://pub.dev/packages/cbl_flutter_ce)
   for the Community Edition or
   [`cbl_flutter_ee`](https://pub.dev/packages/cbl_flutter_ee) for the
   Enterprise Edition:

```pubspec
    # This dependency selects the Couchbase Lite Community Edition.
    cbl_flutter_ce: ^1.0.0-beta.1
```

:warning: You need to comply with the Couchbase licensing terms of the edition
of Couchbase Lite you select.

3. Make sure you have set the required minimum target version in the build
   systems of the platforms you support.

4. Couchbase Lite needs to be initialized, before it can be used:

```dart
import 'dart:io';

import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:cbl_flutter_ce/cbl_flutter_ce.dart';

Future<void> initCouchbaseLite() async {
  // On mobile platforms, `CblFlutterCe` and `CblFlutterEe` currently need to
  // be registered manually. This is due to a temporary limitation in how Flutter
  // initializes plugins, and will become obsolete eventually.
  if (Platform.isIOS || Platform.isAndroid) {
    CblFlutterCe.registerWith();
  }
  await CouchbaseLiteFlutter.init();
}
```

5. Now you can start using Couchbase Lite, for example by opening a database:

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

## Default database directory

When opening a database without specifying a directory,
[`path_provider`][path_provider]'s `getApplicationSupportDirectory` is used to
resolve it. See that function's documentation for the concrete locations on the
various platforms.

[path_provider]: https://pub.dev/packages/path_provider

# Disclaimer

> **Warning:** This is not an official Couchbase product.

[cbl]: https://pub.dev/packages/cbl
