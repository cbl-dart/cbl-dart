# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2025-03-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.4.1`](#cbl---v341)
 - [`cbl_flutter_ce` - `v3.3.2`](#cbl_flutter_ce---v332)
 - [`cbl_flutter_ee` - `v3.3.2`](#cbl_flutter_ee---v332)
 - [`cbl_flutter` - `v3.3.1`](#cbl_flutter---v331)
 - [`cbl_flutter_install` - `v0.1.0+2`](#cbl_flutter_install---v0102)
 - [`cbl_dart` - `v3.3.1`](#cbl_dart---v331)
 - [`cbl_flutter_platform_interface` - `v3.1.2`](#cbl_flutter_platform_interface---v312)
 - [`cbl_generator` - `v0.3.1+2`](#cbl_generator---v0312)
 - [`cbl_sentry` - `v2.1.4`](#cbl_sentry---v214)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v3.3.1`
 - `cbl_flutter_install` - `v0.1.0+2`
 - `cbl_dart` - `v3.3.1`
 - `cbl_flutter_platform_interface` - `v3.1.2`
 - `cbl_generator` - `v0.3.1+2`
 - `cbl_sentry` - `v2.1.4`

---

#### `cbl` - `v3.4.1`

 - **FIX**: ensure `copyDirectoryContents` can overwrite links on all platforms ([#721](https://github.com/cbl-dart/cbl-dart/issues/721)). ([d0127459](https://github.com/cbl-dart/cbl-dart/commit/d0127459e3d5c44da265736367bb6fa45b99f90e))

#### `cbl_flutter_ce` - `v3.3.2`

 - **FIX**: resolve absolute path to dart executable Flutter plugin ([#722](https://github.com/cbl-dart/cbl-dart/issues/722)). ([81d78764](https://github.com/cbl-dart/cbl-dart/commit/81d78764fdafb5d8c9e5cdb7961b006130e3922b))

#### `cbl_flutter_ee` - `v3.3.2`

 - **FIX**: resolve absolute path to dart executable Flutter plugin ([#722](https://github.com/cbl-dart/cbl-dart/issues/722)). ([81d78764](https://github.com/cbl-dart/cbl-dart/commit/81d78764fdafb5d8c9e5cdb7961b006130e3922b))


## 2025-02-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.4.0`](#cbl---v340)
 - [`cbl_dart` - `v3.3.0`](#cbl_dart---v330)
 - [`cbl_flutter` - `v3.3.0`](#cbl_flutter---v330)
 - [`cbl_flutter_install` - `v0.1.0+1`](#cbl_flutter_install---v0101)
 - [`cbl_flutter_platform_interface` - `v3.1.1`](#cbl_flutter_platform_interface---v311)
 - [`cbl_sentry` - `v2.1.3`](#cbl_sentry---v213)
 - [`cbl_generator` - `v0.3.1+1`](#cbl_generator---v0311)
 - [`cbl_flutter_ce` - `v3.3.1`](#cbl_flutter_ce---v331)
 - [`cbl_flutter_ee` - `v3.3.1`](#cbl_flutter_ee---v331)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_install` - `v0.1.0+1`
 - `cbl_flutter_platform_interface` - `v3.1.1`
 - `cbl_sentry` - `v2.1.3`
 - `cbl_generator` - `v0.3.1+1`
 - `cbl_flutter_ce` - `v3.3.1`
 - `cbl_flutter_ee` - `v3.3.1`

---

#### `cbl` - `v3.4.0`

 - **REFACTOR**: disable comments and Dart enums for FFI bindings ([#685](https://github.com/cbl-dart/cbl-dart/issues/685)). ([da30961e](https://github.com/cbl-dart/cbl-dart/commit/da30961eef1c19aaf4c58a31416ad28a3d5721f0))
 - **FIX**: vector search extension library name on Linux ([#703](https://github.com/cbl-dart/cbl-dart/issues/703)). ([81f7d74a](https://github.com/cbl-dart/cbl-dart/commit/81f7d74a076488a956a167f12631bfb91b58bc07))
 - **FIX**: handle negative `DatabaseException.errorPosition` in `toString` ([#700](https://github.com/cbl-dart/cbl-dart/issues/700)). ([6e893d45](https://github.com/cbl-dart/cbl-dart/commit/6e893d45e0564ec2ca7e133869171be166317b0f))
 - **FIX**: handle `kCBLNetErrTLSHandshakeFailed` network error code ([#701](https://github.com/cbl-dart/cbl-dart/issues/701)). ([d6ffaf71](https://github.com/cbl-dart/cbl-dart/commit/d6ffaf710a0c27399718bda39675f97b894dc9d7))
 - **FEAT**: add `Extension.enableVectorSearch` ([#711](https://github.com/cbl-dart/cbl-dart/issues/711)). ([ad14951e](https://github.com/cbl-dart/cbl-dart/commit/ad14951e1ff69afff7d0617a7f442bd2199adaed))

#### `cbl_dart` - `v3.3.0`

 - **FIX**: vector search extension library name on Linux ([#703](https://github.com/cbl-dart/cbl-dart/issues/703)). ([81f7d74a](https://github.com/cbl-dart/cbl-dart/commit/81f7d74a076488a956a167f12631bfb91b58bc07))
 - **FEAT**: add `Extension.enableVectorSearch` ([#711](https://github.com/cbl-dart/cbl-dart/issues/711)). ([ad14951e](https://github.com/cbl-dart/cbl-dart/commit/ad14951e1ff69afff7d0617a7f442bd2199adaed))

#### `cbl_flutter` - `v3.3.0`

 - **FEAT**: add `Extension.enableVectorSearch` ([#711](https://github.com/cbl-dart/cbl-dart/issues/711)). ([ad14951e](https://github.com/cbl-dart/cbl-dart/commit/ad14951e1ff69afff7d0617a7f442bd2199adaed))


## 2024-12-06

### Changes

---

Packages with breaking changes:

 - [`cbl_generator` - `v0.3.1`](#cbl_generator---v031)
 - [`cbl_sentry` - `v2.1.2`](#cbl_sentry---v212)

Packages with other changes:

 - [`cbl` - `v3.3.0`](#cbl---v330)
 - [`cbl_dart` - `v3.2.0`](#cbl_dart---v320)
 - [`cbl_flutter` - `v3.2.0`](#cbl_flutter---v320)
 - [`cbl_flutter_ce` - `v3.3.0`](#cbl_flutter_ce---v330)
 - [`cbl_flutter_ee` - `v3.3.0`](#cbl_flutter_ee---v330)
 - [`cbl_flutter_install` - `v0.1.0`](#cbl_flutter_install---v010)
 - [`cbl_flutter_platform_interface` - `v3.1.0`](#cbl_flutter_platform_interface---v310)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `cbl` - `v3.3.0`
 - `cbl_dart` - `v3.2.0`
 - `cbl_flutter` - `v3.2.0`
 - `cbl_flutter_ce` - `v3.3.0`
 - `cbl_flutter_ee` - `v3.3.0`
 - `cbl_flutter_install` - `v0.1.0`
 - `cbl_flutter_platform_interface` - `v3.1.0`
 - `cbl_generator` - `v0.3.1`
 - `cbl_sentry` - `v2.1.2`

---

#### `cbl_generator` - `v0.3.1`

#### `cbl_sentry` - `v2.1.2`

#### `cbl` - `v3.3.0`

#### `cbl_dart` - `v3.2.0`

#### `cbl_flutter` - `v3.2.0`

#### `cbl_flutter_ce` - `v3.3.0`

#### `cbl_flutter_ee` - `v3.3.0`

#### `cbl_flutter_install` - `v0.1.0`

#### `cbl_flutter_platform_interface` - `v3.1.0`


## 2024-12-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.3.0-dev.5`](#cbl---v330-dev5)

---

#### `cbl` - `v3.3.0-dev.5`

 - **REFACTOR**: remove `CBLErrorException` ([#681](https://github.com/cbl-dart/cbl-dart/issues/681)). ([41e932dd](https://github.com/cbl-dart/cbl-dart/commit/41e932ddd8b5c50b5a2334e8166423c32abf90a1))
 - **REFACTOR**: represent hand written native enums same as ffigen ([#679](https://github.com/cbl-dart/cbl-dart/issues/679)). ([d9464435](https://github.com/cbl-dart/cbl-dart/commit/d9464435a74bac80a154f9d3d736202904c4174f))
 - **FIX**: error handling for `QueryIndex.beginUpdate` ([#683](https://github.com/cbl-dart/cbl-dart/issues/683)). ([c00da16b](https://github.com/cbl-dart/cbl-dart/commit/c00da16bc8230ed09536d173c49c87e0eedcb210))
 - **FIX**: don't close channel with pending calls ([#677](https://github.com/cbl-dart/cbl-dart/issues/677)). ([1d957d7d](https://github.com/cbl-dart/cbl-dart/commit/1d957d7d3461a2cd47787c5b062e13d4af25e48c))


## 2024-12-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.3.0-dev.4`](#cbl---v330-dev4)
 - [`cbl_flutter` - `v3.2.0-dev.5`](#cbl_flutter---v320-dev5)
 - [`cbl_flutter_install` - `v0.1.0-dev.4`](#cbl_flutter_install---v010-dev4)
 - [`cbl_flutter_platform_interface` - `v3.1.0-dev.4`](#cbl_flutter_platform_interface---v310-dev4)
 - [`cbl_dart` - `v3.2.0-dev.4`](#cbl_dart---v320-dev4)
 - [`cbl_generator` - `v0.3.1-dev.4`](#cbl_generator---v031-dev4)
 - [`cbl_sentry` - `v2.1.2-dev.4`](#cbl_sentry---v212-dev4)
 - [`cbl_flutter_ce` - `v3.3.0-dev.7`](#cbl_flutter_ce---v330-dev7)
 - [`cbl_flutter_ee` - `v3.3.0-dev.7`](#cbl_flutter_ee---v330-dev7)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v3.2.0-dev.5`
 - `cbl_flutter_install` - `v0.1.0-dev.4`
 - `cbl_flutter_platform_interface` - `v3.1.0-dev.4`
 - `cbl_dart` - `v3.2.0-dev.4`
 - `cbl_generator` - `v0.3.1-dev.4`
 - `cbl_sentry` - `v2.1.2-dev.4`
 - `cbl_flutter_ce` - `v3.3.0-dev.7`
 - `cbl_flutter_ee` - `v3.3.0-dev.7`

---

#### `cbl` - `v3.3.0-dev.4`

 - **FIX**: code sign vector serach library for macOS ([#663](https://github.com/cbl-dart/cbl-dart/issues/663)). ([b3d0c58b](https://github.com/cbl-dart/cbl-dart/commit/b3d0c58bb16daaa9ff4129ebda950058214f6235))


## 2024-11-30

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.3.0-dev.3`](#cbl---v330-dev3)
 - [`cbl_flutter_platform_interface` - `v3.1.0-dev.3`](#cbl_flutter_platform_interface---v310-dev3)
 - [`cbl_flutter_install` - `v0.1.0-dev.3`](#cbl_flutter_install---v010-dev3)
 - [`cbl_generator` - `v0.3.1-dev.3`](#cbl_generator---v031-dev3)
 - [`cbl_sentry` - `v2.1.2-dev.3`](#cbl_sentry---v212-dev3)
 - [`cbl_flutter` - `v3.2.0-dev.4`](#cbl_flutter---v320-dev4)
 - [`cbl_dart` - `v3.2.0-dev.3`](#cbl_dart---v320-dev3)
 - [`cbl_flutter_ce` - `v3.3.0-dev.6`](#cbl_flutter_ce---v330-dev6)
 - [`cbl_flutter_ee` - `v3.3.0-dev.6`](#cbl_flutter_ee---v330-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_install` - `v0.1.0-dev.3`
 - `cbl_generator` - `v0.3.1-dev.3`
 - `cbl_sentry` - `v2.1.2-dev.3`
 - `cbl_flutter` - `v3.2.0-dev.4`
 - `cbl_dart` - `v3.2.0-dev.3`
 - `cbl_flutter_ce` - `v3.3.0-dev.6`
 - `cbl_flutter_ee` - `v3.3.0-dev.6`

---

#### `cbl` - `v3.3.0-dev.3`

 - **FEAT**: support updating lazy vector indexes ([#661](https://github.com/cbl-dart/cbl-dart/issues/661)). ([909a21ee](https://github.com/cbl-dart/cbl-dart/commit/909a21eed6648a6fc31eac41494e153f543ce78b))
 - **FEAT**: support creating vector indexs ([#660](https://github.com/cbl-dart/cbl-dart/issues/660)). ([3bb84324](https://github.com/cbl-dart/cbl-dart/commit/3bb84324718bc54e55837d5e85f7771381850cf3))
 - **FEAT**: add support for predictive models ([#645](https://github.com/cbl-dart/cbl-dart/issues/645)). ([1be1949a](https://github.com/cbl-dart/cbl-dart/commit/1be1949a95e317f17044b89680b9de59c75937f0))

#### `cbl_flutter_platform_interface` - `v3.1.0-dev.3`

 - **FEAT**: support creating vector indexs ([#660](https://github.com/cbl-dart/cbl-dart/issues/660)). ([3bb84324](https://github.com/cbl-dart/cbl-dart/commit/3bb84324718bc54e55837d5e85f7771381850cf3))


## 2024-11-30

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.3.0-dev.2`](#cbl---v330-dev2)
 - [`cbl_flutter_install` - `v0.1.0-dev.2`](#cbl_flutter_install---v010-dev2)
 - [`cbl_sentry` - `v2.1.2-dev.2`](#cbl_sentry---v212-dev2)
 - [`cbl_flutter_platform_interface` - `v3.1.0-dev.2`](#cbl_flutter_platform_interface---v310-dev2)
 - [`cbl_flutter` - `v3.2.0-dev.3`](#cbl_flutter---v320-dev3)
 - [`cbl_dart` - `v3.2.0-dev.2`](#cbl_dart---v320-dev2)
 - [`cbl_generator` - `v0.3.1-dev.2`](#cbl_generator---v031-dev2)
 - [`cbl_flutter_ce` - `v3.3.0-dev.5`](#cbl_flutter_ce---v330-dev5)
 - [`cbl_flutter_ee` - `v3.3.0-dev.5`](#cbl_flutter_ee---v330-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_install` - `v0.1.0-dev.2`
 - `cbl_sentry` - `v2.1.2-dev.2`
 - `cbl_flutter_platform_interface` - `v3.1.0-dev.2`
 - `cbl_flutter` - `v3.2.0-dev.3`
 - `cbl_dart` - `v3.2.0-dev.2`
 - `cbl_generator` - `v0.3.1-dev.2`
 - `cbl_flutter_ce` - `v3.3.0-dev.5`
 - `cbl_flutter_ee` - `v3.3.0-dev.5`

---

#### `cbl` - `v3.3.0-dev.2`

 - **FIX**: for installing native packages use temp dir on same volume ([#659](https://github.com/cbl-dart/cbl-dart/issues/659)). ([ebc9be0c](https://github.com/cbl-dart/cbl-dart/commit/ebc9be0c5c0bc11f76b946f01459582345db1ca4))


## 2024-11-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_flutter_ce` - `v3.3.0-dev.4`](#cbl_flutter_ce---v330-dev4)
 - [`cbl_flutter_ee` - `v3.3.0-dev.4`](#cbl_flutter_ee---v330-dev4)

---

#### `cbl_flutter_ce` - `v3.3.0-dev.4`

 - **FIX**: use `dart pub global run` to invoke `cbl_flutter_install` ([#658](https://github.com/cbl-dart/cbl-dart/issues/658)). ([d2f0d356](https://github.com/cbl-dart/cbl-dart/commit/d2f0d356cb1e69dabdf3530b7b8ab65fb73c3aa5))

#### `cbl_flutter_ee` - `v3.3.0-dev.4`

 - **FIX**: use `dart pub global run` to invoke `cbl_flutter_install` ([#658](https://github.com/cbl-dart/cbl-dart/issues/658)). ([d2f0d356](https://github.com/cbl-dart/cbl-dart/commit/d2f0d356cb1e69dabdf3530b7b8ab65fb73c3aa5))


## 2024-11-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.3.0-dev.1`](#cbl---v330-dev1)
 - [`cbl_flutter` - `v3.2.0-dev.2`](#cbl_flutter---v320-dev2)
 - [`cbl_flutter_ce` - `v3.3.0-dev.3`](#cbl_flutter_ce---v330-dev3)
 - [`cbl_flutter_ee` - `v3.3.0-dev.3`](#cbl_flutter_ee---v330-dev3)
 - [`cbl_flutter_install` - `v0.1.0-dev.1`](#cbl_flutter_install---v010-dev1)
 - [`cbl_sentry` - `v2.1.2-dev.1`](#cbl_sentry---v212-dev1)
 - [`cbl_flutter_platform_interface` - `v3.1.0-dev.1`](#cbl_flutter_platform_interface---v310-dev1)
 - [`cbl_generator` - `v0.3.1-dev.1`](#cbl_generator---v031-dev1)
 - [`cbl_dart` - `v3.2.0-dev.1`](#cbl_dart---v320-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_install` - `v0.1.0-dev.1`
 - `cbl_sentry` - `v2.1.2-dev.1`
 - `cbl_flutter_platform_interface` - `v3.1.0-dev.1`
 - `cbl_generator` - `v0.3.1-dev.1`
 - `cbl_dart` - `v3.2.0-dev.1`

---

#### `cbl` - `v3.3.0-dev.1`

 - **FIX**: invoking `cbl_flutter_install` on Windows ([#656](https://github.com/cbl-dart/cbl-dart/issues/656)). ([d9eaca2b](https://github.com/cbl-dart/cbl-dart/commit/d9eaca2be3b69eee525d9896e31ace19ff1a90ca))

#### `cbl_flutter` - `v3.2.0-dev.2`

 - **FIX**: move functionality to install native libraries to own package. ([d4faef33](https://github.com/cbl-dart/cbl-dart/commit/d4faef33bf654ac5365f11c874bfe422bbe89858))
 - **FIX**: upgrade to Gradle Kotlin plugin `1.9.25` ([#654](https://github.com/cbl-dart/cbl-dart/issues/654)). ([1d105d3d](https://github.com/cbl-dart/cbl-dart/commit/1d105d3d33316326760c5fba26c858d8afc0ea6c))

#### `cbl_flutter_ce` - `v3.3.0-dev.3`

 - **FIX**: invoking `cbl_flutter_install` on Windows ([#656](https://github.com/cbl-dart/cbl-dart/issues/656)). ([d9eaca2b](https://github.com/cbl-dart/cbl-dart/commit/d9eaca2be3b69eee525d9896e31ace19ff1a90ca))
 - **FIX**: move functionality to install native libraries to own package. ([d4faef33](https://github.com/cbl-dart/cbl-dart/commit/d4faef33bf654ac5365f11c874bfe422bbe89858))
 - **FIX**: upgrade to Gradle Kotlin plugin `1.9.25` ([#654](https://github.com/cbl-dart/cbl-dart/issues/654)). ([1d105d3d](https://github.com/cbl-dart/cbl-dart/commit/1d105d3d33316326760c5fba26c858d8afc0ea6c))

#### `cbl_flutter_ee` - `v3.3.0-dev.3`

 - **FIX**: invoking `cbl_flutter_install` on Windows ([#656](https://github.com/cbl-dart/cbl-dart/issues/656)). ([d9eaca2b](https://github.com/cbl-dart/cbl-dart/commit/d9eaca2be3b69eee525d9896e31ace19ff1a90ca))
 - **FIX**: move functionality to install native libraries to own package. ([d4faef33](https://github.com/cbl-dart/cbl-dart/commit/d4faef33bf654ac5365f11c874bfe422bbe89858))
 - **FIX**: upgrade to Gradle Kotlin plugin `1.9.25` ([#654](https://github.com/cbl-dart/cbl-dart/issues/654)). ([1d105d3d](https://github.com/cbl-dart/cbl-dart/commit/1d105d3d33316326760c5fba26c858d8afc0ea6c))


## 2024-11-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_flutter_install` - `v0.1.0-dev.0`](#cbl_flutter_install---v010-dev0)
 - [`cbl_flutter_ce` - `v3.3.0-dev.3`](#cbl_flutter_ce---v330-dev3)
 - [`cbl_flutter_ee` - `v3.3.0-dev.3`](#cbl_flutter_ee---v330-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_ce` - `v3.3.0-dev.3`
 - `cbl_flutter_ee` - `v3.3.0-dev.3`

---

#### `cbl_flutter_install` - `v0.1.0-dev.0`

 - **FIX**: move functionality to install native libraries to own package. ([d4faef33](https://github.com/cbl-dart/cbl-dart/commit/d4faef33bf654ac5365f11c874bfe422bbe89858))


## 2024-11-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_flutter_ce` - `v3.3.0-dev.2`](#cbl_flutter_ce---v330-dev2)
 - [`cbl_flutter_ee` - `v3.3.0-dev.2`](#cbl_flutter_ee---v330-dev2)

---

#### `cbl_flutter_ce` - `v3.3.0-dev.2`

 - **FIX**: global activation of cbl_flutter for Windows and Linux. ([935cc837](https://github.com/cbl-dart/cbl-dart/commit/935cc837b213615a27697c1e9dd59168b591902b))

#### `cbl_flutter_ee` - `v3.3.0-dev.2`

 - **FIX**: global activation of cbl_flutter for Windows and Linux. ([935cc837](https://github.com/cbl-dart/cbl-dart/commit/935cc837b213615a27697c1e9dd59168b591902b))


## 2024-11-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_flutter` - `v3.2.0-dev.1`](#cbl_flutter---v320-dev1)
 - [`cbl_flutter_ce` - `v3.3.0-dev.1`](#cbl_flutter_ce---v330-dev1)
 - [`cbl_flutter_ee` - `v3.3.0-dev.1`](#cbl_flutter_ee---v330-dev1)

---

#### `cbl_flutter` - `v3.2.0-dev.1`

 - **FIX**: globally activate cbl_flutter during install. ([ebefdd16](https://github.com/cbl-dart/cbl-dart/commit/ebefdd16555bca83a622f5ba9d9186f40dbdab31))

#### `cbl_flutter_ce` - `v3.3.0-dev.1`

 - **FIX**: globally activate cbl_flutter during install. ([ebefdd16](https://github.com/cbl-dart/cbl-dart/commit/ebefdd16555bca83a622f5ba9d9186f40dbdab31))

#### `cbl_flutter_ee` - `v3.3.0-dev.1`

 - **FIX**: globally activate cbl_flutter during install. ([ebefdd16](https://github.com/cbl-dart/cbl-dart/commit/ebefdd16555bca83a622f5ba9d9186f40dbdab31))


## 2024-11-26

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.3.0-dev.0`](#cbl---v330-dev0)
 - [`cbl_dart` - `v3.2.0-dev.0`](#cbl_dart---v320-dev0)
 - [`cbl_flutter` - `v3.2.0-dev.0`](#cbl_flutter---v320-dev0)
 - [`cbl_flutter_ce` - `v3.3.0-dev.0`](#cbl_flutter_ce---v330-dev0)
 - [`cbl_flutter_ee` - `v3.3.0-dev.0`](#cbl_flutter_ee---v330-dev0)
 - [`cbl_flutter_platform_interface` - `v3.1.0-dev.0`](#cbl_flutter_platform_interface---v310-dev0)
 - [`cbl_generator` - `v0.3.1-dev.0`](#cbl_generator---v031-dev0)
 - [`cbl_sentry` - `v2.1.2-dev.0`](#cbl_sentry---v212-dev0)

---

#### `cbl` - `v3.3.0-dev.0`

 - **REFACTOR**: remove duplication of Librarie(s)Configuration classes ([#642](https://github.com/cbl-dart/cbl-dart/issues/642)). ([9be1b59e](https://github.com/cbl-dart/cbl-dart/commit/9be1b59e9f105797b79082e79d46f4801e9dcbc9))
 - **REFACTOR**: remove cblBindings in favor of CBLBindings.instance ([#641](https://github.com/cbl-dart/cbl-dart/issues/641)). ([776eb700](https://github.com/cbl-dart/cbl-dart/commit/776eb700c122b3c12d4573a91106170027dd0ca2))
 - **REFACTOR**: make native library install code more flexible ([#640](https://github.com/cbl-dart/cbl-dart/issues/640)). ([7c54b0dc](https://github.com/cbl-dart/cbl-dart/commit/7c54b0dca40f42adc224da23406b21eabba32e12))
 - **REFACTOR**: use ffigen to generate bindings ([#633](https://github.com/cbl-dart/cbl-dart/issues/633)). ([900bd3ca](https://github.com/cbl-dart/cbl-dart/commit/900bd3cadeb3b9e059f91ce717bc7e9afd7c871a))
 - **FEAT**: support typed documents in collections ([#650](https://github.com/cbl-dart/cbl-dart/issues/650)). ([d6a20e52](https://github.com/cbl-dart/cbl-dart/commit/d6a20e5235493c9e841dfea395d6f7863c0c6ea1))
 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))
 - **FEAT**: use Dart for native libraries install script ([#639](https://github.com/cbl-dart/cbl-dart/issues/639)). ([40c70c71](https://github.com/cbl-dart/cbl-dart/commit/40c70c716361368481537c718c5459ef983136f6))
 - **FEAT**: add `DatabaseConfiguration.fullSync` ([#637](https://github.com/cbl-dart/cbl-dart/issues/637)). ([7f5341b1](https://github.com/cbl-dart/cbl-dart/commit/7f5341b1e3330d7c42082f6f0890c34ed9090180))

#### `cbl_dart` - `v3.2.0-dev.0`

 - **REFACTOR**: make native library install code more flexible ([#640](https://github.com/cbl-dart/cbl-dart/issues/640)). ([7c54b0dc](https://github.com/cbl-dart/cbl-dart/commit/7c54b0dca40f42adc224da23406b21eabba32e12))
 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))
 - **FEAT**: use Dart for native libraries install script ([#639](https://github.com/cbl-dart/cbl-dart/issues/639)). ([40c70c71](https://github.com/cbl-dart/cbl-dart/commit/40c70c716361368481537c718c5459ef983136f6))

#### `cbl_flutter` - `v3.2.0-dev.0`

 - **REFACTOR**: remove duplication of Librarie(s)Configuration classes ([#642](https://github.com/cbl-dart/cbl-dart/issues/642)). ([9be1b59e](https://github.com/cbl-dart/cbl-dart/commit/9be1b59e9f105797b79082e79d46f4801e9dcbc9))
 - **REFACTOR**: make native library install code more flexible ([#640](https://github.com/cbl-dart/cbl-dart/issues/640)). ([7c54b0dc](https://github.com/cbl-dart/cbl-dart/commit/7c54b0dca40f42adc224da23406b21eabba32e12))
 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))
 - **FEAT**: use Dart for native libraries install script ([#639](https://github.com/cbl-dart/cbl-dart/issues/639)). ([40c70c71](https://github.com/cbl-dart/cbl-dart/commit/40c70c716361368481537c718c5459ef983136f6))

#### `cbl_flutter_ce` - `v3.3.0-dev.0`

 - **REFACTOR**: make native library install code more flexible ([#640](https://github.com/cbl-dart/cbl-dart/issues/640)). ([7c54b0dc](https://github.com/cbl-dart/cbl-dart/commit/7c54b0dca40f42adc224da23406b21eabba32e12))
 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))
 - **FEAT**: use Dart for native libraries install script ([#639](https://github.com/cbl-dart/cbl-dart/issues/639)). ([40c70c71](https://github.com/cbl-dart/cbl-dart/commit/40c70c716361368481537c718c5459ef983136f6))

#### `cbl_flutter_ee` - `v3.3.0-dev.0`

 - **REFACTOR**: make native library install code more flexible ([#640](https://github.com/cbl-dart/cbl-dart/issues/640)). ([7c54b0dc](https://github.com/cbl-dart/cbl-dart/commit/7c54b0dca40f42adc224da23406b21eabba32e12))
 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))
 - **FEAT**: use Dart for native libraries install script ([#639](https://github.com/cbl-dart/cbl-dart/issues/639)). ([40c70c71](https://github.com/cbl-dart/cbl-dart/commit/40c70c716361368481537c718c5459ef983136f6))

#### `cbl_flutter_platform_interface` - `v3.1.0-dev.0`

 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))

#### `cbl_generator` - `v0.3.1-dev.0`

 - **FEAT**: support typed documents in collections ([#650](https://github.com/cbl-dart/cbl-dart/issues/650)). ([d6a20e52](https://github.com/cbl-dart/cbl-dart/commit/d6a20e5235493c9e841dfea395d6f7863c0c6ea1))

#### `cbl_sentry` - `v2.1.2-dev.0`

 - **REFACTOR**: use ffigen to generate bindings ([#633](https://github.com/cbl-dart/cbl-dart/issues/633)). ([900bd3ca](https://github.com/cbl-dart/cbl-dart/commit/900bd3cadeb3b9e059f91ce717bc7e9afd7c871a))


## 2024-10-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_flutter` - `v3.1.3`](#cbl_flutter---v313)

---

#### `cbl_flutter` - `v3.1.3`

 - **FIX**: put `CBLTemp` directory in application support directory ([#625](https://github.com/cbl-dart/cbl-dart/issues/625)). ([6404d1e6](https://github.com/cbl-dart/cbl-dart/commit/6404d1e6ce8eafd5e120fc44033a67ace25e2de0))


## 2024-10-08

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.2.1`](#cbl---v321)
 - [`cbl_flutter` - `v3.1.2`](#cbl_flutter---v312)
 - [`cbl_flutter_ce` - `v3.2.1`](#cbl_flutter_ce---v321)
 - [`cbl_flutter_ee` - `v3.2.1`](#cbl_flutter_ee---v321)
 - [`cbl_flutter_platform_interface` - `v3.0.3`](#cbl_flutter_platform_interface---v303)
 - [`cbl_dart` - `v3.1.1`](#cbl_dart---v311)
 - [`cbl_sentry` - `v2.1.2`](#cbl_sentry---v212)
 - [`cbl_generator` - `v0.3.0+3`](#cbl_generator---v0303)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_platform_interface` - `v3.0.3`
 - `cbl_dart` - `v3.1.1`
 - `cbl_sentry` - `v2.1.2`
 - `cbl_generator` - `v0.3.0+3`

---

#### `cbl` - `v3.2.1`

 - **FIX**: translate errors when setting file logging config ([#623](https://github.com/cbl-dart/cbl-dart/issues/623)). ([1b646e3f](https://github.com/cbl-dart/cbl-dart/commit/1b646e3f31bfe2f719bef811bc690f2b17e2f195))

#### `cbl_flutter` - `v3.1.2`

 - **FIX**: add workaround for loading native libraries on older versions of Android ([#624](https://github.com/cbl-dart/cbl-dart/issues/624)). ([72b004ab](https://github.com/cbl-dart/cbl-dart/commit/72b004abb206afd72984bcd6f7689667f4215f3b))

#### `cbl_flutter_ce` - `v3.2.1`

 - **FIX**: add workaround for loading native libraries on older versions of Android ([#624](https://github.com/cbl-dart/cbl-dart/issues/624)). ([72b004ab](https://github.com/cbl-dart/cbl-dart/commit/72b004abb206afd72984bcd6f7689667f4215f3b))

#### `cbl_flutter_ee` - `v3.2.1`

 - **FIX**: add workaround for loading native libraries on older versions of Android ([#624](https://github.com/cbl-dart/cbl-dart/issues/624)). ([72b004ab](https://github.com/cbl-dart/cbl-dart/commit/72b004abb206afd72984bcd6f7689667f4215f3b))


## 2024-10-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_flutter` - `v3.1.1`](#cbl_flutter---v311)

---

#### `cbl_flutter` - `v3.1.1`

 - **FIX**: create CBLTemp directory recursively ([#620](https://github.com/cbl-dart/cbl-dart/issues/620)). ([687068a0](https://github.com/cbl-dart/cbl-dart/commit/687068a08cdb87c405b8369c4ccdf7830ae8eb25))


## 2024-10-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_dart` - `v3.1.0`](#cbl_dart---v310)
 - [`cbl_flutter_ce` - `v3.2.0`](#cbl_flutter_ce---v320)
 - [`cbl_flutter_ee` - `v3.2.0`](#cbl_flutter_ee---v320)

---

#### `cbl_dart` - `v3.1.0`

 - **FEAT**: provide libcblite `3.2.0`. ([b0e2a1cc](https://github.com/cbl-dart/cbl-dart/commit/b0e2a1ccbd20f2b3c866ef39ce7824991c90f836))

#### `cbl_flutter_ce` - `v3.2.0`

 - **FEAT**: provide libcblite `3.2.0`. ([b0e2a1cc](https://github.com/cbl-dart/cbl-dart/commit/b0e2a1ccbd20f2b3c866ef39ce7824991c90f836))

#### `cbl_flutter_ee` - `v3.2.0`

 - **FEAT**: provide libcblite `3.2.0`. ([b0e2a1cc](https://github.com/cbl-dart/cbl-dart/commit/b0e2a1ccbd20f2b3c866ef39ce7824991c90f836))


## 2024-09-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.2.0`](#cbl---v320)
 - [`cbl_flutter` - `v3.1.1`](#cbl_flutter---v311)
 - [`cbl_flutter_platform_interface` - `v3.0.3`](#cbl_flutter_platform_interface---v303)
 - [`cbl_dart` - `v3.0.4`](#cbl_dart---v304)
 - [`cbl_generator` - `v0.3.0+3`](#cbl_generator---v0303)
 - [`cbl_sentry` - `v2.1.2`](#cbl_sentry---v212)
 - [`cbl_flutter_ce` - `v3.1.1`](#cbl_flutter_ce---v311)
 - [`cbl_flutter_ee` - `v3.1.1`](#cbl_flutter_ee---v311)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v3.1.1`
 - `cbl_flutter_platform_interface` - `v3.0.3`
 - `cbl_dart` - `v3.0.4`
 - `cbl_generator` - `v0.3.0+3`
 - `cbl_sentry` - `v2.1.2`
 - `cbl_flutter_ce` - `v3.1.1`
 - `cbl_flutter_ee` - `v3.1.1`

---

#### `cbl` - `v3.2.0`

 - **FEAT**: loosen version constraint for `web_socket_channel` to allow `>=2.1.0 <4.0.0` ([#616](https://github.com/cbl-dart/cbl-dart/issues/616)). ([de572588](https://github.com/cbl-dart/cbl-dart/commit/de5725889e5c057bfa729635f886fa403254dcc4))


## 2024-09-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.1.1`](#cbl---v311)
 - [`cbl_flutter` - `v3.1.0`](#cbl_flutter---v310)
 - [`cbl_flutter_ce` - `v3.1.0`](#cbl_flutter_ce---v310)
 - [`cbl_flutter_ee` - `v3.1.0`](#cbl_flutter_ee---v310)
 - [`cbl_generator` - `v0.3.0+2`](#cbl_generator---v0302)
 - [`cbl_flutter_platform_interface` - `v3.0.2`](#cbl_flutter_platform_interface---v302)
 - [`cbl_dart` - `v3.0.3`](#cbl_dart---v303)
 - [`cbl_sentry` - `v2.1.1`](#cbl_sentry---v211)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_platform_interface` - `v3.0.2`
 - `cbl_dart` - `v3.0.3`
 - `cbl_sentry` - `v2.1.1`

---

#### `cbl` - `v3.1.1`

 - **REFACTOR**: use `nonNulls` instead of `whereNotNull` ([#607](https://github.com/cbl-dart/cbl-dart/issues/607)). ([d1f87210](https://github.com/cbl-dart/cbl-dart/commit/d1f872106ba32f62772d91734a8bab1e3a6b7e0e))

#### `cbl_flutter` - `v3.1.0`

 - **FEAT**: support Android Gradle Plugin 8 ([#615](https://github.com/cbl-dart/cbl-dart/issues/615)). ([b0e5bf21](https://github.com/cbl-dart/cbl-dart/commit/b0e5bf21cbb3eb216ff9541a99c5d3c72c56387b))

#### `cbl_flutter_ce` - `v3.1.0`

 - **FEAT**: support Android Gradle Plugin 8 ([#615](https://github.com/cbl-dart/cbl-dart/issues/615)). ([b0e5bf21](https://github.com/cbl-dart/cbl-dart/commit/b0e5bf21cbb3eb216ff9541a99c5d3c72c56387b))

#### `cbl_flutter_ee` - `v3.1.0`

 - **FEAT**: support Android Gradle Plugin 8 ([#615](https://github.com/cbl-dart/cbl-dart/issues/615)). ([b0e5bf21](https://github.com/cbl-dart/cbl-dart/commit/b0e5bf21cbb3eb216ff9541a99c5d3c72c56387b))

#### `cbl_generator` - `v0.3.0+2`

 - **REFACTOR**: don't use `getDisplayString` with `withNullability` ([#608](https://github.com/cbl-dart/cbl-dart/issues/608)). ([aa840e04](https://github.com/cbl-dart/cbl-dart/commit/aa840e044fa863de21cb76a4145656425c145d2a))


## 2024-09-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl` - `v3.1.0`](#cbl---v310)
 - [`cbl_sentry` - `v2.1.0`](#cbl_sentry---v210)
 - [`cbl_flutter` - `v3.0.1`](#cbl_flutter---v301)
 - [`cbl_flutter_platform_interface` - `v3.0.1`](#cbl_flutter_platform_interface---v301)
 - [`cbl_dart` - `v3.0.2`](#cbl_dart---v302)
 - [`cbl_generator` - `v0.3.0+1`](#cbl_generator---v0301)
 - [`cbl_flutter_ce` - `v3.0.1`](#cbl_flutter_ce---v301)
 - [`cbl_flutter_ee` - `v3.0.1`](#cbl_flutter_ee---v301)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter` - `v3.0.1`
 - `cbl_flutter_platform_interface` - `v3.0.1`
 - `cbl_dart` - `v3.0.2`
 - `cbl_generator` - `v0.3.0+1`
 - `cbl_flutter_ce` - `v3.0.1`
 - `cbl_flutter_ee` - `v3.0.1`

---

#### `cbl` - `v3.1.0`

 - **FEAT**: use `asUnmodifiableView` instead of `UnmodifiableUint8ListView` ([#599](https://github.com/cbl-dart/cbl-dart/issues/599)). ([3ca65118](https://github.com/cbl-dart/cbl-dart/commit/3ca65118d803966004eca6d37faded9221d6dfe1))

#### `cbl_sentry` - `v2.1.0`

 - **FEAT**: use `asUnmodifiableView` instead of `UnmodifiableUint8ListView` ([#599](https://github.com/cbl-dart/cbl-dart/issues/599)). ([3ca65118](https://github.com/cbl-dart/cbl-dart/commit/3ca65118d803966004eca6d37faded9221d6dfe1))


## 2024-04-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`cbl_dart` - `v3.0.1`](#cbl_dart---v301)

---

#### `cbl_dart` - `v3.0.1`

 - **FIX**(cbl_dart): adapt to `extractArchiveToDisk` in `package:archive` becoming async ([#581](https://github.com/cbl-dart/cbl-dart/issues/581)). ([9e38fd3b](https://github.com/cbl-dart/cbl-dart/commit/9e38fd3bdf416c224923d6bec2949d8698a9c57a))


## 2024-04-24

### Changes

---

Packages with breaking changes:

 - [`cbl` - `v3.0.0`](#cbl---v300)
 - [`cbl_dart` - `v3.0.0`](#cbl_dart---v300)
 - [`cbl_flutter` - `v3.0.0`](#cbl_flutter---v300)
 - [`cbl_flutter_ce` - `v3.0.0`](#cbl_flutter_ce---v300)
 - [`cbl_flutter_ee` - `v3.0.0`](#cbl_flutter_ee---v300)
 - [`cbl_flutter_platform_interface` - `v3.0.0`](#cbl_flutter_platform_interface---v300)
 - [`cbl_sentry` - `v2.0.0`](#cbl_sentry---v200)

Packages with other changes:

 - [`cbl_generator` - `v0.3.0`](#cbl_generator---v030)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `cbl` - `v3.0.0`
 - `cbl_dart` - `v3.0.0`
 - `cbl_flutter` - `v3.0.0`
 - `cbl_flutter_ce` - `v3.0.0`
 - `cbl_flutter_ee` - `v3.0.0`
 - `cbl_flutter_platform_interface` - `v3.0.0`
 - `cbl_generator` - `v0.3.0`
 - `cbl_sentry` - `v2.0.0`

---

#### `cbl` - `v3.0.0`

#### `cbl_dart` - `v3.0.0`

#### `cbl_flutter` - `v3.0.0`

#### `cbl_flutter_ce` - `v3.0.0`

#### `cbl_flutter_ee` - `v3.0.0`

#### `cbl_flutter_platform_interface` - `v3.0.0`

#### `cbl_sentry` - `v2.0.0`

#### `cbl_generator` - `v0.3.0`


## 2024-04-24

### Changes

---

Packages with breaking changes:

 - [`cbl` - `v3.0.0-dev.5`](#cbl---v300-dev5)
 - [`cbl_dart` - `v3.0.0-dev.6`](#cbl_dart---v300-dev6)
 - [`cbl_flutter` - `v3.0.0-dev.5`](#cbl_flutter---v300-dev5)
 - [`cbl_generator` - `v0.3.0-dev.5`](#cbl_generator---v030-dev5)
 - [`cbl_sentry` - `v2.0.0-dev.6`](#cbl_sentry---v200-dev6)

Packages with other changes:

 - [`cbl_flutter_platform_interface` - `v3.0.0-dev.5`](#cbl_flutter_platform_interface---v300-dev5)
 - [`cbl_flutter_ce` - `v3.0.0-dev.5`](#cbl_flutter_ce---v300-dev5)
 - [`cbl_flutter_ee` - `v3.0.0-dev.5`](#cbl_flutter_ee---v300-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_platform_interface` - `v3.0.0-dev.5`
 - `cbl_flutter_ce` - `v3.0.0-dev.5`
 - `cbl_flutter_ee` - `v3.0.0-dev.5`

---

#### `cbl` - `v3.0.0-dev.5`

 - **DOCS**: use collections in README code example. ([ba25ffe2](https://github.com/cbl-dart/cbl-dart/commit/ba25ffe2fc408859ce61db34a6e9bbe6737cbec6))
 - **BREAKING** **FEAT**: replace `Query.from*` with `Database.createQuery` ([#580](https://github.com/cbl-dart/cbl-dart/issues/580)). ([aa104e25](https://github.com/cbl-dart/cbl-dart/commit/aa104e251c74c8487ccbaaa99c2b6ef03e60c3d7))

#### `cbl_dart` - `v3.0.0-dev.6`

 - **DOCS**(cbl_dart): use scopes and collections in example. ([ab4392d3](https://github.com/cbl-dart/cbl-dart/commit/ab4392d3a3ed0cce08c66726b2c67d2b3b50174e))
 - **DOCS**: use collections in README code example. ([ba25ffe2](https://github.com/cbl-dart/cbl-dart/commit/ba25ffe2fc408859ce61db34a6e9bbe6737cbec6))
 - **BREAKING** **FEAT**: replace `Query.from*` with `Database.createQuery` ([#580](https://github.com/cbl-dart/cbl-dart/issues/580)). ([aa104e25](https://github.com/cbl-dart/cbl-dart/commit/aa104e251c74c8487ccbaaa99c2b6ef03e60c3d7))

#### `cbl_flutter` - `v3.0.0-dev.5`

 - **DOCS**: use collections in README code example. ([ba25ffe2](https://github.com/cbl-dart/cbl-dart/commit/ba25ffe2fc408859ce61db34a6e9bbe6737cbec6))
 - **BREAKING** **FEAT**: replace `Query.from*` with `Database.createQuery` ([#580](https://github.com/cbl-dart/cbl-dart/issues/580)). ([aa104e25](https://github.com/cbl-dart/cbl-dart/commit/aa104e251c74c8487ccbaaa99c2b6ef03e60c3d7))

#### `cbl_generator` - `v0.3.0-dev.5`

 - **BREAKING** **FEAT**: replace `Query.from*` with `Database.createQuery` ([#580](https://github.com/cbl-dart/cbl-dart/issues/580)). ([aa104e25](https://github.com/cbl-dart/cbl-dart/commit/aa104e251c74c8487ccbaaa99c2b6ef03e60c3d7))

#### `cbl_sentry` - `v2.0.0-dev.6`

 - **BREAKING** **FEAT**: replace `Query.from*` with `Database.createQuery` ([#580](https://github.com/cbl-dart/cbl-dart/issues/580)). ([aa104e25](https://github.com/cbl-dart/cbl-dart/commit/aa104e251c74c8487ccbaaa99c2b6ef03e60c3d7))


## 2024-04-18

### Changes

---

Packages with breaking changes:

 - [`cbl` - `v3.0.0-dev.4`](#cbl---v300-dev4)
 - [`cbl_dart` - `v3.0.0-dev.5`](#cbl_dart---v300-dev5)
 - [`cbl_flutter` - `v3.0.0-dev.4`](#cbl_flutter---v300-dev4)
 - [`cbl_flutter_platform_interface` - `v3.0.0-dev.4`](#cbl_flutter_platform_interface---v300-dev4)
 - [`cbl_generator` - `v0.3.0-dev.4`](#cbl_generator---v030-dev4)
 - [`cbl_sentry` - `v2.0.0-dev.5`](#cbl_sentry---v200-dev5)

Packages with other changes:

 - [`cbl_flutter_ce` - `v3.0.0-dev.4`](#cbl_flutter_ce---v300-dev4)
 - [`cbl_flutter_ee` - `v3.0.0-dev.4`](#cbl_flutter_ee---v300-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `cbl_flutter_ce` - `v3.0.0-dev.4`
 - `cbl_flutter_ee` - `v3.0.0-dev.4`

---

#### `cbl` - `v3.0.0-dev.4`

 - **REFACTOR**: fix analyzer issues. ([846cb48d](https://github.com/cbl-dart/cbl-dart/commit/846cb48d86f7309a7f8a65ecc6be0bb71b7d7254))
 - **REFACTOR**: merge `cbl_ffi` into `cbl` ([#554](https://github.com/cbl-dart/cbl-dart/issues/554)). ([08039cff](https://github.com/cbl-dart/cbl-dart/commit/08039cff6e1328b88098af34884f4861f94cb7a5))
 - **BREAKING** **FEAT**(cbl): add class modifiers ([#575](https://github.com/cbl-dart/cbl-dart/issues/575)). ([672df44c](https://github.com/cbl-dart/cbl-dart/commit/672df44c64374f1b3ad9ebd4d93272ea9a51d856))

#### `cbl_dart` - `v3.0.0-dev.5`

 - **BREAKING** **FEAT**(cbl_dart): add class modifiers ([#572](https://github.com/cbl-dart/cbl-dart/issues/572)). ([037b8da5](https://github.com/cbl-dart/cbl-dart/commit/037b8da5b814d740d8892f70c1acfb7b8ec13b1b))

#### `cbl_flutter` - `v3.0.0-dev.4`

 - **BREAKING** **FEAT**(cbl_flutter): add class modifiers ([#571](https://github.com/cbl-dart/cbl-dart/issues/571)). ([ebdd104a](https://github.com/cbl-dart/cbl-dart/commit/ebdd104a179d9360d814d37afd6ef86ee810d71c))

#### `cbl_flutter_platform_interface` - `v3.0.0-dev.4`

 - **BREAKING** **FEAT**(cbl_flutter_platform_interface): add class modifiers ([#567](https://github.com/cbl-dart/cbl-dart/issues/567)). ([01f67681](https://github.com/cbl-dart/cbl-dart/commit/01f67681e298f4fec3e39aaa89307417da58bd89))

#### `cbl_generator` - `v0.3.0-dev.4`

 - **REFACTOR**(cbl_generator): add class modifiers ([#570](https://github.com/cbl-dart/cbl-dart/issues/570)). ([cb49b7e5](https://github.com/cbl-dart/cbl-dart/commit/cb49b7e548c8232db6668df5b8a8f1b0a6afb11d))
 - **BREAKING** **FEAT**(cbl): add class modifiers ([#575](https://github.com/cbl-dart/cbl-dart/issues/575)). ([672df44c](https://github.com/cbl-dart/cbl-dart/commit/672df44c64374f1b3ad9ebd4d93272ea9a51d856))

#### `cbl_sentry` - `v2.0.0-dev.5`

 - **REFACTOR**: fix analyzer issues. ([846cb48d](https://github.com/cbl-dart/cbl-dart/commit/846cb48d86f7309a7f8a65ecc6be0bb71b7d7254))
 - **BREAKING** **FEAT**(cbl_sentry): add class modifiers ([#569](https://github.com/cbl-dart/cbl-dart/issues/569)). ([a61344c1](https://github.com/cbl-dart/cbl-dart/commit/a61344c1786cc8422d8cff626bedc7309273bf21))


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

