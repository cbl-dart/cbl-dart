import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_launcher/cli_launcher.dart';

import 'command/install_packages.dart';
import 'error.dart';

final class CbdRunner extends CommandRunner<void> {
  CbdRunner({required this.projectDir})
      : super('cbd', 'CBL Dart dev tools CLI') {
    addCommand(InstallPackages());
  }

  final String projectDir;

  static Future<void> launch(
    List<String> args,
    LaunchContext context,
  ) async {
    final runner =
        CbdRunner(projectDir: context.localInstallation!.packageRoot.path);

    try {
      await runner.run(args);
    } on UsageException catch (error) {
      stdout.writeln(error);
      exitCode = 64;
    } on ToolException catch (error) {
      stderr.writeln(error);
      exitCode = error.exitCode;
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      stderr
        ..writeln('An unexpected error occurred: $error')
        ..writeln(stackTrace);
      exitCode = 1;
    }
  }
}
