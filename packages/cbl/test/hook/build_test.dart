import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../hook/build.dart' as hook;

/// A target platform and architecture to test the build hook for.
typedef _Target = ({
  OS os,
  Architecture arch,
  IOSSdk? iosSdk,
  bool canRun,

  /// Whether the vector search extension is available for this target.
  /// Vector search is supported on ARM64 and x86-64, but not on 32-bit ARM
  /// or ia32.
  bool supportsVectorSearch,
});

// NOTE: These tests download real artifacts from the network. The build hook
// has internal retry logic with exponential backoff, but network failures or
// CDN slowness may cause intermittent test failures.

void main() {
  // --- Error-path tests ---

  test('rejects invalid edition', () async {
    await expectLater(
      testCodeBuildHook(
        mainMethod: hook.main,
        targetOS: OS.macOS,
        targetArchitecture: Architecture.arm64,
        targetIOSSdk: IOSSdk.iPhoneOS,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'edition': 'foo'},
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) {},
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('edition must be "community" or "enterprise"'),
        ),
      ),
    );
  });

  test('rejects vector_search without enterprise edition', () async {
    await expectLater(
      testCodeBuildHook(
        mainMethod: hook.main,
        targetOS: OS.macOS,
        targetArchitecture: Architecture.arm64,
        targetIOSSdk: IOSSdk.iPhoneOS,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'edition': 'community', 'vector_search': true},
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) {},
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('vector_search: true requires'),
        ),
      ),
    );
  });

  test(
    'skips vector_search on unsupported 32-bit ARM architecture',
    timeout: const Timeout(Duration(minutes: 5)),
    () async {
      await testCodeBuildHook(
        mainMethod: hook.main,
        targetOS: OS.android,
        targetArchitecture: Architecture.arm,
        targetIOSSdk: IOSSdk.iPhoneOS,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'edition': 'enterprise', 'vector_search': true},
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) {
          _checkAssets(
            input: input,
            output: output,
            targetOS: OS.android,
            targetArchitecture: Architecture.arm,
            vectorSearch: false,
          );
        },
      );
    },
  );

  // --- Build hook integration tests ---

  final targets = <_Target>[
    (
      os: OS.macOS,
      arch: Architecture.arm64,
      iosSdk: null,
      canRun: Platform.isMacOS,
      supportsVectorSearch: true,
    ),
    (
      os: OS.macOS,
      arch: Architecture.x64,
      iosSdk: null,
      canRun: Platform.isMacOS,
      supportsVectorSearch: true,
    ),
    // Device SDK (iPhoneOS).
    (
      os: OS.iOS,
      arch: Architecture.arm64,
      iosSdk: IOSSdk.iPhoneOS,
      canRun: Platform.isMacOS,
      supportsVectorSearch: true,
    ),
    // Simulator SDK (iPhoneSimulator).
    (
      os: OS.iOS,
      arch: Architecture.arm64,
      iosSdk: IOSSdk.iPhoneSimulator,
      canRun: Platform.isMacOS,
      supportsVectorSearch: true,
    ),
    (
      os: OS.iOS,
      arch: Architecture.x64,
      iosSdk: IOSSdk.iPhoneSimulator,
      canRun: Platform.isMacOS,
      supportsVectorSearch: true,
    ),
    // Vector search is supported on ARM64 and x86-64, but not on 32-bit ARM.
    (
      os: OS.android,
      arch: Architecture.arm,
      iosSdk: null,
      canRun: Platform.isMacOS || Platform.isLinux || Platform.isWindows,
      supportsVectorSearch: false,
    ),
    (
      os: OS.android,
      arch: Architecture.arm64,
      iosSdk: null,
      canRun: Platform.isMacOS || Platform.isLinux || Platform.isWindows,
      supportsVectorSearch: true,
    ),
    (
      os: OS.android,
      arch: Architecture.x64,
      iosSdk: null,
      canRun: Platform.isMacOS || Platform.isLinux || Platform.isWindows,
      supportsVectorSearch: true,
    ),
    (
      os: OS.linux,
      arch: Architecture.arm64,
      iosSdk: null,
      canRun: Platform.isLinux,
      supportsVectorSearch: true,
    ),
    (
      os: OS.linux,
      arch: Architecture.x64,
      iosSdk: null,
      canRun: Platform.isLinux,
      supportsVectorSearch: true,
    ),
    (
      os: OS.windows,
      arch: Architecture.arm64,
      iosSdk: null,
      canRun: Platform.isWindows,
      supportsVectorSearch: true,
    ),
    (
      os: OS.windows,
      arch: Architecture.x64,
      iosSdk: null,
      canRun: Platform.isWindows,
      supportsVectorSearch: true,
    ),
  ];

  const editions = ['community', 'enterprise'];

  for (final target in targets) {
    for (final edition in editions) {
      for (final vectorSearch in [
        false,
        if (edition == 'enterprise' && target.supportsVectorSearch) true,
      ]) {
        final iosSdkLabel = target.iosSdk != null
            ? ', sdk: ${target.iosSdk}'
            : '';
        final description =
            '${target.os} ${target.arch} '
            '(edition: $edition, '
            'vectorSearch: $vectorSearch$iosSdkLabel)';

        test(
          description,
          skip: target.canRun
              ? null
              : 'Cannot build for ${target.os} on this host.',
          timeout: const Timeout(Duration(minutes: 5)),
          () async {
            await testCodeBuildHook(
              mainMethod: hook.main,
              targetOS: target.os,
              targetArchitecture: target.arch,
              targetIOSSdk: target.iosSdk ?? IOSSdk.iPhoneOS,
              userDefines: PackageUserDefines(
                workspacePubspec: PackageUserDefinesSource(
                  defines: {
                    'edition': edition,
                    if (vectorSearch) 'vector_search': true,
                  },
                  basePath: Directory.current.uri,
                ),
              ),
              check: (input, output) {
                _checkAssets(
                  input: input,
                  output: output,
                  targetOS: target.os,
                  targetArchitecture: target.arch,
                  vectorSearch: vectorSearch,
                );
              },
            );
          },
        );
      }
    }
  }
}

