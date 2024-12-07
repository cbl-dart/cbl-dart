import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';

Future<ProcessResult> runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool expectZeroExitCode = true,
  required Logger logger,
}) async {
  workingDirectory ??= Directory.current.path;

  logger.trace(
    'Running "$executable" in $workingDirectory with arguments $arguments',
  );

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );

  final (_, _, exitCode) = await (
    process.stdout.transform(utf8.decoder).drain(logger.trace),
    process.stderr.transform(utf8.decoder).drain(logger.trace),
    process.exitCode
  ).wait;

  logger.trace('"$executable" exited with code $exitCode');

  if (expectZeroExitCode && exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      'Expected exit code 0 but got $exitCode',
      exitCode,
    );
  }

  return ProcessResult(
    process.pid,
    exitCode,
    stdout,
    stderr,
  );
}

extension LoggerExtension on Logger {
  Future<T> runWithProgress<T>(
    Future<T> Function() action, {
    required String message,
    String? finishMessage,
    bool showTiming = false,
  }) async {
    final progress = this.progress(message);

    try {
      final result = await action();
      progress.finish(message: finishMessage, showTiming: showTiming);
      return result;
    } catch (_) {
      progress.cancel();
      rethrow;
    }
  }
}
