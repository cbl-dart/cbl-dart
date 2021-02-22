# cbl_native

Binaries for CouchbaseLite + Dart.

This package does not contain the actual binaries. It's primary purpose is
to declare dependencies on a version of the binaries. The binaries for a specific released are 
attached to a corresponding GitHub release, with a tag such as `cbl_native-v0.1.0`.

A consumers ([`cbl_ffi`](../cbl_ffi)) declares a dependency with a
version constraint which allows updates for patch and minor releases.

A provider ([`cbl_flutter`](../cbl_flutter)) declares a dependency with an exact version constraint.

Constraint resolution, in the package which uses a consumer and provider, will fail if the
versions of `cbl_native` are incompatible.
