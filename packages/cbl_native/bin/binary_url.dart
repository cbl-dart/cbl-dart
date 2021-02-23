import 'dart:io' as io;

import 'package:cbl_native/cbl_native.dart';
import 'package:collection/collection.dart';

Future<void> main(List<String> args) async {
  final platform = parseArgs(args);

  final binary = CblNativeBinaries(platform: platform);

  print(binary.url);
}

Platform parseArgs(List<String> args) {
  if (args.length != 1) {
    usageError('Please pass a platform.');
  }

  final platformArg = args.first;

  final platform = Platform.values
      .firstWhereOrNull((element) => element.platformName() == platformArg);

  if (platform == null) {
    final platformNames =
        Platform.values.map((it) => it.platformName()).toList();
    usageError('Please pass a valid platform: $platformNames');
  }

  return platform;
}

Never usageError(String message) {
  print(message);
  printUsage();
  io.exit(64);
}

void printUsage() {
  print('''

Usage:
  
  dart run cbl_native:binary_url <platform>

Prints the url from which the binary archive for the given platform can be 
downloaded.
''');
}
