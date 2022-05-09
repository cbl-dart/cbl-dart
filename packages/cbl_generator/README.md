[![Version](https://badgen.net/pub/v/cbl_generator)](https://pub.dev/packages/cbl_generator)
[![License](https://badgen.net/pub/license/cbl_generator)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl_generator/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

Couchbase Lite is an embedded, NoSQL database:

- **Multi-Platform** - Android, iOS, macOS, Windows, Linux
- **Standalone Dart and Flutter** - No manual setup required, just add the
  package.
- **Fast and Compact** - Uses efficient persisted data structures.

It is fully featured:

- **JSON Style Documents** - No explicit schema and supports deep nesting.
- **Expressive Queries** - N1QL (SQL for JSON), QueryBuilder, Full-Text Search
- **Observable** - Get notified of changes in database, queries and data sync.
- **Data Sync** - Pull and push data from/to server with full control over
  synced data.

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

| Package          | Required when you want to:                                                                                 | Pub                                          | Likes                                           | Points                                           | Popularity                                           |
| ---------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------- | ----------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------- |
| [cbl]            | use Couchbase Lite.                                                                                        | ![](https://badgen.net/pub/v/cbl)            | ![](https://badgen.net/pub/likes/cbl)           | ![](https://badgen.net/pub/points/cbl)           | ![](https://badgen.net/pub/popularity/cbl)           |
| [cbl_dart]       | use the **Community** or **Enterprise Edition** in a **standalone Dart** app or in **Flutter unit tests**. | ![](https://badgen.net/pub/v/cbl_dart)       | ![](https://badgen.net/pub/likes/cbl_dart)      | ![](https://badgen.net/pub/points/cbl_dart)      | ![](https://badgen.net/pub/popularity/cbl_dart)      |
| [cbl_flutter]    | use Couchbase Lite in a **Flutter app**.                                                                   | ![](https://badgen.net/pub/v/cbl_flutter)    | ![](https://badgen.net/pub/likes/cbl_flutter)   | ![](https://badgen.net/pub/points/cbl_flutter)   | ![](https://badgen.net/pub/popularity/cbl_flutter)   |
| [cbl_flutter_ce] | use the **Community Edition** in a Flutter app.                                                            | ![](https://badgen.net/pub/v/cbl_flutter_ce) |                                                 |                                                  |                                                      |
| [cbl_flutter_ee] | use the **Enterprise Edition** in a Flutter app.                                                           | ![](https://badgen.net/pub/v/cbl_flutter_ee) |                                                 |                                                  |                                                      |
| [cbl_sentry]     | integrate Couchbase Lite with Sentry in a Dart or Flutter app.                                             | ![](https://badgen.net/pub/v/cbl_sentry)     | ![](https://badgen.net/pub/likes/cbl_sentry)    | ![](https://badgen.net/pub/points/cbl_sentry)    | ![](https://badgen.net/pub/popularity/cbl_sentry)    |
| [cbl_generator]  | generated Dart code to access data trough a typed data model.                                              | ![](https://badgen.net/pub/v/cbl_generator)  | ![](https://badgen.net/pub/likes/cbl_generator) | ![](https://badgen.net/pub/points/cbl_generator) | ![](https://badgen.net/pub/popularity/cbl_generator) |

# 🔌 Getting Started

1. After setting up your app for use with [`cbl`][cbl], add `cbl_generator` and
   `build_runner` as development dependencies:

   ```yaml
   dev_dependencies:
     cbl_generator: ...
     build_runner: ...
   ```

2. Annotate Dart code with [typed data annotations][typed data docs].

3. Run the build runner to invoke the generator:
   ```shell
   dart run build_runner build
   # or
   flutter run build_runner build
   ```

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
[cbl_generator]: https://pub.dev/packages/cbl_generator
[issues]: https://github.com/cbl-dart/cbl-dart/issues
[discussions]: https://github.com/cbl-dart/cbl-dart/discussions
[typed data docs]: https://pub.dev/packages/cbl#-typed-data
