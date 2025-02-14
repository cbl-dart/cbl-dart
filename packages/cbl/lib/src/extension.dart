import '../cbl.dart';
import 'bindings.dart';

final _binding = CBLBindings.instance.base;

// ignore: avoid_classes_with_only_static_members
/// Manage Couchbase Lite extensions.
abstract final class Extension {
  /// Enables the vector search extension.
  ///
  /// This function must be called before opening a database that intends to use
  /// the vector search extension.
  ///
  /// If the vector search extension is not available, not supported on the
  /// current system or cannot be enabled for some other reason, an exception is
  /// thrown.
  ///
  /// The various `init` methods implicitly call this function if vector search
  /// is available and supported on the current system. This behavior can be
  /// disabled by setting the `autoEnableVectorSearch` parameter to `false`.
  /// In the future the `autoEnableVectorSearch` parameter will be removed and
  /// this function will have to be called explicitly.
  static void enableVectorSearch() {
    if (!_binding.vectorSearchLibraryAvailable) {
      throw DatabaseException(
        'The vector search extension library is not available.',
        DatabaseErrorCode.unsupported,
      );
    }

    if (!_binding.systemSupportsVectorSearch) {
      throw DatabaseException(
        'The vector search extension is not supported on this system.',
        DatabaseErrorCode.unsupported,
      );
    }

    _binding.enableVectorSearch();
  }
}
