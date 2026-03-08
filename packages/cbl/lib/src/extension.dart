import 'package:meta/meta.dart';

import 'bindings.dart';

final _binding = CBLBindings.instance.base;

/// Status of the vector search extension on the current system.
enum VectorSearchStatus {
  /// Vector search is available and can be enabled.
  available,

  /// Vector search has been enabled.
  enabled,

  /// The vector search extension library was not bundled.
  ///
  /// To include the vector search library, set `vector_search: true` under
  /// `hooks.user_defines.cbl` in `pubspec.yaml`.
  libraryNotAvailable,

  /// The current system does not support vector search.
  ///
  /// Vector search requires a 64-bit architecture. On x86-64, the CPU must
  /// support the AVX2 instruction set.
  systemNotSupported,
}

/// Manage Couchbase Lite extensions.
abstract final class Extension {
  static bool _vectorSearchEnabled = false;

  /// Returns the [VectorSearchStatus] of the vector search extension.
  static VectorSearchStatus get vectorSearchStatus {
    if (_vectorSearchEnabled) {
      return VectorSearchStatus.enabled;
    }
    if (!_binding.vectorSearchLibraryAvailable) {
      return VectorSearchStatus.libraryNotAvailable;
    }
    if (!_binding.systemSupportsVectorSearch) {
      return VectorSearchStatus.systemNotSupported;
    }
    return VectorSearchStatus.available;
  }

  /// Enables the vector search extension.
  ///
  /// Must be called before opening a database that uses vector search.
  ///
  /// Returns the resulting [VectorSearchStatus]. If vector search was
  /// successfully enabled, returns [VectorSearchStatus.enabled]. If the library
  /// is not bundled or the system is unsupported, returns the corresponding
  /// status without throwing.
  ///
  /// Check [vectorSearchStatus] to query the status without attempting to
  /// enable.
  @useResult
  static VectorSearchStatus enableVectorSearch() {
    if (!_binding.vectorSearchLibraryAvailable) {
      return VectorSearchStatus.libraryNotAvailable;
    }
    if (!_binding.systemSupportsVectorSearch) {
      return VectorSearchStatus.systemNotSupported;
    }
    _binding.enableVectorSearch();
    _vectorSearchEnabled = true;
    return VectorSearchStatus.enabled;
  }
}
