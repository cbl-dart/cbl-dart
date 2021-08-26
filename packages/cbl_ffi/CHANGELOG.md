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
