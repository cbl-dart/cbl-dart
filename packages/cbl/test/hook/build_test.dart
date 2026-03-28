import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
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
  /// Vector search is supported on ARM64 and x86-64.
  bool supportsVectorSearch,
});

typedef _HostTarget = ({OS os, Architecture arch});

// NOTE: These tests download real artifacts from the network. The build hook
// has internal retry logic with exponential backoff, but network failures or
// CDN slowness may cause intermittent test failures.

void main() {
  // --- Error-path tests ---

  test('rejects invalid edition', () async {
    await expectLater(
      _runBuildHookDirect(
        targetOS: OS.macOS,
        targetArchitecture: Architecture.arm64,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'edition': 'foo'},
            basePath: Directory.current.uri,
          ),
        ),
      ),
      throwsA(
        isA<BuildError>().having(
          (e) => e.message,
          'message',
          contains('edition must be "community" or "enterprise"'),
        ),
      ),
    );
  });

  test('rejects vector_search without enterprise edition', () async {
    await expectLater(
      _runBuildHookDirect(
        targetOS: OS.macOS,
        targetArchitecture: Architecture.arm64,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'edition': 'community', 'vector_search': true},
            basePath: Directory.current.uri,
          ),
        ),
      ),
      throwsA(
        isA<BuildError>().having(
          (e) => e.message,
          'message',
          contains('vector_search: true requires'),
        ),
      ),
    );
  });

  final hostTarget = _hostTarget();

  test(
    'uses community edition by default when no edition is specified',
    skip: hostTarget == null
        ? 'No supported host target is available for this platform.'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
    () async {
      final target = hostTarget!;
      await testCodeBuildHook(
        mainMethod: hook.main,
        targetOS: target.os,
        targetArchitecture: target.arch,
        targetIOSSdk: IOSSdk.iPhoneOS,
        check: (input, output) {
          _checkAssets(
            input: input,
            output: output,
            targetOS: target.os,
            targetArchitecture: target.arch,
            vectorSearch: false,
          );
          _expectCommunityEditionCache(input);
        },
      );
    },
  );

  test(
    'bundles cblite debug symbols when requested',
    skip: hostTarget == null
        ? 'No supported host target is available for this platform.'
        : null,
    timeout: const Timeout(Duration(minutes: 5)),
    () async {
      final target = hostTarget!;
      await _testBuildHookWithDataAssets(
        targetOS: target.os,
        targetArchitecture: target.arch,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'debug_symbols': true},
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) async {
          final dataAssets = output.assets.encodedAssets
              .where((asset) => asset.isDataAsset)
              .map((asset) => asset.asDataAsset)
              .toList();
          expect(dataAssets, isNotEmpty);

          final expectedSuffix = switch (target.os) {
            OS.macOS => p.join(
              'libcblite.dylib.dSYM',
              'Contents',
              'Info.plist',
            ),
            OS.linux => 'libcblite.so.sym',
            OS.windows => 'cblite.pdb',
            _ => throw UnsupportedError('Unsupported OS: ${target.os}'),
          };
          expect(
            dataAssets.any(
              (asset) => asset.file.toFilePath().endsWith(expectedSuffix),
            ),
            isTrue,
          );
        },
      );
    },
  );

  test(
    'bundles vector search debug symbols when requested',
    skip: switch (hostTarget) {
      null => 'No supported host target is available for this platform.',
      (os: OS.linux, arch: Architecture.x64) ||
      (os: OS.macOS, arch: _) ||
      (os: OS.windows, arch: _) => null,
      _ =>
        'Vector search debug symbol test is only enabled on supported hosts.',
    },
    timeout: const Timeout(Duration(minutes: 5)),
    () async {
      final target = hostTarget!;
      await _testBuildHookWithDataAssets(
        targetOS: target.os,
        targetArchitecture: target.arch,
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {
              'edition': 'enterprise',
              'vector_search': true,
              'debug_symbols': true,
            },
            basePath: Directory.current.uri,
          ),
        ),
        check: (input, output) async {
          final dataAssets = output.assets.encodedAssets
              .where((asset) => asset.isDataAsset)
              .map((asset) => asset.asDataAsset)
              .toList();

          final expectedSuffix = switch (target.os) {
            OS.macOS => p.join(
              'CouchbaseLiteVectorSearch.dSYM',
              'Contents',
              'Info.plist',
            ),
            OS.linux => 'CouchbaseLiteVectorSearch.so.sym',
            OS.windows => 'CouchbaseLiteVectorSearch.pdb',
            _ => throw UnsupportedError('Unsupported OS: ${target.os}'),
          };
          expect(
            dataAssets.any(
              (asset) => asset.file.toFilePath().endsWith(expectedSuffix),
            ),
            isTrue,
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
    (
      os: OS.android,
      arch: Architecture.arm,
      iosSdk: null,
      canRun: Platform.isMacOS || Platform.isLinux || Platform.isWindows,
      supportsVectorSearch: false,
    ),
    (
      os: OS.android,
      arch: Architecture.ia32,
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
      for (final vectorSearchRequested in [
        false,
        if (edition == 'enterprise') true,
      ]) {
        final expectedVectorSearch =
            vectorSearchRequested && target.supportsVectorSearch;
        final iosSdkLabel = target.iosSdk != null
            ? ', sdk: ${target.iosSdk}'
            : '';
        final description =
            '${target.os} ${target.arch} '
            '(edition: $edition, '
            'vectorSearch: $vectorSearchRequested$iosSdkLabel)';

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
                    if (vectorSearchRequested) 'vector_search': true,
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
                  vectorSearch: expectedVectorSearch,
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

_HostTarget? _hostTarget() {
  final os = switch (Platform.operatingSystem) {
    'macos' => OS.macOS,
    'linux' => OS.linux,
    'windows' => OS.windows,
    _ => null,
  };

  final arch = switch (Abi.current()) {
    Abi.macosArm64 || Abi.linuxArm64 || Abi.windowsArm64 => Architecture.arm64,
    Abi.macosX64 || Abi.linuxX64 || Abi.windowsX64 => Architecture.x64,
    _ => null,
  };

  if (os == null || arch == null) {
    return null;
  }

  return (os: os, arch: arch);
}

Future<void> _runBuildHookDirect({
  required OS targetOS,
  required Architecture targetArchitecture,
  PackageUserDefines? userDefines,
  IOSSdk targetIOSSdk = IOSSdk.iPhoneOS,
  int targetIOSVersion = 17,
  int targetMacOSVersion = 13,
  int targetAndroidNdkApi = 30,
}) async {
  final tempDir = await Directory.systemTemp.createTemp();

  try {
    final tempUri = Directory(
      await tempDir.resolveSymbolicLinks(),
    ).uri.normalizePath();
    final outputDirectoryShared = tempUri.resolve('output_shared/');
    final outputFile = tempUri.resolve('output.json');

    await Directory.fromUri(outputDirectoryShared).create();

    final inputBuilder = BuildInputBuilder()
      ..setupShared(
        packageRoot: Directory.current.uri,
        packageName: 'cbl',
        outputFile: outputFile,
        outputDirectoryShared: outputDirectoryShared,
        userDefines: userDefines,
      )
      ..setupBuildInput()
      ..config.setupBuild(linkingEnabled: false);

    CodeAssetExtension(
      linkModePreference: LinkModePreference.dynamic,
      targetArchitecture: targetArchitecture,
      targetOS: targetOS,
      iOS: targetOS == OS.iOS
          ? IOSCodeConfig(
              targetSdk: targetIOSSdk,
              targetVersion: targetIOSVersion,
            )
          : null,
      macOS: targetOS == OS.macOS
          ? MacOSCodeConfig(targetVersion: targetMacOSVersion)
          : null,
      android: targetOS == OS.android
          ? AndroidCodeConfig(targetNdkApi: targetAndroidNdkApi)
          : null,
    ).setupBuildInput(inputBuilder);

    final input = inputBuilder.build();
    final output = BuildOutputBuilder();

    await hook.buildHook(input, output);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

Future<void> _testBuildHookWithDataAssets({
  required OS targetOS,
  required Architecture targetArchitecture,
  required PackageUserDefines userDefines,
  required Future<void> Function(BuildInput input, BuildOutput output) check,
}) {
  final codeExtension = CodeAssetExtension(
    linkModePreference: LinkModePreference.dynamic,
    targetArchitecture: targetArchitecture,
    targetOS: targetOS,
    iOS: targetOS == OS.iOS
        ? IOSCodeConfig(targetSdk: IOSSdk.iPhoneOS, targetVersion: 17)
        : null,
    macOS: targetOS == OS.macOS ? MacOSCodeConfig(targetVersion: 13) : null,
    android: targetOS == OS.android
        ? AndroidCodeConfig(targetNdkApi: 30)
        : null,
  );

  return testBuildHook(
    mainMethod: hook.main,
    userDefines: userDefines,
    extensions: [codeExtension, DataAssetsExtension()],
    check: check,
  );
}

void _expectCommunityEditionCache(BuildInput input) {
  final sharedEntries = Directory(input.outputDirectoryShared.toFilePath())
      .listSync()
      .whereType<Directory>()
      .map((dir) => p.basename(dir.path))
      .toList();

  expect(
    sharedEntries.any((name) => name.startsWith('cblite-community-')),
    isTrue,
    reason: 'Expected a community cblite cache directory in $sharedEntries.',
  );
  expect(
    sharedEntries.any((name) => name.startsWith('cblite-enterprise-')),
    isFalse,
    reason:
        'Did not expect an enterprise cblite cache directory in '
        '$sharedEntries.',
  );
}

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
  const cbliteId = 'package:cbl/src/bindings/cblite.dart';
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
      final sonameFiles = Directory(libDir)
          .listSync()
          .map((entity) => p.basename(entity.path))
          .where((name) => RegExp(r'^libcblite\.so\.\d+$').hasMatch(name))
          .toList();
      expect(sonameFiles, hasLength(1));
      // Unversioned symlink for the linker (-lcblite).
      expect(File(p.join(libDir, 'libcblite.so')).existsSync(), isTrue);
      // Code asset should be the soname version.
      expect(cbliteAsset.file!.toFilePath(), endsWith(sonameFiles.single));
    case OS.android:
      expect(File(p.join(libDir, 'libcblite.so')).existsSync(), isTrue);
    case OS.windows:
      expect(File(p.join(libDir, 'cblite.dll')).existsSync(), isTrue);
      expect(File(p.join(libDir, 'cblite.lib')).existsSync(), isTrue);
    default:
      break;
  }

  // --- cblitedart asset ---
  const cblitedartId = 'package:cbl/src/bindings/cblitedart.dart';
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
