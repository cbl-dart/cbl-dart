[![Version](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter)
[![License](https://badgen.net/pub/license/cbl_flutter)](https://github.com/cofu-app/cbl-dart/blob/main/packages/cbl_flutter/LICENSE)
[![CI](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml)

> ⚠️ New users should start with, and users of version `0.x.x` should migrate to
> the latest beta. The API has been heavily refactored from `0.x.x` to `1.0.0`
> and `0.x.x` wont receive any more updates.

This package provides binaries required to use
[`cbl`](https://pub.dev/packages/cbl) in Flutter apps.

## Supported Platforms

| Platform | Minimum version |
| -------: | --------------- |
|      iOS | 11              |
|    macOS | 10.13           |
|  Android | 19              |

## Usage

Make sure you have set the required minimum target version in the build systems
of the platforms you support.

Before you access any part of the library, `CouchbaseLite` needs to be
initialized before it can be used. For Flutter apps you provide the `initialize`
function with the dynamic libraries returned from `flutterLibraries`:

```dart
import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';

void initCbl() {
  CouchbaseLite.initialize(libraries: flutterLibraries());
}
```
