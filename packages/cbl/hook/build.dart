import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import 'src/download.dart' as dl;

const _cbliteRelease = '3.2.4';
const _vectorSearchRelease = '1.0.0';

void main(List<String> args) async {
  await build(args, _build);
}

Future<void> _build(BuildInput input, BuildOutputBuilder output) async {
  // Diagnostic logging for CI: confirm the build hook is running and show
  // key configuration values.
  // ignore: avoid_print
  print('[cbl build hook] Running build hook.');
  // ignore: avoid_print
  print('[cbl build hook] targetOS: ${input.config.code.targetOS}');
  // ignore: avoid_print
  print(
    '[cbl build hook] targetArchitecture: '
    '${input.config.code.targetArchitecture}',
  );
  // ignore: avoid_print
  print('[cbl build hook] outputDirectory: ${input.outputDirectory}');

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

  // 1. Download precompiled cblite and stage files for linking and bundling.
  final cblite = await _downloadCblite(
    input: input,
    edition: edition,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
  );

  // Stage native libraries into a lib subdirectory of the output directory.
  // This directory is used both for linking cblitedart against cblite and
  // for registering shared libraries as code assets.
  const libDir = 'lib';
  final libPath = p.join(input.outputDirectory.toFilePath(), libDir);
  await Directory(libPath).create(recursive: true);
  final cbliteAssetPath = await _stageCblite(
    cblite,
    stagingDir: libPath,
    targetOS: targetOS,
    targetArchitecture: targetArchitecture,
  );

  output.assets.code.add(
    CodeAsset(
      package: 'cbl',
      name: 'src/bindings/cblite_native_assets.dart',
      linkMode: DynamicLoadingBundled(),
      file: cbliteAssetPath,
    ),
  );
  // ignore: avoid_print
  print('[cbl build hook] Registered cblite asset: $cbliteAssetPath');

  // 2. Compile cblitedart from source.
  // Use headers from the downloaded cblite package — they contain the correct
  // CBL_Edition.h for the selected edition (community vs enterprise).
  final builder = CBuilder.library(
    name: 'cblitedart',
    assetName: 'src/bindings/cblitedart_native_assets.dart',
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
    libraries: [if (targetOS != OS.iOS) 'cblite'],
    libraryDirectories: [if (targetOS != OS.iOS) libDir],
    flags: [
      if (targetOS != OS.windows) '-fvisibility=hidden',
      '-I${cblite.includeDir}',
      if (targetOS == OS.iOS) ...[
        '-F${p.dirname(p.dirname(cblite.libPath.toFilePath()))}',
        '-framework',
        'CouchbaseLite',
      ],
    ],
    defines: {if (edition == 'enterprise') 'COUCHBASE_ENTERPRISE': '1'},
    language: Language.cpp,
    std: 'c++17',
    // Use static libc++ on Android to avoid needing to bundle
    // libc++_shared.so as a separate code asset.
    cppLinkStdLib: targetOS == OS.android ? 'c++_static' : null,
  );
  await builder.run(input: input, output: output);
  // ignore: avoid_print
  print('[cbl build hook] Compiled and registered cblitedart asset.');

  // 3. Optionally download vector search extension.
  // Vector search is only available for 64-bit architectures.
  final vectorSearchSupported =
      targetArchitecture != Architecture.arm &&
      targetArchitecture != Architecture.ia32;

  if (edition == 'enterprise' && vectorSearch && !vectorSearchSupported) {
    // ignore: avoid_print
    print(
      '[cbl build hook] Skipping vector search: '
      'not available for $targetArchitecture.',
    );
  }

  if (edition == 'enterprise' && vectorSearch && vectorSearchSupported) {
    var vectorSearchLibPath = await _downloadVectorSearch(
      input: input,
      targetOS: targetOS,
      targetArchitecture: targetArchitecture,
    );

    if (targetOS == OS.macOS || targetOS == OS.iOS) {
      vectorSearchLibPath = await _lipoThin(
        vectorSearchLibPath,
        targetArchitecture: targetArchitecture,
        outputDir: input.outputDirectory,
      );
    }

    // Stage the vector search library into the shared lib directory.
    final vsFileName = p.basename(vectorSearchLibPath.toFilePath());
    final vsDest = p.join(libPath, vsFileName);
    await File(vectorSearchLibPath.toFilePath()).copy(vsDest);

    output.assets.code.add(
      CodeAsset(
        package: 'cbl',
        name: 'src/bindings/cblite_vector_search.dart',
        linkMode: DynamicLoadingBundled(),
        file: Uri.file(vsDest),
      ),
    );
    // ignore: avoid_print
    print('[cbl build hook] Registered vector search asset: $vsDest');

    // On Windows, the vector search library depends on runtime DLLs (e.g.
    // the OpenMP runtime libomp140.*.dll) that are bundled in the archive
    // alongside the main DLL. Copy and register any additional DLLs as code
    // assets so they are available at runtime.
    if (targetOS == OS.windows) {
      final vsSourceDir = p.dirname(vectorSearchLibPath.toFilePath());
      final vsMainName = p.basename(vectorSearchLibPath.toFilePath());
      var depIndex = 0;
      for (final entity in Directory(vsSourceDir).listSync()) {
        if (entity is! File) {
          continue;
        }
        final name = p.basename(entity.path);
        if (!name.endsWith('.dll') || name == vsMainName) {
          continue;
        }
        final depDest = p.join(libPath, name);
        await entity.copy(depDest);
        output.assets.code.add(
          CodeAsset(
            package: 'cbl',
            name: 'src/bindings/vector_search_dep_$depIndex.dart',
            linkMode: DynamicLoadingBundled(),
            file: Uri.file(depDest),
          ),
        );
        depIndex++;
        // ignore: avoid_print
        print('[cbl build hook] Registered vector search dependency: $name');
      }
    }
  }

  // ignore: avoid_print
  print('[cbl build hook] Build hook completed successfully.');
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
  final architectures = _cbliteArchitectures(os, arch);

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
  final package = await loader.load(config);

  if (targetOS == OS.iOS) {
    return _findIOSFramework(package, input);
  }

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

  final config = dl.VectorSearchPackageConfig(
    os: os,
    architectures: _vsArchitectures(os, arch),
    release: release,
  );

  final cacheDir = p.join(
    input.outputDirectoryShared.toFilePath(),
    'vector-search-${os.name}-${arch.name}-$release',
  );

  final loader = dl.RemotePackageLoader(cacheDir: cacheDir);
  final package = await loader.load(config);

  if (targetOS == OS.iOS) {
    return _findIOSVectorSearchLibrary(package, input);
  }

  return _findLibrary(package, os);
}

