## 1.0.0-beta.13

 - **FEAT**: make source N1QL query string available on `Query`. ([a0321727](https://github.com/cbl-dart/cbl-dart/commit/a032172773016ccf30742531828edb8f0ba6fc83))
 - **FEAT**: make remote stack traces available separately instead of throwing with them. ([cfce0de8](https://github.com/cbl-dart/cbl-dart/commit/cfce0de8d3fd07b4db05ab256895b07cd6b9e9b4))
 - **FEAT**: tracing API (#269). ([4c06a977](https://github.com/cbl-dart/cbl-dart/commit/4c06a9772b6026b9e03327e18bb0957a53d28524))

## 1.0.0-beta.12

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: Add `Database.saveBlob` and `Database.getBlob` (#256). ([ec5d1931](https://github.com/cbl-dart/cbl-dart/commit/ec5d1931a65e5dc569c9e5f8da26a5235afdd4f8))

## 1.0.0-beta.11

 - **REFACTOR**: improve coverage (#241). ([a5de00d9](https://github.com/cbl-dart/cbl-dart/commit/a5de00d97ff3b93baab9e373bd70a007bb11dd3e))
 - **FIX**: allow isolate to exit when database is closed (#239). ([8c481d8b](https://github.com/cbl-dart/cbl-dart/commit/8c481d8b61fd02f9a4a14ec0e0a521a5c0429946))
 - **FEAT**: improve native libraries configuration (#247). ([619ca82c](https://github.com/cbl-dart/cbl-dart/commit/619ca82cd8a239dbd90bb37dd00802d0ed53ade0))
 - **FEAT**: throw uncaught exceptions from worker in main isolate. ([9629c8f0](https://github.com/cbl-dart/cbl-dart/commit/9629c8f065cf55b2c5674445bddb0b5bc7de6120))
 - **DOCS**: fix macros in doc comments (#240). ([90232580](https://github.com/cbl-dart/cbl-dart/commit/9023258070e2aa7da2c8c2e7c62f4fc12effa00a))

## 1.0.0-beta.10

 - **FIX**: use current working dir for default database dir (#236). ([a0526a94](https://github.com/cbl-dart/cbl-dart/commit/a0526a94b7b6f1e72863a0ec16a1f4980742f0da))
 - **FEAT**: add `cbl_dart` package (#230). ([09f3da5e](https://github.com/cbl-dart/cbl-dart/commit/09f3da5eef02b2d0543f0653f83676a24648ccd9))

## 1.0.0-beta.9

 - **FIX**: use different `MContext` for every `Result` in `ProxyResultSet` (#228). ([0810e184](https://github.com/cbl-dart/cbl-dart/commit/0810e184488d7cd4801656288e74b66402137d49))
 - **FIX**: ensure query is prepared by listening to `changes` stream (#226). ([887c0d89](https://github.com/cbl-dart/cbl-dart/commit/887c0d89198e70b486f13b6944b22fd2ddda573e))

## 1.0.0-beta.8

 - **REFACTOR**: clean up throwing errors (#219). ([76871d11](https://github.com/cbl-dart/cbl-dart/commit/76871d112ed13a541bfc589c6b60a0decf583f0a))
 - **FIX**: allow `==` and `hashCode` for unsaved blobs (#222). ([cb8fab2e](https://github.com/cbl-dart/cbl-dart/commit/cb8fab2e583324d7bfaaab9bc9df2a36a20eb670))
 - **FIX**: correctly update nested collections in documents (#223). ([60f3fd23](https://github.com/cbl-dart/cbl-dart/commit/60f3fd23e333512e66af6997ff8a2806d866d52a))
 - **FEAT**: clear up semantics of closing of resources. ([226397f3](https://github.com/cbl-dart/cbl-dart/commit/226397f3bcd88d606045c87f811b0df5f20eaff1))
 - **FEAT**: add support for database encryption (#213). ([a92b9e45](https://github.com/cbl-dart/cbl-dart/commit/a92b9e4590e3424ff8d32914cc73d1ec6a1164bb))
 - **FEAT**: add `DatabaseEndpoint` for local replication (#212). ([95274353](https://github.com/cbl-dart/cbl-dart/commit/952743535a55f48592e4542faa1eea9689cd2680))
 - **DOCS**: update formatting of READMEs. ([46da1b0a](https://github.com/cbl-dart/cbl-dart/commit/46da1b0a9ad6dd887afc77c960f41e1e2e162e1a))
 - **DOCS**: expand README. ([7ba2b701](https://github.com/cbl-dart/cbl-dart/commit/7ba2b701b06bde5bd4befb1f0f42e003a29ef53f))
 - **DOCS**: document categories of API elements. ([00b00637](https://github.com/cbl-dart/cbl-dart/commit/00b00637fce5ae9a2fa50747e3a9ab4eb6cb332e))

## 1.0.0-beta.7

> Note: This release has breaking changes.

 - **TEST**: add more tests to improve coverage (#209). ([875639f3](https://github.com/cbl-dart/cbl-dart/commit/875639f3068655272390490a8ff8096cc425898c))
 - **TEST**: run async API tests in main and worker isolate (#208). ([b2966b79](https://github.com/cbl-dart/cbl-dart/commit/b2966b79df221f38350e98c56ee718797c804c15))
 - **STYLE**: fix incorrect spelling and formatting. ([8fb20de8](https://github.com/cbl-dart/cbl-dart/commit/8fb20de8900f27cdcd67b7180390cb04a41ca058))
 - **FEAT**: make `Channel` streams pausable. ([14539977](https://github.com/cbl-dart/cbl-dart/commit/14539977ffc1134f6dfca952b65dd48a48c8ba99))
 - **FEAT**: revise some replicator config options. ([df7ac561](https://github.com/cbl-dart/cbl-dart/commit/df7ac5615e008bc1e9aacab9d0b6d5b4c1f6e6ae))
 - **FEAT**: add `enableAutoPurge` replicator option. ([3d574d26](https://github.com/cbl-dart/cbl-dart/commit/3d574d26f9404ab91b1556192a17e24abef58ad0))
 - **FEAT**: downgrade iOS + macOS minimum deployment targets. ([d932dbd8](https://github.com/cbl-dart/cbl-dart/commit/d932dbd87496e350559aa3dc1672b71a665e2421))
 - **DOCS**: update README. ([d82d6369](https://github.com/cbl-dart/cbl-dart/commit/d82d636943bd3ffce03fab48bb123005af076a71))
 - **BREAKING** **FEAT**: add listener based observer API (#205). ([e67859b2](https://github.com/cbl-dart/cbl-dart/commit/e67859b2bc6333395e86f3ad640ae5a07a742ad7))

## 1.0.0-beta.6

 - **FIX**: make accidentally exported functions private
 - **CHORE**: Update dependency

## 1.0.0-beta.5

 - **FIX**: initialize native libraries exactly once (#176).
 - **FIX**: register controller of `Channel` stream when listened to (#171).
 - **FEAT**: return mutable copies from `toMutable` methods (#178).
 - **FEAT**: use consistent database default directory for Flutter (#177).

## 1.0.0-beta.4

 - **FIX**: allow `ConflictResolver` to be extended.
 - **FEAT**: add support for Linux + Flutter.
 - **FEAT**: `CblWorker` isolate debug name.
 - **FEAT**: add `toJson` methods to containers (#167).
 - **FEAT**: allocate global memory in `SliceResult`.
 - **FEAT**: make `FleeceEncoder` a `NativeObject` (#166).
 - **FEAT**: add initializer for secondary isolate.

## 1.0.0-beta.3

 - Bump "cbl" to `1.0.0-beta.3`.

## 1.0.0-beta.2

 - Bump "cbl" to `1.0.0-beta.2`.

## 0.6.0

> Note: This release has breaking changes.

 - **REFACTOR**: use `FLResultSlice`.
 - **FIX**: fix assert in `FleeceRefCountedObject`.
 - **FEAT**: migrate to `Arena` from `ffi` package (#60).
 - **FEAT**: add support for Fleece data `Value`s.
 - **BREAKING** **REFACTOR**: convert between native and Dart types in `cbl_ffi`.
 - **BREAKING** **FEAT**: rename `DocumentFalgs` to `ReplicatedDocumentFlag`.
 - **BREAKING** **FEAT**: consistently use `id` instead of `ID`.
 - **BREAKING** **FEAT**: make `Value.asString` and `Query.columnName` nullable.

## 0.5.1

 - **FEAT**: retain `Document.properties`.
 - **FEAT**: Update dependencies.
 - **DOCS**: mention minimum platform targets.

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