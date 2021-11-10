[![Version](https://badgen.net/pub/v/cbl_dart)](https://pub.dev/packages/cbl_dart)
[![License](https://badgen.net/pub/license/cbl_dart)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl_dart/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

Couchbase Lite for pure Dart apps, such as servers and CLIs.

The Couchbase Lite API is in the [`cbl`][cbl] package. This package is enabling
the use of `cbl` in pure Dart apps.

> This package is in beta. Use it with caution and [report any issues you
> see][issues].

# 🎯 Platform Support

| Platform | Version                | Note                   |
| -------: | :--------------------- | ---------------------- |
|    macOS | >= 10.14               |                        |
|    Linux | == Ubuntu 20.04-x86_64 |                        |
|  Windows | >= 10                  | 🚧 Not yet implemented |

# 🔌 Getting Started

1. Add [`cbl`][cbl] and `cbl_dart` as dependencies:

   ```yaml
   dependencies:
     cbl: ...
     cbl_dart: ...
   ```

1. Initialize Couchbase Lite before using it. This is also where you select the
   edition of Couchbase Lite you want to use:

   ```dart
   import 'package:cbl_dart/cbl_dart.dart';

   Future<void> initCouchbaseLite() async {
     await CouchbaseLiteDart.init(edition: Edition.community);
   }
   ```

   Note that `init` downloads the needed native libraries if they have not
   already been cached. See the documentation for `CouchbaseLiteDart.init` for
   more information.

   > ⚖️ You need to comply with the Couchbase licensing terms of the edition of
   > Couchbase Lite you select.

# Default database directory

When opening a database without specifying a directory, the current working
directory will be used. `CouchbaseLiteDart.init` allows you to specify a
different default directory.

# 💡 Where to go next

- Check out the example app in the **Example** tab.
- Look at the usage examples for [`cbl`][cbl] (go to the latest prerelease).

# ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[cbl]: https://pub.dev/packages/cbl
[issues]: https://github.com/cbl-dart/cbl-dart/issues