// === Helpers ================================================================

Future<({Uri libPath, String includeDir})> _findIOSFramework(
  dl.Package package,
  BuildInput input,
) async {
  final targetSdk = input.config.code.iOS.targetSdk;
  final sliceDir = switch (targetSdk) {
    IOSSdk.iPhoneOS => 'ios-arm64',
    IOSSdk.iPhoneSimulator => 'ios-arm64_x86_64-simulator',
    _ => throw UnsupportedError('Unsupported iOS SDK: $targetSdk'),
  };
  final frameworkDir = p.join(
    package.packageDir,
    'CouchbaseLite.xcframework',
    sliceDir,
    'CouchbaseLite.framework',
  );
  final headersDir = p.join(frameworkDir, 'Headers');

  // The framework has flat headers, but cblitedart sources include
  // "cbl/CBL.h" and "fleece/Fleece.h". Create a synthetic include directory
  // with symlinks that map these subdirectories to the flat headers.
  final includeDir = p.join(package.packageDir, 'include');
  for (final subdir in ['cbl', 'fleece']) {
    final link = Link(p.join(includeDir, subdir));
    if (!link.existsSync()) {
      await link.create(headersDir, recursive: true);
    }
  }

  return (
    libPath: Uri.file(p.join(frameworkDir, 'CouchbaseLite')),
    includeDir: includeDir,
  );
}

/// Finds the vector search dynamic library inside an iOS xcframework.
Uri _findIOSVectorSearchLibrary(dl.Package package, BuildInput input) {
  final targetSdk = input.config.code.iOS.targetSdk;
  final sliceDir = switch (targetSdk) {
    IOSSdk.iPhoneOS => 'ios-arm64',
    IOSSdk.iPhoneSimulator => 'ios-arm64_x86_64-simulator',
    _ => throw UnsupportedError('Unsupported iOS SDK: $targetSdk'),
  };
  final frameworkDir = p.join(
    package.packageDir,
    'CouchbaseLiteVectorSearch.xcframework',
    sliceDir,
    'CouchbaseLiteVectorSearch.framework',
  );
  return Uri.file(p.join(frameworkDir, 'CouchbaseLiteVectorSearch'));
}

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

