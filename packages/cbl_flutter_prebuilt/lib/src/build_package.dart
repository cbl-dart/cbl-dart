import 'dart:io';

import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;

import 'configuration.dart';
import 'template_context.dart';
import 'utils.dart';

Future<void> buildPackage(PackageConfiguration configuration) async {
  final packageBuildDir = p.join(buildDir, configuration.name);
  final packageBuildDirectory = Directory(packageBuildDir);

  // Clean the package build dir and ensure it exists
  if (packageBuildDirectory.existsSync()) {
    await packageBuildDirectory.delete(recursive: true);
  }
  await packageBuildDirectory.create(recursive: true);

  await _renderTemplateDirectory(
    templateDirectory: Directory(templatePackageDir),
    outputDirectory: Directory(packageBuildDir),
    templateContext: createTemplateContext(configuration: configuration),
  );
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
  final chmodResult = await Process.run('chmod', ['--reference', from, file]);

  if (chmodResult.exitCode != 0) {
    throw StateError(
      'Could not set mode of copied file: $file\n'
      '${chmodResult.stdout}\n'
      '${chmodResult.stderr}',
    );
  }
}
