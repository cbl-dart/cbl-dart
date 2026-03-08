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

  if (logger.isVerbose) {
    logger
      ..trace('Running process in $workingDirectory')
      ..trace('$executable ${arguments.map((arg) => '"$arg"').join(' ')}');
  }

  // Resolve the executable path. When run from a globally activated package,
  // the default PATH may not include tools like `dart` or `daco`.
  final resolvedExecutable = switch (executable) {
    'dart' => Platform.resolvedExecutable,
    _ => _resolveExecutable(executable),
  };

  final process = await Process.start(
    resolvedExecutable,
    arguments,
    workingDirectory: workingDirectory,
  );

  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  // Tee to logger.trace while capturing
  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((chunk) {
        stdoutBuffer.writeln(chunk);
        logger.trace(chunk);
      })
      .drain<void>();
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((chunk) {
        stderrBuffer.writeln(chunk);
        logger.trace(chunk);
      })
      .drain<void>();

  final exitCode = await process.exitCode;
  await stdoutDone;
  await stderrDone;

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
    stdoutBuffer.toString(),
    stderrBuffer.toString(),
  );
}

/// Resolves an executable by looking it up in the pub cache bin directory,
/// falling back to the executable name itself.
String _resolveExecutable(String executable) {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null) {
    final pubCacheBin = '$home/.pub-cache/bin/$executable';
    if (File(pubCacheBin).existsSync()) {
      return pubCacheBin;
    }
  }
  return executable;
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
