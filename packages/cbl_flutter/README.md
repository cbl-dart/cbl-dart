[![Version](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter)
[![License](https://badgen.net/pub/license/cbl_flutter)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl_flutter/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

This is the Flutter plugin for Couchbase Lite.

The Couchbase Lite API is in the [`cbl`][cbl] package. This package is enabling
the use of `cbl` in Flutter apps.

> This package is in beta. Use it with caution and [report any issues you
> see][issues].

## 🎯 Platform Support

| Platform | Version         | Note                                                                                                                                                                     |
| -------: | :-------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|      iOS | >= 10.0         |                                                                                                                                                                          |
|    macOS | >= 10.14        |                                                                                                                                                                          |
|  Android | >= 22           |                                                                                                                                                                          |
|    Linux | == 20.04-x86_64 | 🐛 Currently broken because of a [bug in Flutter](https://github.com/flutter/flutter/issues/66575).<br>Most notably, operations trying to return an error crash the app. |
|  Windows | >= 10           | 🚧 Not yet implemented                                                                                                                                                   |

## 🔌 Getting started

1. Add [`cbl`][cbl] and `cbl_flutter` as dependencies:

```yaml
dependencies:
  cbl: ^1.0.0-beta.7
  cbl_flutter: ^1.0.0-beta.7
```

2. Select the edition of Couchbase Lite you want to use, by adding as a
   dependency either [`cbl_flutter_ce`](https://pub.dev/packages/cbl_flutter_ce)
   for the Community Edition or
   [`cbl_flutter_ee`](https://pub.dev/packages/cbl_flutter_ee) for the
   Enterprise Edition:

```yaml
# This dependency selects the Couchbase Lite Community Edition.
cbl_flutter_ce: ^1.0.0-beta.1
```

> ⚖️ You need to comply with the Couchbase licensing terms of the edition of
> Couchbase Lite you select.

3. Make sure you have set the required minimum target version in the build
   systems of the platforms you support.

4. Initialize Couchbase Lite, before using it:

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

## Default database directory

When opening a database without specifying a directory,
[`path_provider`][path_provider]'s `getApplicationSupportDirectory` is used to
resolve it. See that function's documentation for the concrete locations on the
various platforms.

## 💡 Where to go next

- Check out the example app in the **Example** tab.
- Look at the usage examples for [`cbl`][cbl] (go to the latest prerelease).

## ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[path_provider]: https://pub.dev/packages/path_provider
[cbl]: https://pub.dev/packages/cbl
[issues]: https://github.com/cbl-dart/cbl-dart/issues
