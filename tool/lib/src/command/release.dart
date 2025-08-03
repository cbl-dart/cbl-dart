import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../error.dart';
import 'base_command.dart';

final class ReleaseCommand extends BaseCommand {
  ReleaseCommand() {
    addSubcommand(ReleaseCblLibcbliteApiCommand());
    addSubcommand(ReleaseCblLibcblitedartApiCommand());
  }

  @override
  String get description => 'Create releases';

  @override
  String get name => 'release';

  @override
  Future<void> doRun() async {
    throw UsageException('Please specify what to release.', usage);
  }
}

abstract class ApiPackageReleaseCommand extends BaseCommand {
  String get packageName => name;

  String get packageDir =>
      path.join(projectLayout.rootDir, 'packages', packageName);

  late final String version;

  String get versionFilePath;

  @mustCallSuper
  List<String> get tags => ['$packageName-v$version'];

  @override
  String get description => 'Release $packageName package';

  @override
  String get invocation {
    final parents = [name];
    for (var command = parent; command != null; command = command.parent) {
      parents.add(command.name);
    }
    parents.add(runner!.executableName);

    return '${parents.reversed.join(' ')} <version>';
  }

  @override
  Future<void> doRun() async {
    if (argResults!.rest.length != 1) {
      throw UsageException('Please specify a version.', usage);
    }

    version = argResults!.rest.first;

    await _verifyRepoState();
    await _updateVersionFile();
    await _updatePubspecVersion();
    await _addChangelogEntry();
    await _commitChanges();
    await _tagRelease();
    await _publishPackage();
    await _pushToRemote();

    logger.stdout('Successfully released $packageName v$version');
  }

  Future<void> _verifyRepoState() async {
    logger.stdout('Verifying repository state...');

    // Check if on main branch
    final branchResult = await Process.run('git', ['branch', '--show-current']);
    if (branchResult.exitCode != 0) {
      throw ToolException(
        'Failed to get current branch',
        exitCode: branchResult.exitCode,
      );
    }
    final currentBranch = branchResult.stdout.toString().trim();
    if (currentBranch != 'main') {
      throw ToolException(
        'Must be on main branch to release. Current branch: $currentBranch',
      );
    }

    // Check if repo is clean
    final statusResult = await Process.run('git', ['status', '--porcelain']);
    if (statusResult.exitCode != 0) {
      throw ToolException(
        'Failed to check git status',
        exitCode: statusResult.exitCode,
      );
    }
    if (statusResult.stdout.toString().trim().isNotEmpty) {
      throw ToolException(
        'Repository is not clean. Please commit or stash changes.',
      );
    }

    logger.stdout('Repository state verified ✓');
  }

  Future<void> _updateVersionFile() async {
    logger.stdout('Updating version file...');

    final versionFile = File(versionFilePath);
    if (!versionFile.existsSync()) {
      throw ToolException('Version file not found: $versionFilePath');
    }

    await versionFile.writeAsString(version);
    logger.stdout('Updated $versionFilePath to $version ✓');
  }

  Future<void> _updatePubspecVersion() async {
    logger.stdout('Updating pubspec.yaml...');

    final pubspecPath = path.join(packageDir, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      throw ToolException('pubspec.yaml not found: $pubspecPath');
    }

    final content = await pubspecFile.readAsString();

    // Create new content with updated version
    final lines = content.split('\n');
    final updatedLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('version:')) {
        updatedLines.add('version: $version');
      } else {
        updatedLines.add(line);
      }
    }

    await pubspecFile.writeAsString(updatedLines.join('\n'));
    logger.stdout('Updated pubspec.yaml version to $version ✓');
  }

  Future<void> _addChangelogEntry() async {
    logger.stdout('Adding changelog entry...');

    final changelogPath = path.join(packageDir, 'CHANGELOG.md');
    final changelogFile = File(changelogPath);

    if (!changelogFile.existsSync()) {
      throw ToolException('CHANGELOG.md not found: $changelogPath');
    }

    final content = await changelogFile.readAsString();
    final newEntry =
        '## $version\n\n'
        ' - Bump "$packageName" to `$version`.\n\n';
    final updatedContent = newEntry + content;

    await changelogFile.writeAsString(updatedContent);
    logger.stdout('Added changelog entry for $version ✓');
  }

  Future<void> _commitChanges() async {
    logger.stdout('Committing changes...');

    final files = [
      versionFilePath,
      path.join(packageDir, 'pubspec.yaml'),
      path.join(packageDir, 'CHANGELOG.md'),
    ];

    // Add files to git
    for (final file in files) {
      final addResult = await Process.run('git', ['add', file]);
      if (addResult.exitCode != 0) {
        throw ToolException(
          'Failed to add $file to git',
          exitCode: addResult.exitCode,
        );
      }
    }

    // Commit changes
    final commitMessage = 'chore($packageName): $version release';
    final commitResult = await Process.run('git', [
      'commit',
      '-m',
      commitMessage,
    ]);
    if (commitResult.exitCode != 0) {
      throw ToolException(
        'Failed to commit changes',
        exitCode: commitResult.exitCode,
      );
    }

    logger.stdout('Committed changes ✓');
  }

  Future<void> _tagRelease() async {
    logger.stdout('Creating release tags...');

    // Create all tags
    for (final tagName in tags) {
      final tagResult = await Process.run('git', ['tag', tagName]);
      if (tagResult.exitCode != 0) {
        throw ToolException(
          'Failed to create tag $tagName',
          exitCode: tagResult.exitCode,
        );
      }
      logger.stdout('Created tag $tagName ✓');
    }
  }

  Future<void> _publishPackage() async {
    logger.stdout('Publishing package...');

    final publishResult = await Process.run('dart', [
      'pub',
      'publish',
      '--force',
    ], workingDirectory: packageDir);

    if (publishResult.exitCode != 0) {
      logger.stderr('Failed to publish package:\n${publishResult.stderr}');
      throw ToolException(
        'Failed to publish package',
        exitCode: publishResult.exitCode,
      );
    }

    logger.stdout('Package published successfully ✓');
  }

  Future<void> _pushToRemote() async {
    logger.stdout('Pushing to remote...');

    // Push commits
    final pushResult = await Process.run('git', ['push']);
    if (pushResult.exitCode != 0) {
      throw ToolException(
        'Failed to push commits',
        exitCode: pushResult.exitCode,
      );
    }

    // Push all tags
    for (final tagName in tags) {
      final pushTagResult = await Process.run('git', [
        'push',
        'origin',
        tagName,
      ]);
      if (pushTagResult.exitCode != 0) {
        throw ToolException(
          'Failed to push tag $tagName',
          exitCode: pushTagResult.exitCode,
        );
      }
    }

    logger.stdout('Pushed commits and tags to remote ✓');
  }
}

final class ReleaseCblLibcbliteApiCommand extends ApiPackageReleaseCommand {
  @override
  String get name => 'cbl_libcblite_api';

  @override
  String get versionFilePath =>
      path.join(projectLayout.rootDir, 'native', 'CouchbaseLiteC.release');
}

final class ReleaseCblLibcblitedartApiCommand extends ApiPackageReleaseCommand {
  @override
  String get name => 'cbl_libcblitedart_api';

  @override
  String get versionFilePath => path.join(
    projectLayout.rootDir,
    'native',
    'couchbase-lite-dart',
    'CouchbaseLiteDart.version',
  );

  @override
  List<String> get tags => [...super.tags, 'libcblitedart-v$version'];
}
