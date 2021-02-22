[![CI](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cofu-app/cbl-dart/actions/workflows/ci.yaml)

# cbl-dart

This is a mono-repository for the CouchbaseLite Dart API package [cbl](./packages/cbl)
and packages to distribute accompanying binaries.

### TODO

- Couchbase
  - Replicator tests
  - QueryBuilder
- Fleece
  - Data
  - Paths
  - Encoder
  - Review: check that getting collection contents always returns a Value
  - Review: check that setting collection contents allows `Object?`
  - Review: make sure docs are complete
- Remove Slice API wrappers once passing structs by value is possible in Dart FFI
- Add dispose method to bindings classes so that allocated memory for global objects
  can be released.
- Ergonomics: Review api for ease of use
- Docs
  - How to redirect logs to flutter
- cbl_flutter
  - tests