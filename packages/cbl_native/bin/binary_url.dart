import 'dart:io' as io;
import 'dart:io';

import 'package:cbl_native/cbl_native.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  final config = parseArgs(args);

  final binary = CblNativeBinaries(platform: config.platform);

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

  Directory? installDir;
  if (args.contains('--install')) {
    final installOptIndex = args.indexOf('--install');
    final installDirInput = args.asMap()[installOptIndex + 1];
    if (installDirInput == null || installDirInput.startsWith('-')) {
      usageError('Please pass a installDir');
    } else {
      installDir = Directory(installDirInput).absolute;
    }

    args.removeRange(installOptIndex, installOptIndex + 2);
  }

  var overrideInstallDir = false;
  if (args.contains('--overrideInstallDir')) {
    overrideInstallDir = true;
    args.remove('--overrideInstallDir');
  }

  return Configuration(
    platform: platform,
    installDir: installDir,
    overrideInstallDir: overrideInstallDir,
  );
}

class Configuration {
  Configuration({
    required this.platform,
    required this.installDir,
    required this.overrideInstallDir,
  });

  final Platform platform;
  final Directory? installDir;
  final bool overrideInstallDir;
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
''');
}
