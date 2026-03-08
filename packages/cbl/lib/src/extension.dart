import 'package:meta/meta.dart';

import 'bindings.dart';
import 'bindings/cblite_vector_search.dart' as vector_search;

/// Status of the vector search extension on the current system.
enum VectorSearchStatus {
  /// Vector search is available and can be enabled.
  available,

  /// Vector search has been enabled.
  enabled,

  /// The vector search extension library was not bundled.
  ///
  /// To include the vector search library, set `vector_search: true` under
  /// `hooks.user_defines.cbl` in your package `pubspec.yaml`. In a pub
  /// workspace, put that configuration in the workspace root `pubspec.yaml`.
  libraryNotAvailable,

  /// The current system does not support vector search.
  ///
  /// Vector search is supported on ARM64 and x86-64. On x86-64, the CPU must
  /// additionally support the AVX2 instruction set.
  systemNotSupported,
}

/// Manage Couchbase Lite extensions.
abstract final class Extension {
  static bool _vectorSearchEnabled = false;

  /// Returns the [VectorSearchStatus] of the vector search extension.
  ///
  /// Can be called before Couchbase Lite is initialized.
  ///
  /// Throws `DatabaseException` if the vector search library is bundled but its
  /// file path cannot be resolved.
  static VectorSearchStatus get vectorSearchStatus {
    if (_vectorSearchEnabled) {
      return VectorSearchStatus.enabled;
    }
    if (!vector_search.vectorSearchLibraryBundled) {
      return VectorSearchStatus.libraryNotAvailable;
    }
    final _ = vector_search.vectorSearchLibraryPath;
    if (!vector_search.systemSupportsVectorSearch) {
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
  /// Throws `DatabaseException` if the vector search library is bundled but its
  /// file path cannot be resolved.
  ///
  /// Check [vectorSearchStatus] to query the status without attempting to
  /// enable.
  @useResult
  static VectorSearchStatus enableVectorSearch() {
    final status = vectorSearchStatus;
    if (status != VectorSearchStatus.available) {
      return status;
    }
    CBLBindings.instance.base.enableVectorSearch();
    _vectorSearchEnabled = true;
    return VectorSearchStatus.enabled;
  }
}
