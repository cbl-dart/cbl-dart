// ignore_for_file: avoid_print

import 'dart:io' as io;
import 'dart:io';

import 'package:cbl_native/cbl_native.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  final config = parseArgs(args);

  final binary = CblNativeBinaries(
    platform: config.platform,
    version: config.version,
  );

  if (config.installDir == null) {
    print(binary.url);
  } else {
    await binary.install(
      installDir: config.installDir!,
      override: config.overrideInstallDir,
    );
  }
}

Configuration parseArgs(List<String> args) {
  // ignore_for_file: parameter_assignments
  args = args.toList();

  if (args.isEmpty) {
    usageError('Please pass a platform.');
  }

  final platformArg = args.removeAt(0);

  final platform = Platform.values
      .firstWhereOrNull((element) => element.platformName() == platformArg);

  if (platform == null) {
    final platformNames =
        Platform.values.map((it) => it.platformName()).toList();
    usageError('Please pass a valid platform: $platformNames');
  }

  String? parseOption(String name) {
    final cmdLineName = '--$name';

    if (args.contains(cmdLineName)) {
      final optionIndex = args.indexOf(cmdLineName);
      final optionValue = args.asMap()[optionIndex + 1];

      if (optionValue == null || optionValue.startsWith('-')) {
        usageError('Please pass a value for $cmdLineName');
      }

      args.removeRange(optionIndex, optionIndex + 2);

      return optionValue;
    }
  }

  bool parseFlag(String name) {
    final cmdLineName = '--$name';
    final isOnCmdLine = args.contains(cmdLineName);

    if (isOnCmdLine) {
      args.remove(cmdLineName);
    }

    return isOnCmdLine;
  }

  final installDirInput = parseOption('install');
  final installDir =
      installDirInput == null ? null : Directory(installDirInput).absolute;

  final version = parseOption('version') ?? currentVersion;

  final overrideInstallDir = parseFlag('overrideInstallDir');

  return Configuration(
    platform: platform,
    installDir: installDir,
    overrideInstallDir: overrideInstallDir,
    version: version,
  );
}

class Configuration {
  Configuration({
    required this.platform,
    required this.installDir,
    required this.overrideInstallDir,
    required this.version,
  });

  final Platform platform;
  final Directory? installDir;
  final bool overrideInstallDir;
  final String version;
}

Never usageError(String message) {
  print(message);
  printUsage();
  io.exit(64);
}

void printUsage() {
  print('''

Usage: dart run cbl_native:binary_url <platform> [option...]

Prints the url from which the binary archive for the given platform can be 
downloaded.

Options:

  --install <installDir> download and install the binaries into <installDir> 
                         instead of printing the url

  --overrideInstallDir   override the <installDir> if it already exists

  --version <version>    use a specific version instead of the current one
''');
}
