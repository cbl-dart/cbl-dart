import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import 'src/download.dart' as dl;

void main(List<String> args) async {
  await build(args, _build);
}

Future<void> _build(BuildInput input, BuildOutputBuilder output) async {
  final edition = (input.userDefines['edition'] as String?) ?? 'community';
  final vectorSearch = input.userDefines['vector_search']?.toString() == 'true';

  if (vectorSearch && edition != 'enterprise') {
    throw Exception(
      'cbl: vector_search: true requires '
      'edition: enterprise in user_defines.',
    );
  }

  if (edition != 'community' && edition != 'enterprise') {
    throw Exception(
      'cbl: edition must be "community" or "enterprise", '
      'got "$edition".',
    );
  }

  final targetOS = input.config.code.targetOS;
  final targetArchitecture = input.config.code.targetArchitecture;

  // 1. Download precompiled cblite.
  final cblite = await _downloadCblite(
    input: input,
    edition: edition,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
  );

  // On macOS, the downloaded library is a universal binary. The Dart native
  // assets bundler expects single-architecture binaries, so we thin it.
  final cbliteAssetPath = await _thinIfNeeded(
    cblite.libPath,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
    outputDir: input.outputDirectory,
  );

  output.assets.code.add(
    CodeAsset(
      package: 'cbl',
      name: 'package:cbl/src/bindings/cblite_native_assets.dart',
      linkMode: DynamicLoadingBundled(),
      file: cbliteAssetPath,
    ),
  );

  // 2. Compile cblitedart from source.
  // Use headers from the downloaded cblite package — they contain the correct
  // CBL_Edition.h for the selected edition (community vs enterprise).
  final builder = CBuilder.library(
    name: 'cblitedart',
    assetName: 'package:cbl/src/bindings/cblitedart_native_assets.dart',
    sources: [
      'native/couchbase-lite-dart/src/CBL+Dart.cpp',
      'native/couchbase-lite-dart/src/Fleece+Dart.cpp',
      'native/couchbase-lite-dart/src/AsyncCallback.cpp',
      'native/couchbase-lite-dart/src/Sentry.cpp',
      'native/couchbase-lite-dart/src/Utils.cpp',
      'native/couchbase-lite-dart/src/CpuSupport.cpp',
      'native/couchbase-lite-dart/src/dart_api_dl.cpp',
    ],
    includes: [
      'native/vendor/dart/include',
      'native/couchbase-lite-dart/include',
    ],
    flags: [
      if (targetOS != OS.windows) '-fvisibility=hidden',
      // Use cblite headers from the downloaded package.
      '-I${cblite.includeDir}',
      // Link against cblite.
      ...switch (targetOS) {
        OS.iOS => [
          '-F${cblite.libPath.resolve('../').toFilePath()}',
          '-framework',
          'CouchbaseLite',
        ],
        OS.macOS => [
          '-L${cblite.libPath.resolve('./').toFilePath()}',
          '-lcblite',
        ],
        OS.android || OS.linux => [
          r'-Wl,-rpath=$ORIGIN',
          '-L${cblite.libPath.resolve('./').toFilePath()}',
          '-lcblite',
        ],
        OS.windows => [
          cblite.libPath.resolve('../lib/cblite.lib').toFilePath(),
        ],
        _ => throw UnsupportedError('Unsupported OS: $targetOS'),
      },
    ],
    defines: {if (edition == 'enterprise') 'COUCHBASE_ENTERPRISE': '1'},
    language: Language.cpp,
    std: 'c++17',
  );
  await builder.run(input: input, output: output);

  // 3. Optionally download vector search extension.
  if (edition == 'enterprise' && vectorSearch) {
    final vectorSearchLibPath = await _downloadVectorSearch(
      input: input,
      targetOS: targetOS,
      targetArchitecture: targetArchitecture,
    );

    output.assets.code.add(
      CodeAsset(
        package: 'cbl',
        name: 'package:cbl/src/bindings/cblite_vector_search.dart',
        linkMode: DynamicLoadingBundled(),
        file: vectorSearchLibPath,
      ),
    );
  }
}

// === Download cblite ========================================================

Future<({Uri libPath, String includeDir})> _downloadCblite({
  required BuildInput input,
  required String edition,
  required OS targetOS,
  required Architecture targetArchitecture,
}) async {
  const release = _cbliteRelease;
  final os = _mapOS(targetOS);
  final arch = _mapArchitecture(targetArchitecture);
  final architectures = _architectures(os, arch);

  final config = dl.DatabasePackageConfig(
    library: dl.Library.cblite,
    os: os,
    architectures: architectures,
    release: release,
    archiveFormat: os == dl.OS.linux
        ? dl.ArchiveFormat.tarGz
        : dl.ArchiveFormat.zip,
    edition: edition == 'enterprise'
        ? dl.Edition.enterprise
        : dl.Edition.community,
  );

  final cacheDir = p.join(
    input.outputDirectoryShared.toFilePath(),
    'cblite-$edition-${os.name}-${arch.name}-$release',
  );

  final loader = dl.RemotePackageLoader(cacheDir: cacheDir);
  final package = await _retryOnce(() => loader.load(config));
  final libPath = _findLibrary(package, os);
  final includeDir = p.join(package.rootDir, 'include');
  return (libPath: libPath, includeDir: includeDir);
}

