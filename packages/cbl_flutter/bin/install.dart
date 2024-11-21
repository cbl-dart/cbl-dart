// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cbl/src/install.dart';
import 'package:cbl_flutter/src/install.dart';

const androidJniLibsDir = 'android/src/main/jniLibs';
const iosFrameworksDir = 'ios/Frameworks';
const macosLibrariesDir = 'macos/Libraries';
const linuxLibDir = 'linux/lib';
const windowsBinDir = 'windows/bin';

void main(List<String> arguments) async {
  final os = OS.values.byName(arguments.single);
  final configFile = File('prebuilt_package_configuration.json');
  final configJson =
      jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
  final config = PrebuiltPackageConfiguration.fromJson(configJson);

  final installDir = Directory(switch (os) {
    OS.android => androidJniLibsDir,
    OS.iOS => iosFrameworksDir,
    OS.macOS => macosLibrariesDir,
    OS.linux => linuxLibDir,
    OS.windows => windowsBinDir,
  });

  if (installDir.existsSync()) {
    print(
      'Native libraries for Couchbase Lite for $os are already installed',
    );
    return;
  }

  print('Installing native libraries for Couchbase Lite for $os');

  final tmpInstallDir = Directory.systemTemp.createTempSync();

  try {
    final loader = RemotePackageLoader();

    final packageConfigs = <PackageConfig>[];

    // ignore: cascade_invocations
    packageConfigs.addAll(
      DatabasePackageConfig.all(
        releases: {
          for (final library in config.libraries) //
            library.library: library.release,
        },
        edition: config.edition,
      ).where((config) => config.os == os),
    );

    if (config.edition == Edition.enterprise) {
      packageConfigs.addAll(
        VectorSearchPackageConfig.all(release: '1.0.0')
            .where((config) => config.os == os),
      );
    }

    final packages = await Future.wait(packageConfigs.map(loader.load));

    for (final package in packages) {
      switch (package) {
        case DatabaseAndroidPackage(
            config: PackageConfig(:final architectures)
          ):
          for (final architecture in architectures) {
            await copyDirectoryContents(
              package.sharedLibrariesDir(architecture),
              '${tmpInstallDir.path}/${architecture.androidLibDir}',
              filter: (entity) => !entity.path.contains('cmake'),
            );
          }
        case DatabaseStandardPackage(
            config: PackageConfig(os: OS.iOS),
            :final packageDir,
          ):
          // Copy the XCFramework, that is already in the correct structure.
          await copyDirectoryContents(
            packageDir,
            tmpInstallDir.path,
            // Don't copy LICENSE files.
            filter: (entity) => entity.path.contains('.xcframework'),
          );
        case DatabaseStandardPackage(
            config: PackageConfig(os: OS.macOS || OS.linux || OS.windows),
            :final sharedLibrariesDir
          ):
          await copyDirectoryContents(
            sharedLibrariesDir,
            tmpInstallDir.path,
            dereferenceLinks: os == OS.macOS,
            filter: (entity) => !entity.path.contains('cmake'),
          );
        case VectorSearchPackage(
            config: PackageConfig(os: OS.android, :final architectures)
          ):
          await copyDirectoryContents(
            package.sharedLibrariesDir!,
            '${tmpInstallDir.path}/${architectures.single.androidLibDir}',
            filter: (entity) => !entity.path.contains('cmake'),
          );
        case VectorSearchPackage(
            config: PackageConfig(os: OS.iOS),
            :final packageDir,
          ):
          // Copy the XCFramework, that is already in the correct structure.
          await copyDirectoryContents(
            packageDir,
            tmpInstallDir.path,
            // Don't copy LICENSE files.
            filter: (entity) => entity.path.contains('.xcframework'),
          );
        case VectorSearchPackage(
            config: PackageConfig(os: OS.macOS || OS.linux || OS.windows),
            :final sharedLibrariesDir,
          ):
          await copyDirectoryContents(
            sharedLibrariesDir!,
            tmpInstallDir.path,
            dereferenceLinks: os == OS.macOS,
            filter: (entity) => !entity.path.contains('cmake'),
          );
        default:
          throw UnimplementedError();
      }
    }

    tmpInstallDir.renameSync(installDir.path);
  } catch (e) {
    tmpInstallDir.deleteSync(recursive: true);
    rethrow;
  }
}

extension on Architecture {
  String get androidLibDir => switch (this) {
        Architecture.arm => 'armeabi-v7a',
        Architecture.arm64 => 'arm64-v8a',
        Architecture.ia32 => 'x86',
        Architecture.x64 => 'x86_64',
      };
}
