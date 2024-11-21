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
  final target = Target.byId(arguments.single);
  final configFile = File('prebuilt_package_configuration.json');
  final configJson =
      jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
  final config = PrebuiltPackageConfiguration.fromJson(configJson);

  final installDir = Directory(switch (target.os) {
    OS.android => androidJniLibsDir,
    OS.ios => iosFrameworksDir,
    OS.macos => macosLibrariesDir,
    OS.linux => linuxLibDir,
    OS.windows => windowsBinDir,
  });

  if (installDir.existsSync()) {
    print(
      'Native libraries for Couchbase Lite for $target are already installed',
    );
    return;
  }

  print('Installing native libraries for Couchbase Lite for $target');

  final tmpInstallDir = Directory.systemTemp.createTempSync();

  final packages = [
    Package(
      library: Library.libcblite,
      release: config.couchbaseLiteC.release,
      edition: config.edition,
      target: target,
    ),
    Package(
      library: Library.libcblitedart,
      release: config.couchbaseLiteDart.release,
      edition: config.edition,
      target: target,
    ),
  ];

  await Future.wait(packages.map((package) => package.acquire()));

  try {
    switch (target.os) {
      case OS.android:
        for (final package in packages) {
          await copyDirectoryContents(
            package.libDir,
            tmpInstallDir.path,
            filter: (entity) => !entity.path.contains('cmake'),
          );
        }
        const architectureDirectoryMapping = {
          'aarch64-linux-android': 'arm64-v8a',
          'arm-linux-androideabi': 'armeabi-v7a',
          'i686-linux-android': 'x86',
          'x86_64-linux-android': 'x86_64',
        };
        for (final MapEntry(key: src, value: dest)
            in architectureDirectoryMapping.entries) {
          Directory('${tmpInstallDir.path}/$src')
              .renameSync('${tmpInstallDir.path}/$dest');
        }
      case OS.ios:
        for (final package in packages) {
          // Copy the XCFrameworks, that are already in the correct structure.
          await copyDirectoryContents(
            package.archiveDir,
            tmpInstallDir.path,
            // Don't copy LICENSE files.
            filter: (entity) => entity.path.contains('.xcframework'),
          );
        }
      case OS.macos || OS.linux || OS.windows:
        for (final package in packages) {
          await copyDirectoryContents(
            package.libDir,
            tmpInstallDir.path,
            dereferenceLinks: target.os == OS.macos,
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
