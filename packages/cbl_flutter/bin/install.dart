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
    OS.ios => iosFrameworksDir,
    OS.macos => macosLibrariesDir,
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

  final loader = RemotePackageLoader();
  final packageConfigs = DatabasePackageConfig.all(
    releases: {
      for (final library in config.libraries) //
        library.library: library.release,
    },
    edition: config.edition,
  ).where((config) => config.os == os);
  final packages = await Future.wait(packageConfigs.map(loader.load));

  try {
    for (final package in packages) {
      switch (package.config.os) {
        case OS.android:
          final AndroidPackage(config: PackageConfig(:architectures)) =
              package as AndroidPackage;
          for (final architecture in architectures) {
            await copyDirectoryContents(
              package.sharedLibrariesDir(architecture),
              '${tmpInstallDir.path}/${architecture.androidLibDir}',
              filter: (entity) => !entity.path.contains('cmake'),
            );
          }
        case OS.ios:
          final StandardPackage(:baseDir) = package as StandardPackage;
          // Copy the XCFramework, that is already in the correct structure.
          await copyDirectoryContents(
            baseDir,
            tmpInstallDir.path,
            // Don't copy LICENSE files.
            filter: (entity) => entity.path.contains('.xcframework'),
          );
        case OS.macos || OS.linux || OS.windows:
          final StandardPackage(:sharedLibrariesDir) =
              package as StandardPackage;
          await copyDirectoryContents(
            sharedLibrariesDir,
            tmpInstallDir.path,
            dereferenceLinks: os == OS.macos,
            filter: (entity) => !entity.path.contains('cmake'),
          );
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
        Architecture.x86 => 'x86',
        Architecture.x86_64 => 'x86_64',
      };
}
