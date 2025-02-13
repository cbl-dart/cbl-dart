import 'dart:io';
import 'package:path/path.dart';

import '../bindings/libraries.dart';
import 'package.dart';

/// Configuration for local assets containing pre-bundled libraries
class LocalAssetsConfiguration {
  LocalAssetsConfiguration({
    required this.binaryDependencies,
    required this.edition,
    this.skipVectorSearch = false,
  });

  final Directory binaryDependencies;
  final Edition edition;
  final bool skipVectorSearch;

  String get _platformDir => switch (Platform.operatingSystem) {
        'macos' => 'macos',
        'windows' => 'windows',
        'linux' => 'linux',
        _ => throw UnsupportedError('Unsupported platform'),
      };

  String get _platformHash => switch (Platform.operatingSystem) {
        'macos' => 'c4f61c9bde1085be63f32dd54ca8829e',
        'windows' => 'c2ddf39c36bd6ab58d86b27ddc102286',
        'linux' => '6af4f73a0a0e59cb7e1a272a9fa0828a',
        _ => throw UnsupportedError('Unsupported platform'),
      };

  String get librariesPath => join(binaryDependencies.path, _platformDir, _platformHash);

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

  LibraryConfiguration _createLibraryConfig(OS os, Library library) {
    final name = library.libraryName(os);
    final isAppleFramework = library.appleFrameworkType(os) == AppleFrameworkType.framework;

    // For macOS, we need to handle symlinks correctly
    final version = os == OS.macOS && !isAppleFramework
        ? switch (library) {
            Library.cblite => '3',
            Library.cblitedart => '8',
            Library.vectorSearch => null,
          }
        : null;

    // On macOS, vector search is a framework
    return LibraryConfiguration.dynamic(
      name,
      version: version,
      isAppleFramework: isAppleFramework,
    );
  }

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

  String resolveLibraryPath(Library library) {
    final os = OS.current;
    final config = _createLibraryConfig(os, library);
    return _resolveLibraryPath(config);
  }
}
