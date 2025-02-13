import 'dart:io';
import 'package:path/path.dart';

import '../bindings/libraries.dart';
import 'package.dart';

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
  LocalAssetsConfiguration({
    required this.binaryDependencies,
    required this.edition,
    this.skipVectorSearch = false,
  });

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

  /// Platform-specific hash used to identify the correct binary version.
  ///
  /// These hashes ensure the correct binary version is loaded for each platform.
  /// They are used to create unique paths for storing platform-specific libraries.
  String get _platformHash => switch (Platform.operatingSystem) {
        'macos' => 'c4f61c9bde1085be63f32dd54ca8829e',
        'windows' => 'c2ddf39c36bd6ab58d86b27ddc102286',
        'linux' => '6af4f73a0a0e59cb7e1a272a9fa0828a',
        _ => throw UnsupportedError('Unsupported platform'),
      };

  /// Full path to the directory containing the platform-specific libraries
  String get librariesPath => join(binaryDependencies.path, _platformDir, _platformHash);

  /// Converts this configuration into a [LibrariesConfiguration] for library loading.
  ///
  /// This method creates the necessary configuration for loading all required
  /// native libraries, including optional vector search support if enabled.
  LibrariesConfiguration toLibrariesConfiguration() {
    final os = OS.current;

    return LibrariesConfiguration(
      directory: librariesPath,
      enterpriseEdition: edition == Edition.enterprise,
      cbl: _createLibraryConfig(os, Library.cblite),
      cblDart: _createLibraryConfig(os, Library.cblitedart),
      vectorSearch: skipVectorSearch ? null : _createLibraryConfig(os, Library.vectorSearch),
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
  LibraryConfiguration _createLibraryConfig(OS os, Library library) {
    final name = library.libraryName(os);
    final isAppleFramework = library.appleFrameworkType(os) == AppleFrameworkType.framework;

    // Special version handling for macOS dynamic libraries
    final version = os == OS.macOS && !isAppleFramework
        ? switch (library) {
            Library.cblite => '3',
            Library.cblitedart => '8',
            Library.vectorSearch => null,
          }
        : null;

    return LibraryConfiguration.dynamic(
      name,
      version: version,
      isAppleFramework: isAppleFramework,
    );
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
      return join(librariesPath, '$libraryName.framework', 'Versions', 'A', libraryName);
    }

    return version == null
        ? join(librariesPath, '$libraryName$extension')
        : join(librariesPath, '$libraryName.$version$extension');
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
        throw StateError('Required library not found at: $path');
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
