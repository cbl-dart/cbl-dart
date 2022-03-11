[![Version](https://badgen.net/pub/v/cbl_dart)](https://pub.dev/packages/cbl_dart)
[![License](https://badgen.net/pub/license/cbl_dart)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl_dart/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

Couchbase Lite is an embedded, NoSQL JSON Document Style database, supporting
Blobs, Encryption, N1QL Queries, Live Queries, Full-Text Search and Data Sync.

It can be used as a standalone embedded database for mobile or desktop apps. Or
it can be combined with [Sync Gateway] to synchronize with a central data store.

---

❤️ If you find this package useful, please ⭐ us on [pub.dev][cbl] and
[GitHub][repository]. 🙏

🐛 & ✨ Did you find a bug or have a feature request? Please open a [GitHub
issue][issues].

👋 Do you you have a question or feedback? Let us know in a [GitHub
discussion][discussions].

---

**What are all these packages for?**

Couchbase Lite can be used with **standalone Dart** or with **Flutter** apps and
comes in two editions: **Community** and **Enterprise**.

Regardless of the app platform and edition of Couchbase Lite you use, you always
need the `cbl` package. All of the APIs of Couchbase Lite live in this package.

What other packages you need depends on the app platform and the edition of
Couchbase Lite you use.

| Package          | Required when you want to:                                                                                 | Pub                                          | Likes                                         | Points                                         | Popularity                                         |
| ---------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------- | --------------------------------------------- | ---------------------------------------------- | -------------------------------------------------- |
| [cbl]            | use Couchbase Lite.                                                                                        | ![](https://badgen.net/pub/v/cbl)            | ![](https://badgen.net/pub/likes/cbl)         | ![](https://badgen.net/pub/points/cbl)         | ![](https://badgen.net/pub/popularity/cbl)         |
| [cbl_dart]       | use the **Community** or **Enterprise Edition** in a **standalone Dart** app or in **Flutter unit tests**. | ![](https://badgen.net/pub/v/cbl_dart)       | ![](https://badgen.net/pub/likes/cbl_dart)    | ![](https://badgen.net/pub/points/cbl_dart)    | ![](https://badgen.net/pub/popularity/cbl_dart)    |
| [cbl_flutter]    | use Couchbase Lite in a **Flutter app**.                                                                   | ![](https://badgen.net/pub/v/cbl_flutter)    | ![](https://badgen.net/pub/likes/cbl_flutter) | ![](https://badgen.net/pub/points/cbl_flutter) | ![](https://badgen.net/pub/popularity/cbl_flutter) |
| [cbl_flutter_ce] | use the **Community Edition** in a Flutter app.                                                            | ![](https://badgen.net/pub/v/cbl_flutter_ce) |                                               |                                                |                                                    |
| [cbl_flutter_ee] | use the **Enterprise Edition** in a Flutter app.                                                           | ![](https://badgen.net/pub/v/cbl_flutter_ee) |                                               |                                                |                                                    |
| [cbl_sentry]     | integrate Couchbase Lite with Sentry in a Dart or Flutter app.                                             | ![](https://badgen.net/pub/v/cbl_sentry)     | ![](https://badgen.net/pub/likes/cbl_sentry)  | ![](https://badgen.net/pub/points/cbl_sentry)  | ![](https://badgen.net/pub/popularity/cbl_sentry)  |

# 🎯 Platform Support

| Platform | Version                |
| -------: | :--------------------- |
|    macOS | >= 10.14               |
|    Linux | == Ubuntu 20.04-x86_64 |
|  Windows | >= 10                  |

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
   already been cached. See the documentation for
   [`CouchbaseLiteDart.init`](https://pub.dev/documentation/cbl_dart/latest/cbl_dart/CouchbaseLiteDart/init.html)
   for more information.

   > ⚖️ You need to comply with the Couchbase licensing terms of the edition of
   > Couchbase Lite you select.

# Default database directory

When opening a database without specifying a directory, the current working
directory will be used. `CouchbaseLiteDart.init` allows you to specify a
different default directory.

# 💡 Where to go next

- Check out the example app in the **Example** tab.
- Look at the usage examples for [`cbl`][cbl].

# ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[repository]: https://github.com/cbl-dart/cbl-dart
[cbl]: https://pub.dev/packages/cbl
[cbl_dart]: https://pub.dev/packages/cbl_dart
[cbl_flutter]: https://pub.dev/packages/cbl_flutter
[cbl_flutter_ce]: https://pub.dev/packages/cbl_flutter_ce
[cbl_flutter_ee]: https://pub.dev/packages/cbl_flutter_ee
[cbl_sentry]: https://pub.dev/packages/cbl_sentry
[issues]: https://github.com/cbl-dart/cbl-dart/issues
[discussions]: https://github.com/cbl-dart/cbl-dart/discussions
[sync gateway]: https://www.couchbase.com/sync-gateway
