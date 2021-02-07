# cbl_flutter

This package provides binaries required to use [`cbl`](https://github.com/cofu-app/cbl-dart)
in Flutter apps.

## Usage

`CouchbaseLite` needs to be initialized before it can be used. For Flutter apps
you provide the `init` function with the dynamic libraries returned from `flutterLibraries`:

```dart
import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';

void initApp() async {
    await CouchbaseLite.init(libraries: flutterLibraries());
}
```