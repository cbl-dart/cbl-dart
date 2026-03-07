import 'dart:ffi';

import 'package:cbl/src/bindings/cblite_vector_search.dart'
    as cblite_vector_search;
import 'package:cbl/src/bindings/cblitedart_native_assets.dart'
    as cblitedart_native;

/// Whether vector search is available on this system.
///
/// This check calls the FFI bindings directly and can be used before
/// CouchbaseLite has been initialized.
bool get vectorSearchAvailable =>
    _vectorSearchLibraryAvailable && _systemSupportsVectorSearch;

bool get _vectorSearchLibraryAvailable {
  try {
    cblite_vector_search.vectorSearchLibraryPath;
    return true;
    // ignore: avoid_catching_errors
  } on ArgumentError {
    return false;
  }
}

bool get _systemSupportsVectorSearch => switch (Abi.current()) {
  Abi.androidArm ||
  Abi.androidArm64 ||
  Abi.iosArm ||
  Abi.iosArm64 ||
  Abi.linuxArm ||
  Abi.linuxArm64 ||
  Abi.macosArm64 ||
  Abi.windowsArm64 => true,
  Abi.linuxX64 ||
  Abi.windowsX64 ||
  Abi.iosX64 ||
  Abi.macosX64 ||
  Abi.androidX64 => cblitedart_native.CBLDart_CpuSupportsAVX2(),
  _ => false,
};
