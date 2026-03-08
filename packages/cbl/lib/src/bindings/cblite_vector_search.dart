@ffi.DefaultAsset('package:cbl/src/bindings/cblite_vector_search.dart')
library;

import 'dart:ffi' as ffi;

import 'cblitedart_native_assets.dart'
    as cblitedart
    show CBLDart_CpuSupportsAVX2;
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

/// Returns the file path of the vector search extension library, or `null` if
/// the extension is not bundled or the path cannot be resolved.
///
/// Resolves the address of a known symbol back to its containing library path.
String? get vectorSearchLibraryPath {
  if (!vectorSearchLibraryBundled) {
    return null;
  }
  final address = ffi.Native.addressOf<ffi.NativeFunction<ffi.Void Function()>>(
    _extensionEntryPoint,
  ).cast<ffi.Void>();
  return resolveLibraryPathFromAddress(address);
}

/// Whether the vector search extension library is bundled.
///
/// This does not require Couchbase Lite to be initialized.
bool get vectorSearchLibraryBundled {
  try {
    ffi.Native.addressOf<ffi.NativeFunction<ffi.Void Function()>>(
      _extensionEntryPoint,
    );
    return true;
  } on Object {
    return false;
  }
}

/// Whether the current system supports vector search.
///
/// Vector search is supported on ARM64 and x86-64. On x86-64, the CPU must
/// additionally support the AVX2 instruction set. 32-bit ARM and ia32
/// architectures are not supported.
///
/// This does not require Couchbase Lite to be initialized.
bool get systemSupportsVectorSearch => switch (ffi.Abi.current()) {
  ffi.Abi.androidArm64 ||
  ffi.Abi.iosArm64 ||
  ffi.Abi.linuxArm64 ||
  ffi.Abi.macosArm64 ||
  ffi.Abi.windowsArm64 => true,
  ffi.Abi.linuxX64 ||
  ffi.Abi.windowsX64 ||
  ffi.Abi.iosX64 ||
  ffi.Abi.macosX64 ||
  ffi.Abi.androidX64 => cblitedart.CBLDart_CpuSupportsAVX2(),
  _ => false,
};
