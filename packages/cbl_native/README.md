# cbl_native

Binaries for Couchbase Lite + Dart.

> **Warning:** This is an internal package for [`cbl`](https://github.com/cofu-app/cbl-dart/tree/main/packages/cbl)
and its API should not be considered public.

## Binaries versioning

This package does not contain the actual binaries. Its primary purpose is
to declare dependencies on a version of the binaries. The binaries for a specific released are
attached to a corresponding GitHub release, with a tag such as `cbl_native-v0.1.0`.

A consumer ([`cbl_ffi`](https://github.com/cofu-app/cbl-dart/tree/main/packages/cbl_ffi))
declares a dependency with a version constraint which allows updates for patch and minor releases.

A provider ([`cbl_flutter`](https://github.com/cofu-app/cbl-dart/tree/main/packages/cbl_flutter))
declares a dependency with an exact version constraint.

Constraint resolution, in the package which uses a consumer and provider, will fail if the
versions of `cbl_native` are incompatible.

## Installing binaries

This package contains a command line tool (`bin/binary_url.dart`), which can output
the urls for the binary archives of supported platforms. The tool can also download
and unpack the archives into a specified directory.
