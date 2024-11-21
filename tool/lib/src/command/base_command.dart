import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';

import '../project_layout.dart';
import '../runner.dart';

abstract class BaseCommand extends Command<void> {
  @override
  CbdRunner? get runner => super.runner as CbdRunner?;

  late final projectLayout = ProjectLayout(runner!.projectDir);

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
