[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

# cbl-dart

This is the mono-repository for the `cbl-dart` project, wich implements
Couchbase Lite for Dart and Flutter.

## Dart packages

All Dart code is organized into several [packages].

| Package                          | Description                                              | Pub                                                                                                   | Internal     |
| -------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------ |
| [cbl]                            | Dart package for Couchbase Lite                          | [![](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)                                     |              |
| [cbl_e2e_tests]                  | E2E tests                                                |                                                                                                       |              |
| [cbl_e2e_tests_flutter]          | E2E tests runner for Flutter                             |                                                                                                       |              |
| [cbl_e2e_tests_standalone_dart]  | E2E tests runner for standalone Dart                     |                                                                                                       |              |
| [cbl_ffi]                        | FFI bindings for `libcblite` and `libcblitedart`         | [![](https://badgen.net/pub/v/cbl_ffi)](https://pub.dev/packages/cbl_ffi)                             | :red_circle: |
| [cbl_libcblite_api]              | Marker package for API versions of `libcblite`           | [![](https://badgen.net/pub/v/cbl_libcblite_api)](https://pub.dev/packages/cbl_libcblite_api)         | :red_circle: |
| [cbl_libcblitedart_api]          | Marker package for API versions of `libcblitedart`       | [![](https://badgen.net/pub/v/cbl_libcblitedart_api)](https://pub.dev/packages/cbl_libcblitedart_api) | :red_circle: |
| [cbl_flutter]                    | Flutter plugin for Couchbase Lite (frontend)             | [![](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter)                     |              |
| [cbl_flutter_platform_interface] | Platform interface for [cbl_flutter]                     | [![](https://badgen.net/pub/v/cbl_flutter)](https://pub.dev/packages/cbl_flutter_platform_interface)  | :red_circle: |
| [cbl_flutter_local]              | Platform implementation of [cbl_flutter] for development |                                                                                                       |              |

## Native libraries

Two native libraries are required to enable Couchbase Lite for Dart.

| Library         | Description                                                      |
| --------------- | ---------------------------------------------------------------- |
| [libcblite]     | Couchbase Lite C                                                 |
| [libcblitedart] | Support library required by Dart to make use of Couchbase Lite C |

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

[packages]: https://github.com/cbl-dart/cbl-dart/tree/main/packages
[cbl]: https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl
[cbl_e2e_tests]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_e2e_tests
[cbl_e2e_tests_standalone_dart]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_e2e_tests_standalone_dart
[cbl_e2e_tests_flutter]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_e2e_tests_flutter
[cbl_ffi]: https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_ffi
[cbl_libcblite_api]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_libcblite_api
[cbl_libcblitedart_api]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_libcblitedart_api
[cbl_flutter]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_flutter
[cbl_flutter_platform_interface]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_flutter_platform_interface
[cbl_flutter_local]:
  https://github.com/cbl-dart/cbl-dart/tree/main/packages/cbl_flutter_local
[native]: https://github.com/cbl-dart/cbl-dart/tree/main/native
[libcblite]: https://github.com/couchbaselabs/couchbase-lite-C
[libcblitedart]: https://github.com/cbl-dart/cbl-dart/tree/main/native/cbl-dart
[contributing]: ./CONTRIBUTING.md
