// ignore_for_file: cascade_invocations

import 'package:cli_util/cli_logging.dart';

import '../utils.dart';
import 'base_command.dart';

final class GenerateBindings extends BaseCommand {
  @override
  String get name => 'generate-bindings';

  @override
  String get description => 'Regenerates FFI bindings.';

  @override
  Future<void> doRun() async {
    final cbliteGenerator = _BindingsGenerator(
      packageDir: projectLayout.packages.cbl.rootDir,
      ffigenConfig: 'cblite_ffigen.yaml',
      logger: logger,
    );
    final cblitedartGenerator = _BindingsGenerator(
      packageDir: projectLayout.packages.cbl.rootDir,
      ffigenConfig: 'cblitedart_ffigen.yaml',
      logger: logger,
    );

    final generators = [cbliteGenerator, cblitedartGenerator];

    for (final generator in generators) {
      await generator.generate();
    }
  }
}

class _BindingsGenerator {
  _BindingsGenerator({
    required this.packageDir,
    required this.ffigenConfig,
    required this.logger,
  });

  final String packageDir;
  final String ffigenConfig;
  final Logger logger;

  Future<void> generate() async {
    await _runFfigen();
  }

  Future<void> _runFfigen() async {
    await logger.runWithProgress(
      message: 'Running ffigen for $ffigenConfig',
      showTiming: true,
      () async {
        await runProcess(
          'dart',
          ['run', 'ffigen', '--config', ffigenConfig],
          workingDirectory: packageDir,
          logger: logger,
        );
      },
    );
  }
}
