# Couchbase Lite for Dart based on the C API

# Design

- CBL Api is not thread safe
- Expensive operations should be async, off of the isolate thread
- C Api objects are ref counted and Dart objects should manage those ref counts
- The C Api needs to be able to callback into Dart code, blocking and
  non-blocking, with results
- Callbacks should not have to be static

### TODO

- Couchbase
  - Blobs
  - Replication
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
- Use Opaque for opaque structs
  - CBLDatabase
  - CBLQuery
  - CBLResultSet
  - FLDoc
  - FLValue
  - FLDict
  - FLArray
  - FLMutableDict
  - FLMutableArray
  - .etc
- Ergonomics: Review api for ease of use
- Create flutter plugin cbl_flutter to distribute binaries
- Setup CI
- Docs