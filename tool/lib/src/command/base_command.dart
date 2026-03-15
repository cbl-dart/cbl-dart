import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../project_layout.dart';
import '../runner.dart';

abstract class BaseCommand extends Command<void> {
  @override
  CbdRunner? get runner => super.runner as CbdRunner?;

  bool get verbose => globalResults!['verbose'] as bool;

  late final logger = verbose ? Logger.verbose() : Logger.standard();

  late final projectLayout = ProjectLayout(_findProjectRoot());

  @visibleForOverriding
  Future<void> doRun();

  @protected
  T arg<T>(String name) {
    try {
      return argResults![name]! as T;
      // ignore: avoid_catching_errors
    } on ArgumentError catch (error) {
      usageException(error.toString());
    }
  }

  @protected
  T? optionalArg<T>(String name) => argResults![name] as T?;

  @override
  @mustCallSuper
  Future run() async => doRun();
}

/// Finds the project root by walking up from the current working directory,
/// looking for a workspace root `pubspec.yaml` (one that contains a
/// `workspace:` key).
String _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (RegExp('^workspace:', multiLine: true).hasMatch(content)) {
        return dir.path;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not find project root (no pubspec.yaml with '
        '"workspace:" found).',
      );
    }
    dir = parent;
  }
}
