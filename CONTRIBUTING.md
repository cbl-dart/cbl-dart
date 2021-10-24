# Contributing

Please submit contributions as PRs against the `main` branch. PRs must pass all
checks to merge.

Format your commit messages as [conventional commits]. If the changes of a PR
are limited to a single package use it as the commit message's scope, e.g.
`feat(cbl): ...`.

# Development environment

## Requirements

- Flutter (stable)
- melos (1.0.0-dev.3)
  ```shell
  flutter pub global activate melos 1.0.0-dev.3
  ```

### Linux

**Dependencies**:

- CMake 3.12+
- ninja-build
- GCC/Clang

### Android

**Dependencies**:

- Android SDK with NDK `21.4.7075529` and CMake `3.18.1`

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
2. Build the generated Flutter packages:
   ```shell
   melos run build:cbl_flutter_prebuilt
   ```
3. Build the native libraries for the host target:
   ```shell
   melos run build:nativeLibraries
   ```
4. Generate files that `melos bootstrap` doesn't:
   ```shell
   melos run flutter:pubGet
   ```
5. Bootstrap the Dart [packages] so they depend on the local versions of their
   siblings:
   ```shell
   melos bootstrap
   ```

## Running tests

The `cbl` package is pure Dart and has unit tests, which can be run through the
normal methods, e.g `dart test`/`flutter test` or the IDE. These unit tests only
test components which are independent of the native libraries.

To ensure good test coverage a suite of E2E tests is maintained in
`cbl_e2e_tests`. This package is not used to run the tests, through.

To execute them against a standalone Dart VM you need to go though the
`cbl_e2e_tests_standalone_dart` package. The test files have been symbolically
linked from `cbl_e2e_test/lib/src` to
`cbl_e2e_tests_standalone_dart/test/cbl_e2e_tests` to support launching them
from an IDE and easy editing. All the normal methods to run unit tests in Dart
packages work.

The story for executing tests in the context of Flutter is similar. Here the
tests have been linked into
`cbl_e2e_tests_flutter/integration_test/cbl_e2e_tests`. The difference is that
the tests are not configured as Flutter unit tests, but instead as Flutter
integration tests. Integration tests can can be launched through the IDE or
through `flutter test` with a specific test file in `integration_test`. By using
`integration_test/e2e_test.dart` as the test file all tests are executed.

[flutter]: https://flutter.dev/docs/get-started/install
[packages]: ../packages
[conventional commits]: https://www.conventionalcommits.org/en/v1.0.0/