// === Download vector search ================================================

Future<Uri> _downloadVectorSearch({
  required BuildInput input,
  required OS targetOS,
  required Architecture targetArchitecture,
}) async {
  const release = _vectorSearchRelease;
  final os = _mapOS(targetOS);
  final arch = _mapArchitecture(targetArchitecture);
  final architectures = _architectures(os, arch);

  final config = dl.VectorSearchPackageConfig(
    os: os,
    architectures: architectures,
    release: release,
  );

  final cacheDir = p.join(
    input.outputDirectoryShared.toFilePath(),
    'vector-search-${os.name}-${arch.name}-$release',
  );

  final loader = dl.RemotePackageLoader(cacheDir: cacheDir);
  final package = await _retryOnce(() => loader.load(config));
  return _findLibrary(package, os);
}

// === Helpers ================================================================

Uri _findLibrary(dl.Package package, dl.OS os) {
  final libDir = package.sharedLibrariesDir;
  if (libDir == null) {
    throw Exception('No shared libraries directory for ${package.libraryName}');
  }

  final libraryName = package.libraryName;
  final extensions = switch (os) {
    dl.OS.macOS || dl.OS.iOS => ['.dylib'],
    dl.OS.linux || dl.OS.android => ['.so'],
    dl.OS.windows => ['.dll'],
  };

  for (final ext in extensions) {
    final candidate = p.join(libDir, '$libraryName$ext');
    if (File(candidate).existsSync()) {
      return Uri.file(candidate);
    }
  }

  // Try finding any file matching the library name.
  final dir = Directory(libDir);
  if (dir.existsSync()) {
    for (final entity in dir.listSync()) {
      final name = p.basename(entity.path);
      if (entity is File && name.contains(libraryName)) {
        return Uri.file(entity.path);
      }
    }
  }

  throw Exception('Could not find $libraryName library in $libDir');
}

Future<T> _retryOnce<T>(Future<T> Function() fn) async {
  try {
    return await fn();
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return fn();
  }
}

/// Extracts the target architecture from a universal (fat) binary using lipo.
///
/// On macOS, downloaded cblite packages are universal binaries. The Dart native
/// assets bundler expects single-architecture binaries.
Future<Uri> _thinIfNeeded(
  Uri libPath, {
  required OS targetOS,
  required Architecture targetArchitecture,
  required Uri outputDir,
}) async {
  if (targetOS != OS.macOS) return libPath;

  final arch = switch (targetArchitecture) {
    Architecture.arm64 => 'arm64',
    Architecture.x64 => 'x86_64',
    _ => throw UnsupportedError(
      'Unsupported macOS architecture: $targetArchitecture',
    ),
  };

  final outputFile = p.join(
    outputDir.toFilePath(),
    p.basename(libPath.toFilePath()),
  );

  final result = await Process.run('lipo', [
    libPath.toFilePath(),
    '-thin',
    arch,
    '-output',
    outputFile,
  ]);

  if (result.exitCode != 0) {
    throw Exception('lipo failed: ${result.stderr}');
  }

  return Uri.file(outputFile);
}

dl.OS _mapOS(OS os) => switch (os) {
  OS.android => dl.OS.android,
  OS.iOS => dl.OS.iOS,
  OS.macOS => dl.OS.macOS,
  OS.linux => dl.OS.linux,
  OS.windows => dl.OS.windows,
  _ => throw Exception('Unsupported target OS: $os'),
};

/// Returns the list of architectures for the download URL.
///
/// macOS and iOS packages are universal binaries containing all architectures,
/// so we pass both to make [PackageConfig.isMultiArchitecture] true, which
/// produces a target ID without an architecture suffix (e.g. just "macos").
List<dl.Architecture> _architectures(dl.OS os, dl.Architecture arch) =>
    switch (os) {
      dl.OS.macOS || dl.OS.iOS => [dl.Architecture.x64, dl.Architecture.arm64],
      _ => [arch],
    };

dl.Architecture _mapArchitecture(Architecture arch) => switch (arch) {
  Architecture.arm => dl.Architecture.arm,
  Architecture.arm64 => dl.Architecture.arm64,
  Architecture.ia32 => dl.Architecture.ia32,
  Architecture.x64 => dl.Architecture.x64,
  _ => throw Exception('Unsupported target architecture: $arch'),
};

const _cbliteRelease = '3.2.4';
const _vectorSearchRelease = '1.0.0';
