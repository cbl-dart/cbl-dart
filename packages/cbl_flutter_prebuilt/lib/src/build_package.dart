import 'dart:convert';
import 'dart:io';

import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

import 'configuration.dart';
import 'template_context.dart';
import 'utils.dart';

Future<void> buildPackage(PackageConfiguration configuration) async {
  void log(String message) {
    // ignore: avoid_print
    print('${configuration.name}: $message');
  }

  log('Building package');

  final packageBuildDir = p.join(buildDir, configuration.name);
  final packageBuildDirectory = Directory(packageBuildDir);

  final templateDirectory = Directory(templatePackageDir);
  final templateContext = createTemplateContext(configuration: configuration);

  final templateContextJson =
      // ignore: avoid_annotating_with_dynamic
      JsonEncoder.withIndent('  ', (dynamic value) {
    if (value is Function) {
      return '<lambda>';
    }
    return null;
  }).convert(templateContext);
  log('Template context:\n$templateContextJson');

  await _renderTemplateDirectory(
    templateDirectory: templateDirectory,
    outputDirectory: packageBuildDirectory,
    templateContext: templateContext,
  );

  await _formatDartCode(directory: packageBuildDirectory);
}

Future<void> _renderTemplateDirectory({
  required Directory templateDirectory,
  required Directory outputDirectory,
  required JsonMap templateContext,
}) async {
  final allEntities =
      templateDirectory.list(recursive: true, followLinks: false);

  await for (final entity in allEntities) {
    final isTemplate = p.basename(entity.path).contains(templateFileMarker);

    String outputPath;
    // Calculate the relative path of the entity in the template directory.
    outputPath = p.relative(entity.path, from: templateDirectory.path);

    // Prepend the output directory.
    outputPath = p.join(outputDirectory.path, outputPath);

    // Remove the template marker from the output path.
    if (isTemplate) {
      outputPath = outputPath.replaceAll(templateFileMarker, '');
    }

    // Expand the output path as a template.
    outputPath = Template(outputPath).renderString(templateContext);

    if (entity is Directory) {
      // Recreate the directory
      final outputDirectory = Directory(outputPath);
      await outputDirectory.create();

      await _copyFilePermissions(outputPath, from: entity.path);
    } else if (entity is Link) {
      // Just copy the link as is.
      final outputLink = Link(outputPath);
      final linkTarget = await entity.target();
      if (p.isAbsolute(linkTarget)) {
        throw StateError(
          'Links in template directory must be relative: $linkTarget.',
        );
      }
      await outputLink.create(linkTarget);
    } else if (entity is File) {
      final outputFile = File(outputPath);

      if (isTemplate) {
        // Render template file.
        final template = Template(await entity.readAsString());
        await outputFile.writeAsString(template.renderString(templateContext));
      } else {
        // Just copy the link as is.
        await outputFile.writeAsBytes(await entity.readAsBytes());
      }

      await outputFile.setLastModified(entity.lastModifiedSync());
      await _copyFilePermissions(outputPath, from: entity.path);
    }
  }
}

Future<void> _copyFilePermissions(
  String file, {
  required String from,
}) async {
  if (Platform.isWindows) {
    final result = await Process.run('powershell.exe', [
      '-Command',
      'Get-Acl -Path "$from" | Set-Acl -Path "$file"',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Could not set mode of copied file: $file\n'
        '${result.stdout}\n'
        '${result.stderr}',
      );
    }
  } else if (Platform.isLinux) {
    final result = await Process.run('chmod', ['--reference', from, file]);
    if (result.exitCode != 0) {
      throw StateError(
        'Could not set mode of copied file: $file\n'
        '${result.stdout}\n'
        '${result.stderr}',
      );
    }
  } else if (Platform.isMacOS) {
    final statResult = await Process.run('stat', ['-f', '%p', from]);
    if (statResult.exitCode != 0) {
      throw StateError(
        'Could not get permissions of file: $from\n'
        '${statResult.stdout}\n'
        '${statResult.stderr}',
      );
    }

    final octalMode = (statResult.stdout as String).trim().substring(2);

    final chmodResult = await Process.run('chmod', [octalMode, file]);
    if (chmodResult.exitCode != 0) {
      throw StateError(
        'Could not set mode of copied file: $file\n'
        '${chmodResult.stdout}\n'
        '${chmodResult.stderr}',
      );
    }
  } else {
    throw UnimplementedError(
      'Copying file permission is not implemented on this platform',
    );
  }
}

Future<void> _formatDartCode({required Directory directory}) async {
  final result = await Process.run('dart', ['format', directory.path]);
  if (result.exitCode != 0) {
    throw StateError(
      'Could not format dart code in: $directory\n'
      '${result.stdout}\n'
      '${result.stderr}',
    );
  }
}
