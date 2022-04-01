## 0.7.2+1

 - **FIX**: follow up migration to variable sized C types (#346). ([07de6f1c](https://github.com/cbl-dart/cbl-dart/commit/07de6f1cf4d9771b76240283806d8357eadefa57))

## 0.7.2

 - **FIX**: make expected reachability of all finalized objects explicit (#341). ([d39f291f](https://github.com/cbl-dart/cbl-dart/commit/d39f291f48fc8fb22f5b8ce2b0056556e0a03e2c))
 - **FEAT**: turn asserts in `Slice` constructor into exceptions. ([0789f812](https://github.com/cbl-dart/cbl-dart/commit/0789f81279a84cd54ea11f32d2987db500fefd91))

## 0.7.1

 - **FEAT**: add `DictBindings.getWithFLString`. ([ed98b1b2](https://github.com/cbl-dart/cbl-dart/commit/ed98b1b2555265d1d1046990aff6dd69c9756d75))

## 0.7.0+1

 - **FIX**: ensure `cblReachabilityFence` works with AOT compilation (#325). ([329c427d](https://github.com/cbl-dart/cbl-dart/commit/329c427d248bab5843dc2f303ecaa6b9c9272f13))

## 0.7.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.7.0-beta.12

> Note: This release has breaking changes.

 - **REFACTOR**: remove native type conversions   (#279). ([b79a43fc](https://github.com/cbl-dart/cbl-dart/commit/b79a43fc2df737fb1a16c8903322ed85db995072))
 - **PERF**: improve `String` to `FLSring` conversion (#293). ([98f723f6](https://github.com/cbl-dart/cbl-dart/commit/98f723f6c5b03af441faa9b331541da53766595e))
 - **FEAT**: add environment constant `cblFfiUseIsLeaf` and make it `false` per default. ([e72a31ca](https://github.com/cbl-dart/cbl-dart/commit/e72a31ca72f141d1c6f2a408d7d6d072f8e08566))
 - **BREAKING** **FEAT**: upgrade to Dart `2.16.0` and Flutter `2.10.0` (#290). ([5d8d0829](https://github.com/cbl-dart/cbl-dart/commit/5d8d082967f8a13b47df788fda42bd0ef54d6def))

## 0.7.0-beta.11

> Note: This release has breaking changes.

 - **FEAT**: tracing API (#269). ([4c06a977](https://github.com/cbl-dart/cbl-dart/commit/4c06a9772b6026b9e03327e18bb0957a53d28524))
 - **FEAT**: turn on `isLeaf` for FFI functions (#263). ([29997846](https://github.com/cbl-dart/cbl-dart/commit/29997846a9e9f805c3328b4ec5de7f7a6607ec74))
 - **BREAKING** **REFACTOR**: use `Bool` from `dart:ffi` (#265). ([c5f7b7be](https://github.com/cbl-dart/cbl-dart/commit/c5f7b7bea582d60958e83651457e957ee5c8d26c))

## 0.7.0-beta.10

> Note: This release has breaking changes.

 - **CHORE**: bump dependency on `cbl_libcblitedart_api`. ([b3d38d5a](https://github.com/cbl-dart/cbl-dart/commit/b3d38d5afd1ad182ddc6d2152e420becbd626a7d))
 - **BREAKING** **FEAT**: Add `Database.saveBlob` and `Database.getBlob` (#256). ([ec5d1931](https://github.com/cbl-dart/cbl-dart/commit/ec5d1931a65e5dc569c9e5f8da26a5235afdd4f8))

## 0.7.0-beta.9

 - **REFACTOR**: improve coverage (#241). ([a5de00d9](https://github.com/cbl-dart/cbl-dart/commit/a5de00d97ff3b93baab9e373bd70a007bb11dd3e))
 - **FEAT**: improve native libraries configuration (#247). ([619ca82c](https://github.com/cbl-dart/cbl-dart/commit/619ca82cd8a239dbd90bb37dd00802d0ed53ade0))
 - **FEAT**: build `libcblitedart` for Windows (#244). ([445a4b66](https://github.com/cbl-dart/cbl-dart/commit/445a4b661d85f98155c9609cd69eb82a0f4b46c2))
 - **CHORE**: cut `1.0.0-beta.5` for `cbl_libcblitedart_api`. ([8417a3e0](https://github.com/cbl-dart/cbl-dart/commit/8417a3e01a6873d1dac8b832cefa521570799014))

## 0.7.0-beta.8

 - **FEAT**: add logging breadcrumbs to Sentry Native SDK (#234). ([5b76eac4](https://github.com/cbl-dart/cbl-dart/commit/5b76eac490c6fe19c4e60ac6dfc8e73c232e105c))
 - **CHORE**: cut `1.0.0-beta.4` for `cbl_libcblitedart_api`. ([8723fe06](https://github.com/cbl-dart/cbl-dart/commit/8723fe06b4e98ba22cf2d7d27ec3506fe5be1772))

## 0.7.0-beta.7

 - **FEAT**: add support for database encryption (#213). ([a92b9e45](https://github.com/cbl-dart/cbl-dart/commit/a92b9e4590e3424ff8d32914cc73d1ec6a1164bb))
 - **FEAT**: add `DatabaseEndpoint` for local replication (#212). ([95274353](https://github.com/cbl-dart/cbl-dart/commit/952743535a55f48592e4542faa1eea9689cd2680))
 - **CHORE**: cut release for `cbl_libcblitedart_api` `1.0.0-beta.3`. ([0779ed59](https://github.com/cbl-dart/cbl-dart/commit/0779ed59ba0f9e7fff167727e4678f91a0aca684))

## 0.7.0-beta.6

 - **REFACTOR**: remove workaround in `CBLErrorException.fromCBLErrorWithSource` for bug in CBL C (#196). ([c89bf0c9](https://github.com/cbl-dart/cbl-dart/commit/c89bf0c9e57a5165a2a53803a1b81545bf5c321d))
 - **CHORE**: cut release `cbl_libcblitedart_api` `v1.0.0-beta.2`. ([f503c8ea](https://github.com/cbl-dart/cbl-dart/commit/f503c8ead1f0735d37dae536d20a0043185875e4))
 - **CHORE**: change version format of `cbl_libcblite_api`. ([dc5c49de](https://github.com/cbl-dart/cbl-dart/commit/dc5c49def1705803daa0ce52e9f28ac38b69c510))

## 0.7.0-beta.5

 - **FEAT**: add dependencies on API packages for native libraries
 - **FEAT**: support reading `undefined` from Fleece collections

## 0.7.0-beta.4

 - **FIX**: initialize native libraries exactly once (#176).
 - **CHORE**: cut release of `cbl_native`.
 - **CHORE**: cut `cbl_native` release.

## 0.7.0-beta.3

 - **FIX**: decode error code in `ReplicatorStatusCallbackMessage.parseArguments`.
 - **FEAT**: add `toJson` methods to containers (#167).
 - **FEAT**: allocate global memory in `SliceResult`.
 - **FEAT**: make `FleeceEncoder` a `NativeObject` (#166).
 - **FEAT**: add initializer for secondary isolate.

## 0.7.0-beta.2

 - Bump "cbl_ffi" to `0.7.0-beta.2`.

## 0.7.0-beta.1

 - Bump "cbl_ffi" to `0.7.0-beta.1`.

## 0.6.0

> Note: This release has breaking changes.

 - **FEAT**: migrate to `Arena` from `ffi` package (#60).
 - **FEAT**: add APIs for Fleece data `Value`s.
 - **CHORE**: cut release.
 - **BREAKING** **REFACTOR**: convert between native and Dart types in `cbl_ffi`.
 - **BREAKING** **FEAT**: consistently use `id` instead of `ID`.
 - **BREAKING** **FEAT**: add `FLResultSlice`.

## 0.5.1

 - **FEAT**: Update dependencies.

## 0.5.0

> Note: This release has breaking changes.

 - **FIX**: use correct size for `FleeceErrorCode`.
 - **BREAKING** **FEAT**: add `DatabaseBindings.performMaintenance`.
 - **BREAKING** **FEAT**: use extensions for enum conversion.

## 0.4.0

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: replace `Void` with opaque structs.

## 0.3.0+2

 - **FIX**: fix size of result of FLValue_AsInt_C.

## 0.3.0+1

 - Update a dependency to the latest release.

## 0.3.0

> Note: This release has breaking changes.

 - **CHORE**: cut release.
 - **BREAKING** **FEAT**: rewrite native callback.

## 0.2.1

 - **FEAT**: add binding for `Document_RevisionID`.

## 0.2.0+1

 - **DOCS**: add internal package warning.

## 0.2.0

- **BREAKING** **FEAT**: simplify API

## 0.1.0

- Initial release.