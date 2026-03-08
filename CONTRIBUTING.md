# Contributing

Please submit contributions as PRs against the `main` branch. PRs must pass all
checks to merge.

Format your commit messages as [conventional commits]. If the changes of a PR
are limited to a single package use it as the commit message's scope, e.g.
`feat(cbl): ...`.

## Dart packages

All Dart code is organized into several [packages].

<!-- | Package                         | Description                    | Pub                                                                                     | -->
| ------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------- |
| [cbl]                           | Couchbase Lite for Dart        | [![](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)                       |
| [cbl_sentry]                    | Sentry integration             | [![](https://badgen.net/pub/v/cbl_sentry)](https://pub.dev/packages/cbl_sentry)         |
| [cbl_generator]                 | Code generation                | [![](https://badgen.net/pub/v/cbl_generator)](https://pub.dev/packages/cbl_generator)   |
| [cbl_e2e_tests]                 | E2E tests                      |                                                                                         |
| [cbl_e2e_tests_flutter]         | E2E tests runner for Flutter   |                                                                                         |
| [cbl_e2e_tests_standalone_dart] | E2E tests runner for Dart      |                                                                                         |

## Native libraries

Two native libraries are required to enable Couchbase Lite for Dart, with an
optional third for vector search. They are managed automatically by the build
hook at `packages/cbl/hook/build.dart`:

| Library                | Description                                                      | How it's provided    |
| ---------------------- | ---------------------------------------------------------------- | -------------------- |
| [libcblite]            | Couchbase Lite C                                                 | Downloaded by hook   |
| [libcblitedart]        | Support library required by Dart to make use of Couchbase Lite C | Compiled from source |
| CouchbaseLiteVectorSearch | Vector search extension (Enterprise edition, 64-bit only)     | Downloaded by hook   |

The edition (community/enterprise) and optional vector search extension are
configured via `hooks.user_defines.cbl` in the workspace root `pubspec.yaml`.

# Development environment

## Requirements

- Dart SDK `^3.10.0`
- Flutter (stable)
- melos
  ```shell
  flutter pub global activate melos
  ```

### Linux

**Dependencies**:

- CMake 3.12+
- ninja-build
- GCC/Clang

### Android

**Dependencies**:

- Android SDK with NDK `27.0.12077973` and CMake `3.18.1`

### iOS + macOS

**Dependencies**:

- XCode 12+
- xcpretty (`gem install xcpretty`)
- CMake 3.12+

## Get started

1. Fork and clone the repo:
   ```shell
   git clone https://github.com/$YOUR_USERNAME$/cbl-dart.git
   ```
2. Bootstrap the Dart [packages] so they depend on the local versions of their
   siblings:
   ```shell
   melos bootstrap
   ```

Native libraries are downloaded and compiled automatically by the build hook on
first run — no manual build step is required.

## Running tests

### Unit tests

The `cbl` package has unit tests, which can be run through the normal methods,
e.g. `dart test` or the IDE.

The build hook also has its own tests at `packages/cbl/test/hook/build_test.dart`
which verify native asset builds across platforms. These tests require network
access (to download native libraries) and have a 5-minute timeout per test.

### E2E tests

A suite of E2E tests is maintained in `cbl_e2e_tests`. This package is not used
to run the tests directly.

To execute them against a standalone Dart VM you need to go through the
`cbl_e2e_tests_standalone_dart` package. The test files have been symbolically
linked from `cbl_e2e_tests/lib/src` to
`cbl_e2e_tests_standalone_dart/test/cbl_e2e_tests` to support launching them
from an IDE and easy editing. All the normal methods to run unit tests in Dart
packages work.

The story for executing tests in the context of Flutter is similar. Here the
tests have been linked into
`cbl_e2e_tests_flutter/integration_test/cbl_e2e_tests`. The difference is that
the tests are not configured as Flutter unit tests, but instead as Flutter
integration tests. Integration tests can be launched through the IDE or through
`flutter test` with a specific test file in `integration_test`. By using
`integration_test/e2e_test.dart` as the test file all tests are executed.

[flutter]: https://flutter.dev/docs/get-started/install
[conventional commits]: https://www.conventionalcommits.org/en/v1.0.0/
[packages]: https://github.com/cbl-dart/cbl-dart/tree/main/packages
[cbl]: https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl
[cbl_e2e_tests]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_e2e_tests
[cbl_e2e_tests_standalone_dart]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_e2e_tests_standalone_dart
[cbl_e2e_tests_flutter]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_e2e_tests_flutter
[cbl_sentry]: https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_sentry
[cbl_generator]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_generator
[libcblite]: https://github.com/couchbaselabs/couchbase-lite-C
[libcblitedart]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl/native/couchbase-lite-dart
