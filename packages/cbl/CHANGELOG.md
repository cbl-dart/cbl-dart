## 0.5.0

> Note: This release has breaking changes.

 - **TEST**: add tests for `Replicator`.
 - **REFACTOR**: use extensions for enum conversion.
 - **FIX**: use correct size for `FleeceErrorCode`.
 - **FIX**: fix `hashCode`s of multiple classes.
 - **FIX**: properly handle cancelation of `NativeCallback` streams.
 - **FIX**: fix `Replicator` config options `pullFilter` and `documentIDs`.
 - **FEAT**: add `Resource` abstraction.
 - **BREAKING** **FEAT**: add `Database.performMaintenance`.
 - **BREAKING** **FEAT**: represent uncompiled queries as `QueryDefinition`.
 - **BREAKING** **FEAT**: `Replicator` API change.

## 0.4.1+1

 - **REFACTOR**: replace `Void` with opaque structs.
 - **FIX**: fix `Replicator` conflict resolver callback.

## 0.4.1

 - **FEAT**: highlight error position in query parsing exception.
 - **CHORE**: publish packages.

## 0.4.0

> Note: This release has breaking changes.

 - **REFACTOR**: migrate to new native callback API.
 - **BREAKING** **FEAT**: improve `CouchbaseLite` and `Database` APIs.

## 0.3.0+1

 - **STYLE**: fix formatting.
 - **DOCS**: add example.

## 0.3.0

> Note: This release has breaking changes.

 - **FIX**: actually store callback in `set logCallback`.
 - **FEAT**: add `Document.revisionId`.
 - **FEAT**: make `SessionAuthenticator.cookieName` nullable.
 - **DOCS**: add docs to a few properties.
 - **DOCS**: fix wording.
 - **BREAKING** **FEAT**: new Stream API for logging.

## 0.2.1

 - **FEAT**: include database name in worker id.
 - **DOCS**: add list of features to README.

## 0.2.0

> Note: This release has breaking changes.

 - **DOCS**: fix spelling.
 - **BREAKING** **FIX**: fix name of `LogLevelExt.toLoggingLevel`.

## 0.1.0

- Initial release.
