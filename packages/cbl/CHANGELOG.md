## 3.5.0

 - **REFACTOR**: move native assets bridge to `cbl` ([#797](https://github.com/cbl-dart/cbl-dart/issues/797)). ([5ccaeff5](https://github.com/cbl-dart/cbl-dart/commit/5ccaeff552897cdba80508d8ce87ec886811c0f0))
 - **REFACTOR**: make imports of FFI library bindings consistent ([#796](https://github.com/cbl-dart/cbl-dart/issues/796)). ([872c4721](https://github.com/cbl-dart/cbl-dart/commit/872c4721fd07ab8296feecbee297cfcd9ce72c79))
 - **REFACTOR**: make `Bindings` fields final ([#766](https://github.com/cbl-dart/cbl-dart/issues/766)). ([c9a9adb0](https://github.com/cbl-dart/cbl-dart/commit/c9a9adb00d7dba3a1273d0a2c1d0b54d54966c68))
 - **REFACTOR**: remove JSON serialization support in service layer ([#758](https://github.com/cbl-dart/cbl-dart/issues/758)). ([53b5e02a](https://github.com/cbl-dart/cbl-dart/commit/53b5e02a951167f3f35957c7badb2050cea3d022))
 - **REFACTOR**: rename `encodeQueryParameter` to `encodeUnsavedBlobWithData` ([#749](https://github.com/cbl-dart/cbl-dart/issues/749)). ([a4041c96](https://github.com/cbl-dart/cbl-dart/commit/a4041c96440cb9c7776e43bed2f3f88185237036))
 - **FIX**: add `MbedTlsException` ([#788](https://github.com/cbl-dart/cbl-dart/issues/788)). ([ad212254](https://github.com/cbl-dart/cbl-dart/commit/ad2122548e0b3ecde13c1a8fbe7d1d19dcc5dba4))
 - **FEAT**: add `KeyPair.fromExternal` ([#789](https://github.com/cbl-dart/cbl-dart/issues/789)). ([c281ece8](https://github.com/cbl-dart/cbl-dart/commit/c281ece819cc2a5eb153f82b6afa4aaf1110d21e))
 - **FEAT**: add `UrlEndpointListener` and related APIs ([#785](https://github.com/cbl-dart/cbl-dart/issues/785)). ([8914d1d5](https://github.com/cbl-dart/cbl-dart/commit/8914d1d57b053c280c537de75258cb7f8a8ccffb))
 - **FEAT**: add `TlsIdentity` and related APIs ([#774](https://github.com/cbl-dart/cbl-dart/issues/774)). ([8699d364](https://github.com/cbl-dart/cbl-dart/commit/8699d364c9693ea8a08b5b51d36793a62b736950))
 - **FEAT**: upgrade to CBL C SDK 3.2.3 ([#757](https://github.com/cbl-dart/cbl-dart/issues/757)). ([2f3af72e](https://github.com/cbl-dart/cbl-dart/commit/2f3af72e9ca96d804b45a9fa164c3bb42a5e3a8d))
 - **FEAT**: update to CBL C SDK 3.2.2 ([#755](https://github.com/cbl-dart/cbl-dart/issues/755)). ([12ea21fe](https://github.com/cbl-dart/cbl-dart/commit/12ea21fe0778f5043dc11be708dab94d9aa4a311))
 - **FEAT**: make Fleece encoding synchronous ([#438](https://github.com/cbl-dart/cbl-dart/issues/438)). ([d4cb1aea](https://github.com/cbl-dart/cbl-dart/commit/d4cb1aeaf96cdda3edcf1fd3a385e1b279b40ddd))

## 3.4.2+0

## 3.4.2

 - **REFACTOR**: consistently use `getObjectOrThrow` to find objects in `ObjectRegistry` ([#728](https://github.com/cbl-dart/cbl-dart/issues/728)). ([93048046](https://github.com/cbl-dart/cbl-dart/commit/930480466af2431bba88c25dfd4d0e8eb42159bf))
 - **REFACTOR**: remove `_ProxyQueryEarlyFinalizer` ([#731](https://github.com/cbl-dart/cbl-dart/issues/731)). ([1430486b](https://github.com/cbl-dart/cbl-dart/commit/1430486b815f955bf9f3a93978a517985dd6ab6f))
 - **REFACTOR**: stop registering documents with `ProxyDatabase` for clean up ([#729](https://github.com/cbl-dart/cbl-dart/issues/729)). ([22db7f69](https://github.com/cbl-dart/cbl-dart/commit/22db7f69f96f29411416b3c43e0a72fd3755161b))
 - **FIX**: memory leak in `ObjectRegistry` ([#726](https://github.com/cbl-dart/cbl-dart/issues/726)). ([77471b94](https://github.com/cbl-dart/cbl-dart/commit/77471b9460f0879e1af179146c7e5f9c4a868e63))
 - **FIX**: don't finalize deleted `ProxyDatabase` ([#733](https://github.com/cbl-dart/cbl-dart/issues/733)). ([a05868ad](https://github.com/cbl-dart/cbl-dart/commit/a05868ad411d1b762bad1823e9d7ca9f353880fc))
 - **FIX**: don't require completion of release request for proxied object after `Channel` closure ([#732](https://github.com/cbl-dart/cbl-dart/issues/732)). ([566ff3ca](https://github.com/cbl-dart/cbl-dart/commit/566ff3ca1e2354e72c87164e7fda737fd770ad8c))

## 3.4.1

 - **FIX**: ensure `copyDirectoryContents` can overwrite links on all platforms ([#721](https://github.com/cbl-dart/cbl-dart/issues/721)). ([d0127459](https://github.com/cbl-dart/cbl-dart/commit/d0127459e3d5c44da265736367bb6fa45b99f90e))

## 3.4.0

 - **REFACTOR**: disable comments and Dart enums for FFI bindings ([#685](https://github.com/cbl-dart/cbl-dart/issues/685)). ([da30961e](https://github.com/cbl-dart/cbl-dart/commit/da30961eef1c19aaf4c58a31416ad28a3d5721f0))
 - **FIX**: vector search extension library name on Linux ([#703](https://github.com/cbl-dart/cbl-dart/issues/703)). ([81f7d74a](https://github.com/cbl-dart/cbl-dart/commit/81f7d74a076488a956a167f12631bfb91b58bc07))
 - **FIX**: handle negative `DatabaseException.errorPosition` in `toString` ([#700](https://github.com/cbl-dart/cbl-dart/issues/700)). ([6e893d45](https://github.com/cbl-dart/cbl-dart/commit/6e893d45e0564ec2ca7e133869171be166317b0f))
 - **FIX**: handle `kCBLNetErrTLSHandshakeFailed` network error code ([#701](https://github.com/cbl-dart/cbl-dart/issues/701)). ([d6ffaf71](https://github.com/cbl-dart/cbl-dart/commit/d6ffaf710a0c27399718bda39675f97b894dc9d7))
 - **FEAT**: add `Extension.enableVectorSearch` ([#711](https://github.com/cbl-dart/cbl-dart/issues/711)). ([ad14951e](https://github.com/cbl-dart/cbl-dart/commit/ad14951e1ff69afff7d0617a7f442bd2199adaed))

## 3.3.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 3.3.0-dev.5

 - **REFACTOR**: remove `CBLErrorException` ([#681](https://github.com/cbl-dart/cbl-dart/issues/681)). ([41e932dd](https://github.com/cbl-dart/cbl-dart/commit/41e932ddd8b5c50b5a2334e8166423c32abf90a1))
 - **REFACTOR**: represent hand written native enums same as ffigen ([#679](https://github.com/cbl-dart/cbl-dart/issues/679)). ([d9464435](https://github.com/cbl-dart/cbl-dart/commit/d9464435a74bac80a154f9d3d736202904c4174f))
 - **FIX**: error handling for `QueryIndex.beginUpdate` ([#683](https://github.com/cbl-dart/cbl-dart/issues/683)). ([c00da16b](https://github.com/cbl-dart/cbl-dart/commit/c00da16bc8230ed09536d173c49c87e0eedcb210))
 - **FIX**: don't close channel with pending calls ([#677](https://github.com/cbl-dart/cbl-dart/issues/677)). ([1d957d7d](https://github.com/cbl-dart/cbl-dart/commit/1d957d7d3461a2cd47787c5b062e13d4af25e48c))

## 3.3.0-dev.4

 - **FIX**: code sign vector serach library for macOS ([#663](https://github.com/cbl-dart/cbl-dart/issues/663)). ([b3d0c58b](https://github.com/cbl-dart/cbl-dart/commit/b3d0c58bb16daaa9ff4129ebda950058214f6235))

## 3.3.0-dev.3

 - **FEAT**: support updating lazy vector indexes ([#661](https://github.com/cbl-dart/cbl-dart/issues/661)). ([909a21ee](https://github.com/cbl-dart/cbl-dart/commit/909a21eed6648a6fc31eac41494e153f543ce78b))
 - **FEAT**: support creating vector indexs ([#660](https://github.com/cbl-dart/cbl-dart/issues/660)). ([3bb84324](https://github.com/cbl-dart/cbl-dart/commit/3bb84324718bc54e55837d5e85f7771381850cf3))
 - **FEAT**: add support for predictive models ([#645](https://github.com/cbl-dart/cbl-dart/issues/645)). ([1be1949a](https://github.com/cbl-dart/cbl-dart/commit/1be1949a95e317f17044b89680b9de59c75937f0))

## 3.3.0-dev.2

 - **FIX**: for installing native packages use temp dir on same volume ([#659](https://github.com/cbl-dart/cbl-dart/issues/659)). ([ebc9be0c](https://github.com/cbl-dart/cbl-dart/commit/ebc9be0c5c0bc11f76b946f01459582345db1ca4))

## 3.3.0-dev.1

 - **FIX**: invoking `cbl_flutter_install` on Windows ([#656](https://github.com/cbl-dart/cbl-dart/issues/656)). ([d9eaca2b](https://github.com/cbl-dart/cbl-dart/commit/d9eaca2be3b69eee525d9896e31ace19ff1a90ca))

## 3.3.0-dev.0

 - **REFACTOR**: remove duplication of Librarie(s)Configuration classes ([#642](https://github.com/cbl-dart/cbl-dart/issues/642)). ([9be1b59e](https://github.com/cbl-dart/cbl-dart/commit/9be1b59e9f105797b79082e79d46f4801e9dcbc9))
 - **REFACTOR**: remove cblBindings in favor of CBLBindings.instance ([#641](https://github.com/cbl-dart/cbl-dart/issues/641)). ([776eb700](https://github.com/cbl-dart/cbl-dart/commit/776eb700c122b3c12d4573a91106170027dd0ca2))
 - **REFACTOR**: make native library install code more flexible ([#640](https://github.com/cbl-dart/cbl-dart/issues/640)). ([7c54b0dc](https://github.com/cbl-dart/cbl-dart/commit/7c54b0dca40f42adc224da23406b21eabba32e12))
 - **REFACTOR**: use ffigen to generate bindings ([#633](https://github.com/cbl-dart/cbl-dart/issues/633)). ([900bd3ca](https://github.com/cbl-dart/cbl-dart/commit/900bd3cadeb3b9e059f91ce717bc7e9afd7c871a))
 - **FEAT**: support typed documents in collections ([#650](https://github.com/cbl-dart/cbl-dart/issues/650)). ([d6a20e52](https://github.com/cbl-dart/cbl-dart/commit/d6a20e5235493c9e841dfea395d6f7863c0c6ea1))
 - **FEAT**: enable vector search extension for enterprise edition ([#644](https://github.com/cbl-dart/cbl-dart/issues/644)). ([2949651b](https://github.com/cbl-dart/cbl-dart/commit/2949651b2d7aed8663e2fbf7768d889acce05e4a))
 - **FEAT**: use Dart for native libraries install script ([#639](https://github.com/cbl-dart/cbl-dart/issues/639)). ([40c70c71](https://github.com/cbl-dart/cbl-dart/commit/40c70c716361368481537c718c5459ef983136f6))
 - **FEAT**: add `DatabaseConfiguration.fullSync` ([#637](https://github.com/cbl-dart/cbl-dart/issues/637)). ([7f5341b1](https://github.com/cbl-dart/cbl-dart/commit/7f5341b1e3330d7c42082f6f0890c34ed9090180))

## 3.2.1

 - **FIX**: translate errors when setting file logging config ([#623](https://github.com/cbl-dart/cbl-dart/issues/623)). ([1b646e3f](https://github.com/cbl-dart/cbl-dart/commit/1b646e3f31bfe2f719bef811bc690f2b17e2f195))

## 3.2.0

 - **FEAT**: loosen version constraint for `web_socket_channel` to allow `>=2.1.0 <4.0.0` ([#616](https://github.com/cbl-dart/cbl-dart/issues/616)). ([de572588](https://github.com/cbl-dart/cbl-dart/commit/de5725889e5c057bfa729635f886fa403254dcc4))

## 3.1.1

 - **REFACTOR**: use `nonNulls` instead of `whereNotNull` ([#607](https://github.com/cbl-dart/cbl-dart/issues/607)). ([d1f87210](https://github.com/cbl-dart/cbl-dart/commit/d1f872106ba32f62772d91734a8bab1e3a6b7e0e))

## 3.1.0

 - **FEAT**: use `asUnmodifiableView` instead of `UnmodifiableUint8ListView` ([#599](https://github.com/cbl-dart/cbl-dart/issues/599)). ([3ca65118](https://github.com/cbl-dart/cbl-dart/commit/3ca65118d803966004eca6d37faded9221d6dfe1))

## 3.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 3.0.0-dev.5

> Note: This release has breaking changes.

 - **DOCS**: use collections in README code example. ([ba25ffe2](https://github.com/cbl-dart/cbl-dart/commit/ba25ffe2fc408859ce61db34a6e9bbe6737cbec6))
 - **BREAKING** **FEAT**: replace `Query.from*` with `Database.createQuery` ([#580](https://github.com/cbl-dart/cbl-dart/issues/580)). ([aa104e25](https://github.com/cbl-dart/cbl-dart/commit/aa104e251c74c8487ccbaaa99c2b6ef03e60c3d7))

## 3.0.0-dev.4

> Note: This release has breaking changes.

 - **REFACTOR**: fix analyzer issues. ([846cb48d](https://github.com/cbl-dart/cbl-dart/commit/846cb48d86f7309a7f8a65ecc6be0bb71b7d7254))
 - **REFACTOR**: merge `cbl_ffi` into `cbl` ([#554](https://github.com/cbl-dart/cbl-dart/issues/554)). ([08039cff](https://github.com/cbl-dart/cbl-dart/commit/08039cff6e1328b88098af34884f4861f94cb7a5))
 - **BREAKING** **FEAT**(cbl): add class modifiers ([#575](https://github.com/cbl-dart/cbl-dart/issues/575)). ([672df44c](https://github.com/cbl-dart/cbl-dart/commit/672df44c64374f1b3ad9ebd4d93272ea9a51d856))

## 3.0.0-dev.3

> Note: This release has breaking changes.

 - **FIX**: check in `SerializationRegistry._addCodec` ([#547](https://github.com/cbl-dart/cbl-dart/issues/547)). ([414ef9ed](https://github.com/cbl-dart/cbl-dart/commit/414ef9ed706dfbfca1da06f1a371a095a0ef373e))
 - **BREAKING** **FEAT**: remove `DartConsoleLogger` and stop initializing `Database.log.custom` with it ([#553](https://github.com/cbl-dart/cbl-dart/issues/553)). ([28350a28](https://github.com/cbl-dart/cbl-dart/commit/28350a2835ca14f8774e4e3282a7e0d2bcf7f389))

## 3.0.0-dev.2

 - **FIX**: workaround Dart bug when destructuring record containing `Finalizable` ([#546](https://github.com/cbl-dart/cbl-dart/issues/546)). ([a68456e9](https://github.com/cbl-dart/cbl-dart/commit/a68456e95d970c9e9344f73b7c88815233750dfe))

## 3.0.0-dev.1

 - Update a dependency to the latest release.

## 3.0.0-dev.0

> Note: This release has breaking changes.

 - **FEAT**: add support for collections ([#501](https://github.com/cbl-dart/cbl-dart/issues/501)). ([3f24f234](https://github.com/cbl-dart/cbl-dart/commit/3f24f234726ea248bc4d63808c26ebb7a4e7469b))
 - **BREAKING** **FEAT**: require Dart 3 ([#518](https://github.com/cbl-dart/cbl-dart/issues/518)). ([c653802d](https://github.com/cbl-dart/cbl-dart/commit/c653802dfb69ebbe769b08e9aaeb1cfb906c4dac))

## 2.2.2

 - **FIX**: don't assume `CouchbaseLiteException.code` is `Enum` in `toString` ([#513](https://github.com/cbl-dart/cbl-dart/issues/513)). ([61cef968](https://github.com/cbl-dart/cbl-dart/commit/61cef968d80b23aebdf84db2ecb5c040588e3c73))
 - **FIX**: end transactions exactly once ([#514](https://github.com/cbl-dart/cbl-dart/issues/514)). ([f1f40792](https://github.com/cbl-dart/cbl-dart/commit/f1f40792f4dc59c59bd4dc7d02d81ea41263174d))

## 2.2.1

 - Update a dependency to the latest release.

## 2.2.0

 - **FIX**: compare against correct enum type. ([7e06af5b](https://github.com/cbl-dart/cbl-dart/commit/7e06af5b980acb44a7298300bff3d3027ab97fb0))
 - **FEAT**: add `PosixException`, `SQLiteException` and `FleeceException` ([#488](https://github.com/cbl-dart/cbl-dart/issues/488)). ([892db2ed](https://github.com/cbl-dart/cbl-dart/commit/892db2ed40b01bb7737da8f8c99f5a3e7e23f6fe))

## 2.1.9

 - Update a dependency to the latest release.

## 2.1.8

 - Update a dependency to the latest release.

## 2.1.7

 - **FIX**: prevent deadlock when starting replicator during transaction ([#470](https://github.com/cbl-dart/cbl-dart/issues/470)). ([f1427529](https://github.com/cbl-dart/cbl-dart/commit/f1427529854dbe0065083629a76f3489369dc824))

## 2.1.6

 - **FIX**: use `runWithErrorTranslation` when calling `initializeNativeLibraries`. ([05499efe](https://github.com/cbl-dart/cbl-dart/commit/05499efebc4cf25747c5021780aa4808b52d86f5))

## 2.1.5

 - **FIX**: ensure compatibility with Dart 2.19 ([#457](https://github.com/cbl-dart/cbl-dart/issues/457)). ([caf9bc90](https://github.com/cbl-dart/cbl-dart/commit/caf9bc9050cef56fecc1231bbf18637dd17a4ae8))

## 2.1.4

 - **FIX**: return merged document from conflict resolver ([#454](https://github.com/cbl-dart/cbl-dart/issues/454)). ([cb5deac8](https://github.com/cbl-dart/cbl-dart/commit/cb5deac875d7d507796f76a40d19debc35dd31de))

## 2.1.3

 - **FIX**: don't require trailing path separator when copying databases ([#448](https://github.com/cbl-dart/cbl-dart/issues/448)). ([c027cc73](https://github.com/cbl-dart/cbl-dart/commit/c027cc73662bfdb48e6c78fd105ac75635cc7a08))
 - **FIX**: memory leak in `DocBindings.bindToDartObject` ([#447](https://github.com/cbl-dart/cbl-dart/issues/447)). ([a306facd](https://github.com/cbl-dart/cbl-dart/commit/a306facd5724749bface634d53cef7bae502aab2))

## 2.1.2

 - **DOCS**: fix typo. ([16d1eb3d](https://github.com/cbl-dart/cbl-dart/commit/16d1eb3da10e6228f5d55d2db08061e754e5c2d4))

## 2.1.1

 - **DOCS**: link to new docs website from package READMEs. ([fae73bb2](https://github.com/cbl-dart/cbl-dart/commit/fae73bb2983cde0347091225fa245d2b066be13a))

## 2.1.0

 - **REFACTOR**: use `NativeFinalizer` ([#406](https://github.com/cbl-dart/cbl-dart/issues/406)). ([e7a259ea](https://github.com/cbl-dart/cbl-dart/commit/e7a259ea5c18335f9efe98e415b04dab3d487917))
 - **REFACTOR**: use `Finalizable` to ensure native resources stay alive ([#377](https://github.com/cbl-dart/cbl-dart/issues/377)). ([2b961411](https://github.com/cbl-dart/cbl-dart/commit/2b961411fecdce387b14acc9da737803d14fa5ab))
 - **PERF**: optimize sending `Channel` messages in isolates ([#389](https://github.com/cbl-dart/cbl-dart/issues/389)). ([e1ef25c9](https://github.com/cbl-dart/cbl-dart/commit/e1ef25c98719cd007fbf44ddf21aab8c65e88265))
 - **FIX**: add locking for a number of finalizers ([#412](https://github.com/cbl-dart/cbl-dart/issues/412)). ([55bc3a55](https://github.com/cbl-dart/cbl-dart/commit/55bc3a55798bedfa8f1fe803f8e34bff3068e7a5))
 - **FEAT**: add `ReplicatorConfiguration.trustedRootCertificates` ([#411](https://github.com/cbl-dart/cbl-dart/issues/411)). ([f58fa346](https://github.com/cbl-dart/cbl-dart/commit/f58fa346341a7ae737c782ee659c29277745a66f))

## 2.0.0+0

 - **DOCS**: add Lotum as sponsor. ([2b881cfa](https://github.com/cbl-dart/cbl-dart/commit/2b881cfaf8a526e55a854e3982f5f051fe05b4ef))

## 2.0.0

> Note: This release has breaking changes.

 - **REFACTOR**: enable more lint rules ([#376](https://github.com/cbl-dart/cbl-dart/issues/376)). ([69a6423f](https://github.com/cbl-dart/cbl-dart/commit/69a6423fd518ac11ff485ac8fea7608176c9b272))
 - **REFACTOR**: use super parameters ([#374](https://github.com/cbl-dart/cbl-dart/issues/374)). ([d35feaf0](https://github.com/cbl-dart/cbl-dart/commit/d35feaf04039b1ae7629623f4e1cf4184f22de8a))
 - **REFACTOR**: use `Finalizer` for finalizing `ProxyObject` ([#368](https://github.com/cbl-dart/cbl-dart/issues/368)). ([a10bfb94](https://github.com/cbl-dart/cbl-dart/commit/a10bfb9424c699501ce882f4daa06bfb9e08231d))
 - **DOCS**: remove broken license badge. ([408463ab](https://github.com/cbl-dart/cbl-dart/commit/408463abfd64dc6dabecfbe7d6ce99c9f014df28))
 - **DOCS**: reformat comments with daco ([#385](https://github.com/cbl-dart/cbl-dart/issues/385)). ([e692a51b](https://github.com/cbl-dart/cbl-dart/commit/e692a51b2ae2f9d4a7d240175e5b3c22fb79c783))
 - **DOCS**: fix a few spelling mistakes. ([9404ae77](https://github.com/cbl-dart/cbl-dart/commit/9404ae77dc7bb83d4899aaabf813198ede0af7b7))
 - **BREAKING** **FEAT**: require Flutter `3.0.0` and Dart `2.17.0` ([#366](https://github.com/cbl-dart/cbl-dart/issues/366)). ([480912b6](https://github.com/cbl-dart/cbl-dart/commit/480912b617cb92cda7879d01ad4a0a3ea5b61abe))

## 1.2.0

 - **REFACTOR**: use stricter types for collections in `ObjectRegistry`. ([e71851a5](https://github.com/cbl-dart/cbl-dart/commit/e71851a59278deda3776bfedabe23e7ed42b7e23))
 - **PERF**: optimize `IsolatePacketCodec.decodePacket`. ([e01e1978](https://github.com/cbl-dart/cbl-dart/commit/e01e1978b89976cea5e4d3581da20e4fc96c3919))
 - **PERF**: use collections which are more efficient for the task. ([0c33c132](https://github.com/cbl-dart/cbl-dart/commit/0c33c13271526476f67218b41e1d49718611ebf2))
 - **FIX**: conversions in `EncodedData` (#360). ([58240ee2](https://github.com/cbl-dart/cbl-dart/commit/58240ee2d3c6a205bde26f0d9c460276eed5e680))
 - **FIX**: don't coerce `null` to `false` in `value<bool>` getter (#357). ([24427550](https://github.com/cbl-dart/cbl-dart/commit/244275507a14adf590e5fbb8321a21b3e3d05fa4))
 - **FEAT**: add experimental support for typed data (#359). ([2c9a7d9e](https://github.com/cbl-dart/cbl-dart/commit/2c9a7d9ea94e50ad96354c785ce62d6a437b34bd))
 - **FEAT**: support sharing collections with multiple documents (#361). ([b3e5d12a](https://github.com/cbl-dart/cbl-dart/commit/b3e5d12a034562709e09b65df7469a3ba5ff3660))

## 1.1.3

 - **FIX**: translate exceptions when creating replicator endpoint with URL (#352). ([c2974f94](https://github.com/cbl-dart/cbl-dart/commit/c2974f9447f75cc827ebc1aa1a229293b7f6156e))
 - **FIX**: ensure proxied document can be resolved when saving (#351). ([c8f08dfe](https://github.com/cbl-dart/cbl-dart/commit/c8f08dfe8e2a314bfb5d2884c2a337d17c1b76a8))

## 1.1.2

 - **FIX**: resolve proxied document correctly when deleting it (#348). ([5113d194](https://github.com/cbl-dart/cbl-dart/commit/5113d1941b88ffa5528a4fc4d45ae8252aede87e))

## 1.1.1

 - **FIX**: rethrow exceptions with original stack trace (#345). ([af93a892](https://github.com/cbl-dart/cbl-dart/commit/af93a892badb969f0ece597a57073b393d3f3526))

## 1.1.0

 - **PERF**: keep proxied documents in memory (#340). ([c4330975](https://github.com/cbl-dart/cbl-dart/commit/c4330975d1a1b13a9137466ad77824ce79b09eb7))
 - **FIX**: make expected reachability of all finalized objects explicit (#341). ([d39f291f](https://github.com/cbl-dart/cbl-dart/commit/d39f291f48fc8fb22f5b8ce2b0056556e0a03e2c))
 - **FEAT**: include stack trace in message for unserializable error. ([76f3bece](https://github.com/cbl-dart/cbl-dart/commit/76f3bece71c405fcf271cda449dd955797076a6c))

## 1.0.5

 - **FIX**: temporarily disable use of `FLDictKey`. ([2c729e12](https://github.com/cbl-dart/cbl-dart/commit/2c729e12506030ac8da2f843776bee57b8f69793))

## 1.0.4

 - **FIX**: keep `AsyncCallback` reachable in `close` (#333). ([206950ca](https://github.com/cbl-dart/cbl-dart/commit/206950caa95c50652d66c7351bd4f3ece16ec40d))
 - **FIX**: use own instance of `DictKeys` for each `ResultSet` (#331). ([a0090af7](https://github.com/cbl-dart/cbl-dart/commit/a0090af7a0b252045f8106affd8e20cd99e7721d))

## 1.0.3

 - **FIX**: don't use a `SharedStringsTable` in `ResultSet` (#327). ([eee1e3e6](https://github.com/cbl-dart/cbl-dart/commit/eee1e3e6d866dfd717c605e8618c283e860a16ae))

## 1.0.2

 - **DOCS**: add "Prior work" section to README. ([4f37be01](https://github.com/cbl-dart/cbl-dart/commit/4f37be01c1849cbbe36c79a19a62609619099124))

## 1.0.1+0

 - **DOCS**: update indroduction. ([9e2a578a](https://github.com/cbl-dart/cbl-dart/commit/9e2a578a11115b9e5be67bd57b844e9e72622361))
 - **DOCS**: add contact section. ([240a4add](https://github.com/cbl-dart/cbl-dart/commit/240a4add826e3271eeff306b6dc102d27dae815a))

## 1.0.1

 - **FIX**: use own `SharedKeysTable` for each `ResultSet` (#323). ([8357eb1c](https://github.com/cbl-dart/cbl-dart/commit/8357eb1cc6e9e208eda2ab7fd737980e7a3b0835))

## 1.0.0+1

 - **DOCS**: fix links in READMEs. ([ae73cde4](https://github.com/cbl-dart/cbl-dart/commit/ae73cde46fdcbb204257ea2044cfa71479b13d46))

## 1.0.0+0

 - **DOCS**: update README. ([3dd3aaff](https://github.com/cbl-dart/cbl-dart/commit/3dd3aaffdabe735e4c1deeb3dac28a56241b3d78))

## 1.0.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 1.0.0-beta.15

> Note: This release has breaking changes.

 - **BREAKING** **FEAT**: upgrade to Dart `2.16.0` and Flutter `2.10.0` (#290). ([5d8d0829](https://github.com/cbl-dart/cbl-dart/commit/5d8d082967f8a13b47df788fda42bd0ef54d6def))

## 1.0.0-beta.14

> Note: This release has breaking changes.

 - **FEAT**: eagerly execute query in `ProxyQuery.execute`. ([21139ed6](https://github.com/cbl-dart/cbl-dart/commit/21139ed67ae857e360dd56a0818f0f815a88ec86))
 - **FEAT**: add `DevToolsTracing` `TracingDelegate` (#278). ([fbc8ecb8](https://github.com/cbl-dart/cbl-dart/commit/fbc8ecb861683b3d63f180f5b314065df907bffe))
 - **DOCS**: add **Tracing** section to README. ([bbef3cd0](https://github.com/cbl-dart/cbl-dart/commit/bbef3cd0b82e07a22c21adc5caef38172fa831ab))
 - **DOCS**: document more clearly when to use each package. ([9156c459](https://github.com/cbl-dart/cbl-dart/commit/9156c45930eda98fda552f92897ebecee4c07bdd))
 - **BREAKING** **FEAT**: revise tracing API. ([093003f2](https://github.com/cbl-dart/cbl-dart/commit/093003f27e2e5920c6e4a59c8402bf7942b42021))
 - **BREAKING** **FEAT**: revise tracing API (#276). ([22c2b5b6](https://github.com/cbl-dart/cbl-dart/commit/22c2b5b6113f72970bdc26f0123486f8b13d1f24))

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