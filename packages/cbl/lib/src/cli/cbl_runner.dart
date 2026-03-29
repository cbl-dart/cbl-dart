import 'dart:io';

import 'package:args/args.dart';

import '../native_libraries.dart';

Future<void> runCblCli(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addMultiOption(
      'edition',
      allowed: Edition.values.map((it) => it.name),
      help: 'Editions to assemble. Repeat to include multiple editions.',
    )
    ..addMultiOption(
      'platform',
      allowed: [
        OS.android.name,
        OS.iOS.name,
        OS.macOS.name,
        OS.linux.name,
        OS.windows.name,
      ],
    )
    ..addMultiOption(
      'architecture',
      allowed: Architecture.values.map((it) => it.name),
    )
    ..addFlag('vector-search', negatable: true, defaultsTo: null)
    ..addOption('output', defaultsTo: 'build/cbl-native-libraries');

  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printUsage(parser);
    return;
  }

  if (args.length < 2 ||
      args[0] != 'native-libraries' ||
      args[1] != 'assemble') {
    stderr.writeln('Expected: cbl native-libraries assemble [options]');
    _printUsage(parser);
    exitCode = 64;
    return;
  }

  final parsed = parser.parse(args.skip(2).toList());
  if (parsed['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final defaults = readHookUserDefines();
  final request = applyCliOverrides(defaults, parsed);
  final plan = resolveNativeLibrariesPlan(request);

  for (final resolvedTarget in plan.targets) {
    final target = resolvedTarget.target;
    final targetDir = resolvedTarget.outputDirectory(plan.outputDirectory);
    await Directory(targetDir).create(recursive: true);

    await assembleCblite(
      outputDir: targetDir,
      edition: resolvedTarget.edition,
      os: target.os,
      architecture: target.architecture,
      iOSSdk: target.iOSSdk,
      mode: StageMode.symlink,
    );

    if (resolvedTarget.edition == Edition.enterprise &&
        plan.vectorSearch &&
        vectorSearchSupported(target.architecture)) {
      await assembleVectorSearch(
        outputDir: targetDir,
        os: target.os,
        architecture: target.architecture,
        iOSSdk: target.iOSSdk,
        mode: StageMode.symlink,
      );
    }
  }
}

void _printUsage(ArgParser parser) {
  stdout
    ..writeln('Usage: dart run cbl:cbl native-libraries assemble [options]')
    ..writeln(parser.usage);
}
