import 'dart:io';
import 'package:path/path.dart';

import '../bindings/libraries.dart';
import 'package.dart';

typedef LibraryAssetVersions = ({
  String cblite,
  String cblitedart,
  String? vectorSearch
});

/// Configuration for managing local pre-bundled Couchbase Lite libraries and assets.
///
/// This class handles the configuration and management of platform-specific native
/// libraries that are required for Couchbase Lite to function. It supports different
/// editions (Community/Enterprise) and optional vector search capabilities.
///
/// The configuration manages three main libraries:
/// - cblite: The core Couchbase Lite library
/// - cblitedart: Dart-specific bindings for Couchbase Lite
/// - vector_search: Optional library for vector search capabilities
class LocalAssetsConfiguration {
  /// Creates a new configuration for local Couchbase Lite assets.
  ///
  /// Parameters:
  /// - [binaryDependencies]: Directory containing the platform-specific native libraries
  /// - [edition]: The Couchbase Lite edition (Community/Enterprise) to use
  /// - [skipVectorSearch]: Whether to exclude vector search capabilities (defaults to false)
  LocalAssetsConfiguration(
      {required this.binaryDependencies,
      required this.edition,
      this.skipVectorSearch = false});

  /// Directory containing the platform-specific binary dependencies
  final Directory binaryDependencies;

  /// The edition of Couchbase Lite to use (Community/Enterprise)
  final Edition edition;

  /// Whether to skip loading the vector search library
  final bool skipVectorSearch;

  /// Platform-specific directory name based on the current operating system.
  ///
  /// Returns one of:
  /// - 'macos' for macOS
  /// - 'windows' for Windows
  /// - 'linux' for Linux
  /// Throws [UnsupportedError] for other platforms.
  String get _platformDir => switch (Platform.operatingSystem) {
        'macos' => 'macos',
        'windows' => 'windows',
        'linux' => 'linux',
        _ => throw UnsupportedError('Unsupported platform'),
      };

  /// Full path to the directory containing the platform-specific libraries
  ///
  /// Throws [FileSystemException] if the directory does not exist
  String get localBinaryDependenciesDir {
    final platformPath = join(binaryDependencies.path, _platformDir);
    final directory = Directory(platformPath);

    if (!directory.existsSync()) {
      throw FileSystemException(
          'Platform libraries directory does not exist', platformPath);
    }

    return platformPath;
  }

  /// Converts this configuration into a [LibrariesConfiguration] for library loading.
  ///
  /// This method creates the necessary configuration for loading all required
  /// native libraries, including optional vector search support if enabled.
  LibrariesConfiguration toLibrariesConfiguration() {
    final os = OS.current;

    return LibrariesConfiguration(
      directory: localBinaryDependenciesDir,
      enterpriseEdition: edition == Edition.enterprise,
      cbl: _createLibraryConfig(os, Library.cblite),
      cblDart: _createLibraryConfig(os, Library.cblitedart),
      vectorSearch: skipVectorSearch
          ? null
          : _createLibraryConfig(os, Library.vectorSearch),
    );
  }

  /// Creates a configuration for a specific library based on the OS and library type.
  ///
  /// This method handles special cases for macOS, including:
  /// - Version numbers for dynamic libraries
  /// - Apple Framework handling
  ///
  /// Parameters:
  /// - [os]: The current operating system
  /// - [library]: The specific library to configure
  /// - [versions]: Record containing version information for each library asset i.e. the binary dependencies
  LibraryConfiguration _createLibraryConfig(
    OS os,
    Library library, {
    LibraryAssetVersions versions = (
      cblite: '3',
      cblitedart: '8',
      vectorSearch: null
    ),
  }) {
    final name = library.libraryName(os);
    final isAppleFramework =
        library.appleFrameworkType(os) == AppleFrameworkType.framework;

    // Special version handling for macOS dynamic libraries
    final version = os == OS.macOS && !isAppleFramework
        ? switch (library) {
            Library.cblite => versions.cblite,
            Library.cblitedart => versions.cblitedart,
            Library.vectorSearch => versions.vectorSearch,
          }
        : null;

    return LibraryConfiguration.dynamic(name,
        version: version, isAppleFramework: isAppleFramework);
  }

  /// Resolves the full path to a specific library file.
  ///
  /// Handles platform-specific file extensions and special cases for:
  /// - macOS frameworks and dynamic libraries
  /// - Version-specific library names
  ///
  /// Parameters:
  /// - [config]: The library configuration to resolve
  String _resolveLibraryPath(LibraryConfiguration config) {
    final os = OS.current;
    final extension = switch (os) {
      OS.macOS => '.dylib',
      OS.linux => '.so',
      OS.windows => '.dll',
      _ => throw UnsupportedError('Unsupported platform'),
    };

    final libraryName = config.name!;
    final version = config.version;

    if (config.isAppleFramework ?? false) {
      return join(localBinaryDependenciesDir, '$libraryName.framework',
          'Versions', 'A', libraryName);
    }

    return version == null
        ? join(localBinaryDependenciesDir, '$libraryName$extension')
        : join(localBinaryDependenciesDir, '$libraryName.$version$extension');
  }

  /// Verifies that all required libraries exist in the expected locations.
  ///
  /// This method checks for the presence of:
  /// - Core Couchbase Lite library
  /// - Dart bindings library
  /// - Vector search library (if enabled)
  ///
  /// Throws [StateError] if any required library is missing.
  void verifyLibrariesExist() {
    final os = OS.current;
    final libraryConfigs = [
      _createLibraryConfig(os, Library.cblite),
      _createLibraryConfig(os, Library.cblitedart),
      if (!skipVectorSearch) _createLibraryConfig(os, Library.vectorSearch),
    ];

    for (final config in libraryConfigs) {
      final path = _resolveLibraryPath(config);
      if (!File(path).existsSync()) {
        throw PathNotFoundException(
            path, OSError('Required library not found at: $path', 2));
      }
    }
  }

  /// Resolves the full path for a specific library type.
  ///
  /// This is a convenience method that combines [_createLibraryConfig] and
  /// [_resolveLibraryPath] to get the final path for a specific library.
  ///
  /// Parameters:
  /// - [library]: The type of library to resolve
  String resolveLibraryPath(Library library) {
    final os = OS.current;
    final config = _createLibraryConfig(os, library);
    return _resolveLibraryPath(config);
  }
}
