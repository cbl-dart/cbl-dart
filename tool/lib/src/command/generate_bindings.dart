// ignore_for_file: cascade_invocations

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

import '../ffigen_config.dart';
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

    // Generate cblite first since cblitedart imports its symbols.
    await cbliteGenerator.generate();
    await cblitedartGenerator.generate();
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
    await _formatBindings();
  }

  Future<FfigenConfig> _loadFfigenConfig() =>
      FfigenConfig.load(p.join(packageDir, ffigenConfig));

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

  Future<void> _formatBindings() async {
    await logger.runWithProgress(
      message: 'Formatting bindings from $ffigenConfig',
      showTiming: true,
      () async {
        final ffigenConfig = await _loadFfigenConfig();
        await runProcess('daco', [
          'format',
          ffigenConfig.output!.bindings!,
        ], logger: logger);
      },
    );
  }
}
