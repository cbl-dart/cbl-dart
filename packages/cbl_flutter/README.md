[![Version](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter)
[![License](https://badgen.net/pub/license/cbl_flutter)](https://github.com/cofu-app/cbl-dart/blob/main/packages/cbl_flutter/LICENSE)
[![CI](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml)

# cbl_flutter

This package enables using Couchbase Lite
([`cbl`](https://pub.dev/packages/cbl)) in Flutter apps.

## Supported Platforms

| Platform | Minimum version |
| -------: | --------------- |
|      iOS | 11              |
|    macOS | 10.13           |
|  Android | 22              |

## Getting started

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
