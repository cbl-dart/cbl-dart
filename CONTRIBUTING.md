# Contributing

Please submit contributions as PRs against the `main` branch. PRs must pass all
checks to merge.

Format your commit messages as [conventional commits]. If the changes of a PR
are limited to a single package use it as the commit message's scope, e.g.
`feat(cbl): ...`.

# Development environment

Get started by cloning the repo, including submodules:

```shell
git clone --recurse-submodules https://github.com/cofu-app/cbl-dart.git
```

## Dart/Flutter

1. [Install Flutter] by following the instructions for you OS. Development
   happens against the **stable** channel.
2. Install `melos` (tool to manage Dart/Flutter monorepos):
   ```shell
   flutter pub global activate melos
   ```
3. Bootstrap the Dart [packages] so they depend on the local versions of their
   siblings:
   ```shell
   melos bootstrap
   ```

## Native

To build the native binaries for the different platforms you need to have a few
dependencies installed and run one of the scripts in [`native/tools`]. After the
binaries have been built, they are symbolically linked into various [packages]
so that tests and examples use them.

### Linux

**Dependencies**:

- CMake 3.9+
- ninja-build
- ccache
- GCC/Clang
- ICU libraries

```shell
sudo apt-get install cmake ninja-build ccache clang-10 icu-dev
```

Build the native binaries with build type `Debug`:

```shell
./native/tools/build_unix.sh build Debug
```

### Android

**Dependencies**:

- Android SDK with NDK `21.4.7075529` and CMake `3.18.1`
- ccache (optional)

Build the native binaries with build type `Debug`:

```shell
./native/tools/build_android.sh build Debug
```

### Apple

**Dependencies**:

- XCode 12+
- xcpretty (`gem install xcpretty`)
- ccache (`brew install ccache`)

Build the native binaries with build type `Debug` for the `macos` platform:

```shell
./native/tools/build_apple.sh build macos Debug
```

The binaries for multiple platforms can be build by specifying a space separated
list of platforms, e.g `'macos ios'`. The supported platforms are `macos`, `ios`
and `ios_simulator`.

## Running tests

The packages `cbl`, `cbl_ffi`, and `cbl_native` are pure Dart packages and have
unit tests, which can be run through the normal methods, e.g
`dart test`/`flutter test` or the IDE. These unit tests only test components
which are independent of the native binaries.

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
`cbl_flutter/example/integration_test/cbl_e2e_tests`. The difference is that the
tests are not configured as Flutter unit tests, but instead as Flutter
integration tests. Integration tests can can be launched through the IDE or
through `flutter test` with a specific test file in `integration_test`. By using
`integration_test/cbl_e2e_test.dart` as the test file all tests are executed.

[install flutter]: https://flutter.dev/docs/get-started/install
[packages]: ../packages
[`native/tools`]: ../native/tools
[conventional commits]: https://www.conventionalcommits.org/en/v1.0.0/
