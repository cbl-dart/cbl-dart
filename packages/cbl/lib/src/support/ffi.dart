import 'dart:ffi';

import '../bindings.dart' as bindings;
import 'errors.dart';

/// Convenience accessor for `CBLBindings.instance`, which throws an informative
/// error when used before the bindings are initialized.
final bindings.CBLBindings cblBindings = () {
  final result = bindings.CBLBindings.maybeInstance;
  if (result == null) {
    throwNotInitializedError();
  }
  return result;
}();

/// Configuration of a [DynamicLibrary], which can be used to load the
/// `DynamicLibrary` at a later time.
class LibraryConfiguration {
  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.open].
  ///
  /// If [appendExtension] is `true` (default), the file extension which is used
  /// for dynamic libraries on the current platform is appended to [name].
  LibraryConfiguration.dynamic(
    this.name, {
    this.appendExtension = true,
    this.version,
    this.isAppleFramework = false,
  }) : process = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.process].
  LibraryConfiguration.process()
      : process = true,
        name = null,
        appendExtension = null,
        version = null,
        isAppleFramework = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.executable].
  LibraryConfiguration.executable()
      : process = false,
        name = null,
        appendExtension = null,
        version = null,
        isAppleFramework = null;

  /// `true` if the library is available in the globally visible symbols of the
  /// process.
  final bool? process;

  /// The name of the library.
  final String? name;

  /// Whether to append the platform dependent file extension to [name].
  final bool? appendExtension;

  /// The version to use when building the full library path.
  final String? version;

  /// Whether the library is packaged in an Apple framework .
  final bool? isAppleFramework;
}

/// Configuration for the [DynamicLibrary]s which provide the Couchbase Lite C
/// API and the Dart support layer.
class LibrariesConfiguration {
  /// Creates a configuration for the [DynamicLibrary]s which provide the
  /// Couchbase Lite C API and the Dart support layer.
  LibrariesConfiguration({
    this.enterpriseEdition = false,
    this.directory,
    required this.cbl,
    required this.cblDart,
  });

  /// Whether the provided Couchbase Lite C library is the enterprise edition.
  final bool enterpriseEdition;

  /// The directory in which libraries are located.
  final String? directory;

  /// The configuration for the Couchbase Lite C library.
  final LibraryConfiguration cbl;

  /// The configuration for the Dart support library.
  final LibraryConfiguration cblDart;
}

extension on LibraryConfiguration {
  bindings.LibraryConfiguration _toCblFfi() => bindings.LibraryConfiguration(
        process: process,
        name: name,
        appendExtension: appendExtension,
        version: version,
        isAppleFramework: isAppleFramework,
      );
}

extension CblFfiLibraries on LibrariesConfiguration {
  bindings.LibrariesConfiguration toCblFfi() => bindings.LibrariesConfiguration(
        enterpriseEdition: enterpriseEdition,
        directory: directory,
        cbl: cbl._toCblFfi(),
        cblDart: cblDart._toCblFfi(),
      );
}
