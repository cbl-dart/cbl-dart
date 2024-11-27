import 'dart:convert';
import 'dart:io';

import 'package:cbl/src/install.dart';
import 'package:cbl_flutter_install/cbl_flutter_install.dart';

const androidJniLibsDir = 'android/src/main/jniLibs';
const iosFrameworksDir = 'ios/Frameworks';
const macosLibrariesDir = 'macos/Libraries';
const macosFrameworksDir = 'macos/Frameworks';
const linuxLibDir = 'linux/lib';
const windowsBinDir = 'windows/bin';

void main(List<String> arguments) async {
  final os = OS.values.byName(arguments.single);
  final configFile = File('prebuilt_package_configuration.json');
  final configJson =
      jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
  final config = PrebuiltPackageConfiguration.fromJson(configJson);

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
    if (package.isAppleFramework) {
      final frameworksDir = switch (os) {
        OS.iOS => iosFrameworksDir,
        OS.macOS => macosFrameworksDir,
        _ => throw UnimplementedError(),
      };
      await copyDirectoryContents(
        package.appleFrameworkDir!,
        '$frameworksDir/${package.appleFrameworkName!}',
      );
    } else if (package.os == OS.android) {
      for (final architecture in package.config.architectures) {
        await copyDirectoryContents(
          package.sharedLibrariesDir(architecture)!,
          '$androidJniLibsDir/${architecture.androidLibDir}',
          filter: (entity) => !entity.path.contains('cmake'),
        );
      }
    } else {
      await copyDirectoryContents(
        package.singleSharedLibrariesDir!,
        switch (os) {
          OS.macOS => macosLibrariesDir,
          OS.linux => linuxLibDir,
          OS.windows => windowsBinDir,
          _ => throw UnimplementedError(),
        },
        dereferenceLinks: package.library.isDatabaseLibrary && os == OS.macOS,
        // Don't copy CMake files.
        filter: (entity) => !entity.path.contains('cmake'),
      );
    }
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