/// Expected vector search dependency DLLs per Windows architecture.
const _windowsVectorSearchDeps = <Architecture, List<String>>{
  Architecture.x64: ['libomp140.x86_64.dll'],
  Architecture.arm64: ['libomp140.arm64.dll'],
};

void _checkAssets({
  required BuildInput input,
  required BuildOutput output,
  required OS targetOS,
  required Architecture targetArchitecture,
  required bool vectorSearch,
}) {
  final codeAssets = output.assets.code;

  // Verify the exact number of code assets.
  // On Windows with vector search, additional dependency DLLs (e.g. the
  // OpenMP runtime) are also registered as code assets.
  final windowsVsDeps = vectorSearch && targetOS == OS.windows
      ? _windowsVectorSearchDeps[targetArchitecture]?.length ?? 0
      : 0;
  final expectedAssetCount = (vectorSearch ? 3 : 2) + windowsVsDeps;
  expect(codeAssets, hasLength(expectedAssetCount));

  // Verify the lib staging directory exists.
  final outputDir = input.outputDirectory.toFilePath();
  final libDir = p.join(outputDir, 'lib');
  expect(Directory(libDir).existsSync(), isTrue);

  // --- cblite asset ---
  const cbliteId = 'package:cbl/src/bindings/cblite_native_assets.dart';
  final cbliteAsset = codeAssets.singleWhere((a) => a.id == cbliteId);
  expect(cbliteAsset.linkMode, isA<DynamicLoadingBundled>());
  expect(File.fromUri(cbliteAsset.file!).existsSync(), isTrue);
  expect(cbliteAsset.file!.toFilePath(), startsWith(libDir));

  switch (targetOS) {
    case OS.macOS:
      expect(File(p.join(libDir, 'libcblite.dylib')).existsSync(), isTrue);
    case OS.iOS:
      expect(File(p.join(libDir, 'CouchbaseLite')).existsSync(), isTrue);
    case OS.linux:
      // Major-version soname for DT_NEEDED resolution.
      expect(File(p.join(libDir, 'libcblite.so.3')).existsSync(), isTrue);
      // Unversioned symlink for the linker (-lcblite).
      expect(File(p.join(libDir, 'libcblite.so')).existsSync(), isTrue);
      // Code asset should be the soname version.
      expect(cbliteAsset.file!.toFilePath(), endsWith('libcblite.so.3'));
    case OS.android:
      expect(File(p.join(libDir, 'libcblite.so')).existsSync(), isTrue);
    case OS.windows:
      expect(File(p.join(libDir, 'cblite.dll')).existsSync(), isTrue);
      expect(File(p.join(libDir, 'cblite.lib')).existsSync(), isTrue);
    default:
      break;
  }

  // --- cblitedart asset ---
  const cblitedartId = 'package:cbl/src/bindings/cblitedart_native_assets.dart';
  final cblitedartAsset = codeAssets.singleWhere((a) => a.id == cblitedartId);
  expect(cblitedartAsset.linkMode, isA<DynamicLoadingBundled>());
  expect(File.fromUri(cblitedartAsset.file!).existsSync(), isTrue);

  final expectedCblitedartExt = switch (targetOS) {
    OS.macOS || OS.iOS => '.dylib',
    OS.linux || OS.android => '.so',
    OS.windows => '.dll',
    _ => throw UnsupportedError('Unsupported OS: $targetOS'),
  };
  expect(
    cblitedartAsset.file!.toFilePath(),
    endsWith('cblitedart$expectedCblitedartExt'),
  );

  // --- vector search asset ---
  if (vectorSearch) {
    const vsId = 'package:cbl/src/bindings/cblite_vector_search.dart';
    final vsAsset = codeAssets.singleWhere((a) => a.id == vsId);
    expect(vsAsset.linkMode, isA<DynamicLoadingBundled>());
    expect(File.fromUri(vsAsset.file!).existsSync(), isTrue);
    expect(vsAsset.file!.toFilePath(), startsWith(libDir));

    switch (targetOS) {
      case OS.macOS:
        expect(
          File(p.join(libDir, 'CouchbaseLiteVectorSearch.dylib')).existsSync(),
          isTrue,
        );
      case OS.iOS:
        expect(
          File(p.join(libDir, 'CouchbaseLiteVectorSearch')).existsSync(),
          isTrue,
        );
      case OS.linux:
        expect(
          File(p.join(libDir, 'CouchbaseLiteVectorSearch.so')).existsSync(),
          isTrue,
        );
      case OS.android:
        expect(
          File(p.join(libDir, 'libCouchbaseLiteVectorSearch.so')).existsSync(),
          isTrue,
        );
      case OS.windows:
        expect(
          File(p.join(libDir, 'CouchbaseLiteVectorSearch.dll')).existsSync(),
          isTrue,
        );
        // Verify that vector search dependency DLLs (e.g. OpenMP runtime) are
        // registered as code assets and exist on disk.
        final expectedDeps = _windowsVectorSearchDeps[targetArchitecture] ?? [];
        for (final depName in expectedDeps) {
          expect(
            File(p.join(libDir, depName)).existsSync(),
            isTrue,
            reason: 'Expected vector search dependency $depName in $libDir',
          );
        }
        final depAssets = codeAssets.where(
          (a) => a.id.contains('vector_search_dep_'),
        );
        expect(depAssets, hasLength(expectedDeps.length));
        for (final dep in depAssets) {
          expect(dep.linkMode, isA<DynamicLoadingBundled>());
          expect(File.fromUri(dep.file!).existsSync(), isTrue);
          expect(dep.file!.toFilePath(), startsWith(libDir));
        }
      default:
        break;
    }
  } else {
    expect(
      codeAssets.where((a) => a.id.contains('cblite_vector_search')),
      isEmpty,
    );
  }
}
