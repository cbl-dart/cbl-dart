@ffi.DefaultAsset('package:cbl/src/bindings/cblite_vector_search.dart')
library;

import 'dart:ffi' as ffi;

import 'libraries.dart';

/// A known symbol from the vector search extension library.
///
/// This is used to discover the library path at runtime via
/// [vectorSearchLibraryPath]. The `@Native` annotation is resolved lazily, so
/// if the vector search extension is not bundled, no error occurs unless this
/// symbol is actually accessed.
@ffi.Native<ffi.Void Function()>(
  symbol: 'sqlite3_couchbaselitevectorsearch_init',
)
external void _extensionEntryPoint();

/// Returns the file path of the vector search extension library.
///
/// Resolves the address of a known symbol back to its containing library path.
String get vectorSearchLibraryPath {
  final address = ffi.Native.addressOf<ffi.NativeFunction<ffi.Void Function()>>(
    _extensionEntryPoint,
  ).cast<ffi.Void>();
  return resolveLibraryPathFromAddress(address);
}
