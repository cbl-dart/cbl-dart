# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2024-01-02

### Changes

---

Packages with breaking changes:

 - [`cbl` - `v3.0.0-dev.3`](#cbl---v300-dev3)
 - [`cbl_dart` - `v3.0.0-dev.4`](#cbl_dart---v300-dev4)
 - [`cbl_flutter` - `v3.0.0-dev.3`](#cbl_flutter---v300-dev3)

Packages with other changes:

 - [`cbl_ffi` - `v0.9.0-dev.3`](#cbl_ffi---v090-dev3)
 - [`cbl_flutter_ce` - `v3.0.0-dev.3`](#cbl_flutter_ce---v300-dev3)
 - [`cbl_flutter_ee` - `v3.0.0-dev.3`](#cbl_flutter_ee---v300-dev3)
 - [`cbl_generator` - `v0.3.0-dev.3`](#cbl_generator---v030-dev3)
 - [`cbl_sentry` - `v2.0.0-dev.4`](#cbl_sentry---v200-dev4)
 - [`cbl_flutter_platform_interface` - `v3.0.0-dev.3`](#cbl_flutter_platform_interface---v300-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_sentry` - `v2.0.0-dev.4`
 - `cbl_flutter_platform_interface` - `v3.0.0-dev.3`

---

#### `cbl` - `v3.0.0-dev.3`

 - **FIX**: check in `SerializationRegistry._addCodec` ([#547](https://github.com/cbl-dart/cbl-dart/issues/547)). ([414ef9ed](https://github.com/cbl-dart/cbl-dart/commit/414ef9ed706dfbfca1da06f1a371a095a0ef373e))
 - **BREAKING** **FEAT**: remove `DartConsoleLogger` and stop initializing `Database.log.custom` with it ([#553](https://github.com/cbl-dart/cbl-dart/issues/553)). ([28350a28](https://github.com/cbl-dart/cbl-dart/commit/28350a2835ca14f8774e4e3282a7e0d2bcf7f389))

#### `cbl_dart` - `v3.0.0-dev.4`

 - **FEAT**: upgrade to CBL SDK `3.1.3`. ([74e1c35e](https://github.com/cbl-dart/cbl-dart/commit/74e1c35e9a7c30d700e289e7febbf7b324b55e7c))
 - **BREAKING** **FEAT**: remove `DartConsoleLogger` and stop initializing `Database.log.custom` with it ([#553](https://github.com/cbl-dart/cbl-dart/issues/553)). ([28350a28](https://github.com/cbl-dart/cbl-dart/commit/28350a2835ca14f8774e4e3282a7e0d2bcf7f389))

#### `cbl_flutter` - `v3.0.0-dev.3`

 - **BREAKING** **FEAT**: remove `DartConsoleLogger` and stop initializing `Database.log.custom` with it ([#553](https://github.com/cbl-dart/cbl-dart/issues/553)). ([28350a28](https://github.com/cbl-dart/cbl-dart/commit/28350a2835ca14f8774e4e3282a7e0d2bcf7f389))

#### `cbl_ffi` - `v0.9.0-dev.3`

 - **FEAT**: upgrade to CBL SDK `3.1.3`. ([74e1c35e](https://github.com/cbl-dart/cbl-dart/commit/74e1c35e9a7c30d700e289e7febbf7b324b55e7c))

#### `cbl_flutter_ce` - `v3.0.0-dev.3`

 - **FEAT**: upgrade to CBL SDK `3.1.3`. ([74e1c35e](https://github.com/cbl-dart/cbl-dart/commit/74e1c35e9a7c30d700e289e7febbf7b324b55e7c))

#### `cbl_flutter_ee` - `v3.0.0-dev.3`

 - **FEAT**: upgrade to CBL SDK `3.1.3`. ([74e1c35e](https://github.com/cbl-dart/cbl-dart/commit/74e1c35e9a7c30d700e289e7febbf7b324b55e7c))

#### `cbl_generator` - `v0.3.0-dev.3`

 - **FEAT**(cbl_generator): upgrade to analyzer `6.0.0`. ([6a7832a4](https://github.com/cbl-dart/cbl-dart/commit/6a7832a4df4d13fe422ad363b349ccc3c9c48d32))


## 2023-12-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.0.0-dev.2`](#cbl---v300-dev2)
 - [`cbl_ffi` - `v0.9.0-dev.2`](#cbl_ffi---v090-dev2)
 - [`cbl_flutter` - `v3.0.0-dev.2`](#cbl_flutter---v300-dev2)
 - [`cbl_dart` - `v3.0.0-dev.3`](#cbl_dart---v300-dev3)
 - [`cbl_generator` - `v0.3.0-dev.2`](#cbl_generator---v030-dev2)
 - [`cbl_flutter_platform_interface` - `v3.0.0-dev.2`](#cbl_flutter_platform_interface---v300-dev2)
 - [`cbl_sentry` - `v2.0.0-dev.3`](#cbl_sentry---v200-dev3)
 - [`cbl_flutter_ce` - `v3.0.0-dev.2`](#cbl_flutter_ce---v300-dev2)
 - [`cbl_flutter_ee` - `v3.0.0-dev.2`](#cbl_flutter_ee---v300-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v3.0.0-dev.2`
 - `cbl_dart` - `v3.0.0-dev.3`
 - `cbl_generator` - `v0.3.0-dev.2`
 - `cbl_flutter_platform_interface` - `v3.0.0-dev.2`
 - `cbl_sentry` - `v2.0.0-dev.3`
 - `cbl_flutter_ce` - `v3.0.0-dev.2`
 - `cbl_flutter_ee` - `v3.0.0-dev.2`

---

#### `cbl` - `v3.0.0-dev.2`

 - **FIX**: workaround Dart bug when destructuring record containing `Finalizable` ([#546](https://github.com/cbl-dart/cbl-dart/issues/546)). ([a68456e9](https://github.com/cbl-dart/cbl-dart/commit/a68456e95d970c9e9344f73b7c88815233750dfe))

#### `cbl_ffi` - `v0.9.0-dev.2`

 - **FIX**: decode error code for replicated documents ([#540](https://github.com/cbl-dart/cbl-dart/issues/540)). ([935c36ea](https://github.com/cbl-dart/cbl-dart/commit/935c36ea1b944bd34aab8148805be153a53ede0a))


## 2023-11-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_dart` - `v3.0.0-dev.2`](#cbl_dart---v300-dev2)
 - [`cbl_sentry` - `v2.0.0-dev.2`](#cbl_sentry---v200-dev2)

---

#### `cbl_dart` - `v3.0.0-dev.2`

 - **FEAT**: upgrade `http` to `^1.0.0` ([#538](https://github.com/cbl-dart/cbl-dart/issues/538)). ([711aeabc](https://github.com/cbl-dart/cbl-dart/commit/711aeabc4872e88d232cc53adf35f54dfb981ce3))

#### `cbl_sentry` - `v2.0.0-dev.2`

 - **FEAT**: upgrade `http` to `^1.0.0` ([#538](https://github.com/cbl-dart/cbl-dart/issues/538)). ([711aeabc](https://github.com/cbl-dart/cbl-dart/commit/711aeabc4872e88d232cc53adf35f54dfb981ce3))


## 2023-09-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_ffi` - `v0.9.0-dev.1`](#cbl_ffi---v090-dev1)
 - [`cbl_dart` - `v3.0.0-dev.1`](#cbl_dart---v300-dev1)
 - [`cbl` - `v3.0.0-dev.1`](#cbl---v300-dev1)
 - [`cbl_flutter` - `v3.0.0-dev.1`](#cbl_flutter---v300-dev1)
 - [`cbl_flutter_platform_interface` - `v3.0.0-dev.1`](#cbl_flutter_platform_interface---v300-dev1)
 - [`cbl_generator` - `v0.3.0-dev.1`](#cbl_generator---v030-dev1)
 - [`cbl_sentry` - `v2.0.0-dev.1`](#cbl_sentry---v200-dev1)
 - [`cbl_flutter_ce` - `v3.0.0-dev.1`](#cbl_flutter_ce---v300-dev1)
 - [`cbl_flutter_ee` - `v3.0.0-dev.1`](#cbl_flutter_ee---v300-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl` - `v3.0.0-dev.1`
 - `cbl_flutter` - `v3.0.0-dev.1`
 - `cbl_flutter_platform_interface` - `v3.0.0-dev.1`
 - `cbl_generator` - `v0.3.0-dev.1`
 - `cbl_sentry` - `v2.0.0-dev.1`
 - `cbl_flutter_ce` - `v3.0.0-dev.1`
 - `cbl_flutter_ee` - `v3.0.0-dev.1`

---

#### `cbl_ffi` - `v0.9.0-dev.1`

#### `cbl_dart` - `v3.0.0-dev.1`


## 2023-09-04

### Changes

---

Packages with breaking changes:

 - [`cbl` - `v3.0.0-dev.0`](#cbl---v300-dev0)
 - [`cbl_dart` - `v3.0.0-dev.0`](#cbl_dart---v300-dev0)
 - [`cbl_ffi` - `v0.9.0-dev.0`](#cbl_ffi---v090-dev0)
 - [`cbl_flutter` - `v3.0.0-dev.0`](#cbl_flutter---v300-dev0)
 - [`cbl_flutter_ce` - `v3.0.0-dev.0`](#cbl_flutter_ce---v300-dev0)
 - [`cbl_flutter_ee` - `v3.0.0-dev.0`](#cbl_flutter_ee---v300-dev0)
 - [`cbl_flutter_platform_interface` - `v3.0.0-dev.0`](#cbl_flutter_platform_interface---v300-dev0)
 - [`cbl_generator` - `v0.3.0-dev.0`](#cbl_generator---v030-dev0)
 - [`cbl_sentry` - `v2.0.0-dev.0`](#cbl_sentry---v200-dev0)

Packages with other changes:

 - There are no other changes in this release.

---

#### `cbl` - `v3.0.0-dev.0`

 - **FEAT**: add support for collections ([#501](https://github.com/cbl-dart/cbl-dart/issues/501)). ([3f24f234](https://github.com/cbl-dart/cbl-dart/commit/3f24f234726ea248bc4d63808c26ebb7a4e7469b))
 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_dart` - `v3.0.0-dev.0`

 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_ffi` - `v0.9.0-dev.0`

 - **FEAT**: add support for collections ([#501](https://github.com/cbl-dart/cbl-dart/issues/501)). ([3f24f234](https://github.com/cbl-dart/cbl-dart/commit/3f24f234726ea248bc4d63808c26ebb7a4e7469b))
 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_flutter` - `v3.0.0-dev.0`

 - **FEAT**: add support for collections ([#501](https://github.com/cbl-dart/cbl-dart/issues/501)). ([3f24f234](https://github.com/cbl-dart/cbl-dart/commit/3f24f234726ea248bc4d63808c26ebb7a4e7469b))
 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_flutter_ce` - `v3.0.0-dev.0`

 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_flutter_ee` - `v3.0.0-dev.0`

 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_flutter_platform_interface` - `v3.0.0-dev.0`

 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_generator` - `v0.3.0-dev.0`

 - **FEAT**: add support for collections ([#501](https://github.com/cbl-dart/cbl-dart/issues/501)). ([3f24f234](https://github.com/cbl-dart/cbl-dart/commit/3f24f234726ea248bc4d63808c26ebb7a4e7469b))
 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

#### `cbl_sentry` - `v2.0.0-dev.0`

 - **FEAT**: add support for collections ([#501](https://github.com/cbl-dart/cbl-dart/issues/501)). ([3f24f234](https://github.com/cbl-dart/cbl-dart/commit/3f24f234726ea248bc4d63808c26ebb7a4e7469b))
 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))


## 2023-09-04

### Changes

---

Packages with breaking changes:

 - [`cbl_libcblitedart_api` - `v7.0.0`](#cbl_libcblitedart_api---v700)

---

#### `cbl_libcblitedart_api` - `v7.0.0`

 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))


## 2023-08-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v2.2.2`](#cbl---v222)
 - [`cbl_flutter` - `v2.0.10`](#cbl_flutter---v2010)
 - [`cbl_flutter_platform_interface` - `v2.0.10`](#cbl_flutter_platform_interface---v2010)
 - [`cbl_dart` - `v2.2.3`](#cbl_dart---v223)
 - [`cbl_generator` - `v0.2.0+10`](#cbl_generator---v02010)
 - [`cbl_sentry` - `v1.1.4`](#cbl_sentry---v114)
 - [`cbl_flutter_ce` - `v2.2.3`](#cbl_flutter_ce---v223)
 - [`cbl_flutter_ee` - `v2.2.3`](#cbl_flutter_ee---v223)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v2.0.10`
 - `cbl_flutter_platform_interface` - `v2.0.10`
 - `cbl_dart` - `v2.2.3`
 - `cbl_generator` - `v0.2.0+10`
 - `cbl_sentry` - `v1.1.4`
 - `cbl_flutter_ce` - `v2.2.3`
 - `cbl_flutter_ee` - `v2.2.3`

---

#### `cbl` - `v2.2.2`

 - **FIX**: don't assume `CouchbaseLiteException.code` is `Enum` in `toString` ([#513](https://github.com/cbl-dart/cbl-dart/issues/513)). ([61cef968](https://github.com/cbl-dart/cbl-dart/commit/61cef968d80b23aebdf84db2ecb5c040588e3c73))
 - **FIX**: end transactions exactly once ([#514](https://github.com/cbl-dart/cbl-dart/issues/514)). ([f1f40792](https://github.com/cbl-dart/cbl-dart/commit/f1f40792f4dc59c59bd4dc7d02d81ea41263174d))


## 2023-07-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_libcblite_api` - `v3.1.1`](#cbl_libcblite_api---v311)
 - [`cbl_flutter_ce` - `v2.2.2`](#cbl_flutter_ce---v222)
 - [`cbl_dart` - `v2.2.2`](#cbl_dart---v222)
 - [`cbl_flutter_ee` - `v2.2.2`](#cbl_flutter_ee---v222)
 - [`cbl_ffi` - `v0.8.2+1`](#cbl_ffi---v0821)
 - [`cbl` - `v2.2.1`](#cbl---v221)
 - [`cbl_flutter` - `v2.0.9`](#cbl_flutter---v209)
 - [`cbl_flutter_platform_interface` - `v2.0.9`](#cbl_flutter_platform_interface---v209)
 - [`cbl_generator` - `v0.2.0+9`](#cbl_generator---v0209)
 - [`cbl_sentry` - `v1.1.3`](#cbl_sentry---v113)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_ce` - `v2.2.2`
 - `cbl_dart` - `v2.2.2`
 - `cbl_flutter_ee` - `v2.2.2`
 - `cbl_ffi` - `v0.8.2+1`
 - `cbl` - `v2.2.1`
 - `cbl_flutter` - `v2.0.9`
 - `cbl_flutter_platform_interface` - `v2.0.9`
 - `cbl_generator` - `v0.2.0+9`
 - `cbl_sentry` - `v1.1.3`

---

#### `cbl_libcblite_api` - `v3.1.1`

 - Bump "cbl_libcblite_api" to `3.1.1`.


## 2023-07-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v2.2.0`](#cbl---v220)
 - [`cbl_flutter` - `v2.0.8`](#cbl_flutter---v208)
 - [`cbl_flutter_ce` - `v2.2.1`](#cbl_flutter_ce---v221)
 - [`cbl_flutter_ee` - `v2.2.1`](#cbl_flutter_ee---v221)
 - [`cbl_flutter_platform_interface` - `v2.0.8`](#cbl_flutter_platform_interface---v208)
 - [`cbl_dart` - `v2.2.1`](#cbl_dart---v221)
 - [`cbl_sentry` - `v1.1.2`](#cbl_sentry---v112)
 - [`cbl_generator` - `v0.2.0+8`](#cbl_generator---v0208)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_platform_interface` - `v2.0.8`
 - `cbl_dart` - `v2.2.1`
 - `cbl_sentry` - `v1.1.2`
 - `cbl_generator` - `v0.2.0+8`

---

#### `cbl` - `v2.2.0`

 - **FIX**: compare against correct enum type. ([7e06af5b](https://github.com/cbl-dart/cbl-dart/commit/7e06af5b980acb44a7298300bff3d3027ab97fb0))
 - **FEAT**: add `PosixException`, `SQLiteException` and `FleeceException` ([#488](https://github.com/cbl-dart/cbl-dart/issues/488)). ([892db2ed](https://github.com/cbl-dart/cbl-dart/commit/892db2ed40b01bb7737da8f8c99f5a3e7e23f6fe))

#### `cbl_flutter` - `v2.0.8`

 - **FIX**: upgrade kotlin version used in Android plugin ([#503](https://github.com/cbl-dart/cbl-dart/issues/503)). ([aaac41e7](https://github.com/cbl-dart/cbl-dart/commit/aaac41e7d0f646bc61627bede5991deea7d585e1))

#### `cbl_flutter_ce` - `v2.2.1`

 - **FIX**: upgrade kotlin version used in Android plugin ([#503](https://github.com/cbl-dart/cbl-dart/issues/503)). ([aaac41e7](https://github.com/cbl-dart/cbl-dart/commit/aaac41e7d0f646bc61627bede5991deea7d585e1))

#### `cbl_flutter_ee` - `v2.2.1`

 - **FIX**: upgrade kotlin version used in Android plugin ([#503](https://github.com/cbl-dart/cbl-dart/issues/503)). ([aaac41e7](https://github.com/cbl-dart/cbl-dart/commit/aaac41e7d0f646bc61627bede5991deea7d585e1))


## 2023-05-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_libcblitedart_api` - `v6.0.0`](#cbl_libcblitedart_api---v600)
 - [`cbl_libcblite_api` - `v3.1.0`](#cbl_libcblite_api---v310)
 - [`cbl_dart` - `v2.2.0`](#cbl_dart---v220)
 - [`cbl_ffi` - `v0.8.2`](#cbl_ffi---v082)
 - [`cbl_flutter_ce` - `v2.2.0`](#cbl_flutter_ce---v220)
 - [`cbl_flutter_ee` - `v2.2.0`](#cbl_flutter_ee---v220)
 - [`cbl` - `v2.1.9`](#cbl---v219)
 - [`cbl_flutter` - `v2.0.7`](#cbl_flutter---v207)
 - [`cbl_flutter_platform_interface` - `v2.0.7`](#cbl_flutter_platform_interface---v207)
 - [`cbl_generator` - `v0.2.0+7`](#cbl_generator---v0207)
 - [`cbl_sentry` - `v1.1.1`](#cbl_sentry---v111)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl` - `v2.1.9`
 - `cbl_flutter` - `v2.0.7`
 - `cbl_flutter_platform_interface` - `v2.0.7`
 - `cbl_generator` - `v0.2.0+7`
 - `cbl_sentry` - `v1.1.1`

---

#### `cbl_libcblitedart_api` - `v6.0.0`

 - Bump "cbl_libcblitedart_api" to `6.0.0`.

#### `cbl_libcblite_api` - `v3.1.0`

 - Bump "cbl_libcblite_api" to `3.1.0`.

#### `cbl_dart` - `v2.2.0`

 - **FEAT**: upgrade to CBL C SDK 3.1.0 ([#478](https://github.com/cbl-dart/cbl-dart/issues/478)). ([9031f585](https://github.com/cbl-dart/cbl-dart/commit/9031f58551dbcf035b10c8e0eef5bca25290c60c))

#### `cbl_ffi` - `v0.8.2`

 - **FEAT**: upgrade to CBL C SDK 3.1.0 ([#478](https://github.com/cbl-dart/cbl-dart/issues/478)). ([9031f585](https://github.com/cbl-dart/cbl-dart/commit/9031f58551dbcf035b10c8e0eef5bca25290c60c))

#### `cbl_flutter_ce` - `v2.2.0`

 - **FEAT**: upgrade to CBL C SDK 3.1.0 ([#478](https://github.com/cbl-dart/cbl-dart/issues/478)). ([9031f585](https://github.com/cbl-dart/cbl-dart/commit/9031f58551dbcf035b10c8e0eef5bca25290c60c))

#### `cbl_flutter_ee` - `v2.2.0`

 - **FEAT**: upgrade to CBL C SDK 3.1.0 ([#478](https://github.com/cbl-dart/cbl-dart/issues/478)). ([9031f585](https://github.com/cbl-dart/cbl-dart/commit/9031f58551dbcf035b10c8e0eef5bca25290c60c))


## 2023-04-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_sentry` - `v1.1.0`](#cbl_sentry---v110)

---

#### `cbl_sentry` - `v1.1.0`

 - **FEAT**(cbl_sentry): support sentry `^7.0.0` ([#475](https://github.com/cbl-dart/cbl-dart/issues/475)). ([13969835](https://github.com/cbl-dart/cbl-dart/commit/13969835697da9ea4bac0b3510fb0d5f74e967fe))


## 2023-03-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_libcblitedart_api` - `v5.0.0`](#cbl_libcblitedart_api---v500)
 - [`cbl_flutter_ce` - `v2.1.6`](#cbl_flutter_ce---v216)
 - [`cbl_dart` - `v2.1.9`](#cbl_dart---v219)
 - [`cbl_flutter_ee` - `v2.1.6`](#cbl_flutter_ee---v216)
 - [`cbl_ffi` - `v0.8.1+3`](#cbl_ffi---v0813)
 - [`cbl` - `v2.1.8`](#cbl---v218)
 - [`cbl_flutter` - `v2.0.6`](#cbl_flutter---v206)
 - [`cbl_flutter_platform_interface` - `v2.0.6`](#cbl_flutter_platform_interface---v206)
 - [`cbl_generator` - `v0.2.0+6`](#cbl_generator---v0206)
 - [`cbl_sentry` - `v1.0.6`](#cbl_sentry---v106)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_ce` - `v2.1.6`
 - `cbl_dart` - `v2.1.9`
 - `cbl_flutter_ee` - `v2.1.6`
 - `cbl_ffi` - `v0.8.1+3`
 - `cbl` - `v2.1.8`
 - `cbl_flutter` - `v2.0.6`
 - `cbl_flutter_platform_interface` - `v2.0.6`
 - `cbl_generator` - `v0.2.0+6`
 - `cbl_sentry` - `v1.0.6`

---

#### `cbl_libcblitedart_api` - `v5.0.0`

 - Bump "cbl_libcblitedart_api" to `5.0.0`.


## 2023-03-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_libcblite_api` - `v3.0.11`](#cbl_libcblite_api---v3011)
 - [`cbl` - `v2.1.7`](#cbl---v217)
 - [`cbl_flutter` - `v2.0.5`](#cbl_flutter---v205)
 - [`cbl_flutter_ce` - `v2.1.5`](#cbl_flutter_ce---v215)
 - [`cbl_dart` - `v2.1.8`](#cbl_dart---v218)
 - [`cbl_flutter_ee` - `v2.1.5`](#cbl_flutter_ee---v215)
 - [`cbl_ffi` - `v0.8.1+2`](#cbl_ffi---v0812)
 - [`cbl_flutter_platform_interface` - `v2.0.5`](#cbl_flutter_platform_interface---v205)
 - [`cbl_generator` - `v0.2.0+5`](#cbl_generator---v0205)
 - [`cbl_sentry` - `v1.0.5`](#cbl_sentry---v105)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_ce` - `v2.1.5`
 - `cbl_dart` - `v2.1.8`
 - `cbl_flutter_ee` - `v2.1.5`
 - `cbl_ffi` - `v0.8.1+2`
 - `cbl_flutter_platform_interface` - `v2.0.5`
 - `cbl_generator` - `v0.2.0+5`
 - `cbl_sentry` - `v1.0.5`

---

#### `cbl_libcblite_api` - `v3.0.11`

 - Bump "cbl_libcblite_api" to `3.0.11`.

#### `cbl` - `v2.1.7`

 - **FIX**: prevent deadlock when starting replicator during transaction ([#470](https://github.com/cbl-dart/cbl-dart/issues/470)). ([f1427529](https://github.com/cbl-dart/cbl-dart/commit/f1427529854dbe0065083629a76f3489369dc824))

#### `cbl_flutter` - `v2.0.5`

 - **FIX**: prevent deadlock when starting replicator during transaction ([#470](https://github.com/cbl-dart/cbl-dart/issues/470)). ([f1427529](https://github.com/cbl-dart/cbl-dart/commit/f1427529854dbe0065083629a76f3489369dc824))


## 2023-02-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v2.1.6`](#cbl---v216)
 - [`cbl_dart` - `v2.1.7`](#cbl_dart---v217)
 - [`cbl_flutter` - `v2.0.4`](#cbl_flutter---v204)
 - [`cbl_flutter_platform_interface` - `v2.0.4`](#cbl_flutter_platform_interface---v204)
 - [`cbl_generator` - `v0.2.0+4`](#cbl_generator---v0204)
 - [`cbl_sentry` - `v1.0.4`](#cbl_sentry---v104)
 - [`cbl_flutter_ce` - `v2.1.4`](#cbl_flutter_ce---v214)
 - [`cbl_flutter_ee` - `v2.1.4`](#cbl_flutter_ee---v214)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v2.0.4`
 - `cbl_flutter_platform_interface` - `v2.0.4`
 - `cbl_generator` - `v0.2.0+4`
 - `cbl_sentry` - `v1.0.4`
 - `cbl_flutter_ce` - `v2.1.4`
 - `cbl_flutter_ee` - `v2.1.4`

---

#### `cbl` - `v2.1.6`

 - **FIX**: use `runWithErrorTranslation` when calling `initializeNativeLibraries`. ([05499efe](https://github.com/cbl-dart/cbl-dart/commit/05499efebc4cf25747c5021780aa4808b52d86f5))

#### `cbl_dart` - `v2.1.7`

 - **FIX**: ship correct version of `libcblitedart` with `cbl_dart`. ([f4b92ba7](https://github.com/cbl-dart/cbl-dart/commit/f4b92ba7e8d6b46c9f4f20995b17e8a9028801c4))


## 2023-02-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v2.1.5`](#cbl---v215)
 - [`cbl_ffi` - `v0.8.1+1`](#cbl_ffi---v0811)
 - [`cbl_flutter` - `v2.0.3`](#cbl_flutter---v203)
 - [`cbl_flutter_platform_interface` - `v2.0.3`](#cbl_flutter_platform_interface---v203)
 - [`cbl_dart` - `v2.1.6`](#cbl_dart---v216)
 - [`cbl_generator` - `v0.2.0+3`](#cbl_generator---v0203)
 - [`cbl_sentry` - `v1.0.3`](#cbl_sentry---v103)
 - [`cbl_flutter_ce` - `v2.1.3`](#cbl_flutter_ce---v213)
 - [`cbl_flutter_ee` - `v2.1.3`](#cbl_flutter_ee---v213)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_platform_interface` - `v2.0.3`
 - `cbl_dart` - `v2.1.6`
 - `cbl_generator` - `v0.2.0+3`
 - `cbl_sentry` - `v1.0.3`
 - `cbl_flutter_ce` - `v2.1.3`
 - `cbl_flutter_ee` - `v2.1.3`

---

#### `cbl` - `v2.1.5`

 - **FIX**: ensure compatibility with Dart 2.19 ([#457](https://github.com/cbl-dart/cbl-dart/issues/457)). ([caf9bc90](https://github.com/cbl-dart/cbl-dart/commit/caf9bc9050cef56fecc1231bbf18637dd17a4ae8))

#### `cbl_ffi` - `v0.8.1+1`

 - **FIX**: ensure compatibility with Dart 2.19 ([#457](https://github.com/cbl-dart/cbl-dart/issues/457)). ([caf9bc90](https://github.com/cbl-dart/cbl-dart/commit/caf9bc9050cef56fecc1231bbf18637dd17a4ae8))

#### `cbl_flutter` - `v2.0.3`

 - **FIX**: ensure compatibility with Dart 2.19 ([#457](https://github.com/cbl-dart/cbl-dart/issues/457)). ([caf9bc90](https://github.com/cbl-dart/cbl-dart/commit/caf9bc9050cef56fecc1231bbf18637dd17a4ae8))


## 2023-02-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_libcblitedart_api` - `v4.0.0`](#cbl_libcblitedart_api---v400)
 - [`cbl_flutter_ce` - `v2.1.3`](#cbl_flutter_ce---v213)
 - [`cbl_dart` - `v2.1.6`](#cbl_dart---v216)
 - [`cbl_ffi` - `v0.8.1+1`](#cbl_ffi---v0811)
 - [`cbl_flutter_ee` - `v2.1.3`](#cbl_flutter_ee---v213)
 - [`cbl` - `v2.1.5`](#cbl---v215)
 - [`cbl_flutter_platform_interface` - `v2.0.3`](#cbl_flutter_platform_interface---v203)
 - [`cbl_flutter` - `v2.0.3`](#cbl_flutter---v203)
 - [`cbl_sentry` - `v1.0.3`](#cbl_sentry---v103)
 - [`cbl_generator` - `v0.2.0+3`](#cbl_generator---v0203)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_ce` - `v2.1.3`
 - `cbl_dart` - `v2.1.6`
 - `cbl_ffi` - `v0.8.1+1`
 - `cbl_flutter_ee` - `v2.1.3`
 - `cbl` - `v2.1.5`
 - `cbl_flutter_platform_interface` - `v2.0.3`
 - `cbl_flutter` - `v2.0.3`
 - `cbl_sentry` - `v1.0.3`
 - `cbl_generator` - `v0.2.0+3`

---

#### `cbl_libcblitedart_api` - `v4.0.0`

 - Bump "cbl_libcblitedart_api" to `4.0.0`.