/// Stages cblite library files into the staging directory for linking and
/// bundling. Returns the URI of the shared library to register as a code asset.
Future<Uri> _stageCblite(
  ({Uri libPath, String includeDir}) cblite, {
  required String stagingDir,
  required OS targetOS,
  required Architecture targetArchitecture,
}) async {
  final libFile = cblite.libPath.toFilePath();

  switch (targetOS) {
    case OS.macOS:
      // macOS libraries are universal binaries. The Dart native assets bundler
      // expects single-architecture binaries, so we thin it.
      final arch = switch (targetArchitecture) {
        Architecture.arm64 => 'arm64',
        Architecture.x64 => 'x86_64',
        _ => throw UnsupportedError(
          'Unsupported macOS architecture: $targetArchitecture',
        ),
      };
      final outputFile = p.join(stagingDir, 'libcblite.dylib');
      final result = await Process.run('lipo', [
        libFile,
        '-thin',
        arch,
        '-output',
        outputFile,
      ]);
      if (result.exitCode != 0) {
        throw Exception('lipo failed: ${result.stderr}');
      }
      return Uri.file(outputFile);

    case OS.linux:
      // libcblitedart.so has a DT_NEEDED for the versioned soname (e.g.
      // libcblite.so.3). Dart loads native assets with RTLD_LOCAL and bundles
      // files under their original filename, so we provide the library under
      // its major-version soname for the dynamic linker to resolve.
      final majorVersion = _cbliteRelease.split('.').first;
      final sonameFile = p.join(stagingDir, 'libcblite.so.$majorVersion');
      await File(libFile).copy(sonameFile);
      // Also provide the unversioned name for the linker (-lcblite).
      await File(libFile).copy(p.join(stagingDir, 'libcblite.so'));
      return Uri.file(sonameFile);

    case OS.android:
      final dest = p.join(stagingDir, 'libcblite.so');
      await File(libFile).copy(dest);
      return Uri.file(dest);

    case OS.windows:
      // Copy the DLL for bundling.
      final dllDest = p.join(stagingDir, 'cblite.dll');
      await File(libFile).copy(dllDest);
      // Copy the import library for linking.
      final importLib = cblite.libPath
          .resolve('../lib/cblite.lib')
          .toFilePath();
      await File(importLib).copy(p.join(stagingDir, 'cblite.lib'));
      return Uri.file(dllDest);

    case OS.iOS:
      // The iOS xcframework simulator slice is a universal binary containing
      // both arm64 and x86_64. The native assets bundler invokes the hook once
      // per architecture and then creates a universal binary from the results.
      // We must thin to the target architecture to avoid lipo errors.
      final iosArch = switch (targetArchitecture) {
        Architecture.arm64 => 'arm64',
        Architecture.x64 => 'x86_64',
        _ => throw UnsupportedError(
          'Unsupported iOS architecture: $targetArchitecture',
        ),
      };
      final dest = p.join(stagingDir, 'CouchbaseLite');
      final isUniversal = await _isUniversalBinary(libFile);
      if (isUniversal) {
        final result = await Process.run('lipo', [
          libFile,
          '-thin',
          iosArch,
          '-output',
          dest,
        ]);
        if (result.exitCode != 0) {
          throw Exception('lipo thin failed for iOS: ${result.stderr}');
        }
      } else {
        await File(libFile).copy(dest);
      }
      return Uri.file(dest);

    default:
      throw UnsupportedError('Unsupported OS: $targetOS');
  }
}

/// Extracts a single architecture from a universal (fat) macOS binary.
Future<Uri> _lipoThin(
  Uri libPath, {
  required Architecture targetArchitecture,
  required Uri outputDir,
}) async {
  final arch = switch (targetArchitecture) {
    Architecture.arm64 => 'arm64',
    Architecture.x64 => 'x86_64',
    _ => throw UnsupportedError(
      'Unsupported macOS architecture: $targetArchitecture',
    ),
  };

  final inputFile = libPath.toFilePath();
  final isUniversal = await _isUniversalBinary(inputFile);
  if (!isUniversal) {
    // Already a single-architecture binary; no thinning needed.
    return libPath;
  }

  final outputFile = p.join(outputDir.toFilePath(), p.basename(inputFile));

  final result = await Process.run('lipo', [
    inputFile,
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

/// Returns true if the given file is a universal (fat) Mach-O binary.
Future<bool> _isUniversalBinary(String path) async {
  final result = await Process.run('lipo', ['-info', path]);
  if (result.exitCode != 0) {
    return false;
  }
  return (result.stdout as String).contains('Architectures in the fat file');
}

dl.OS _mapOS(OS os) => switch (os) {
  OS.android => dl.OS.android,
  OS.iOS => dl.OS.iOS,
  OS.macOS => dl.OS.macOS,
  OS.linux => dl.OS.linux,
  OS.windows => dl.OS.windows,
  _ => throw Exception('Unsupported target OS: $os'),
};

/// Returns the list of architectures for the cblite download URL.
///
/// macOS, iOS and Android packages are multi-architecture archives, so we pass
/// multiple architectures to make `PackageConfig.isMultiArchitecture` true,
/// which produces a target ID without an architecture suffix (e.g. just "macos"
/// or "android").
///
/// The target architecture is always first in the list so that
/// `Package.sharedLibrariesDir` resolves to the correct per-architecture
/// subdirectory on Android.
List<dl.Architecture> _cbliteArchitectures(dl.OS os, dl.Architecture arch) =>
    switch (os) {
      dl.OS.macOS || dl.OS.iOS => [dl.Architecture.x64, dl.Architecture.arm64],
      dl.OS.android => [
        arch,
        // Add a second architecture to make isMultiArchitecture true.
        if (arch != dl.Architecture.x64)
          dl.Architecture.x64
        else
          dl.Architecture.arm64,
      ],
      _ => [arch],
    };

/// Returns the list of architectures for the vector search download URL.
///
/// macOS and iOS packages are multi-architecture. Android, Linux and Windows
/// packages are per-architecture.
List<dl.Architecture> _vsArchitectures(dl.OS os, dl.Architecture arch) =>
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
