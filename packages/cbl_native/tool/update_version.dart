import 'dart:io';

import 'package:yaml/yaml.dart';

const libPath = 'lib/cbl_native.dart';

Future<void> main() async {
  final pubspec = await loadPubspec();
  final version = pubspec['version'] as String;
  final name = pubspec['name'] as String;
  final tag = '$name-v$version';

  await updateVersion(version);
  await amendCommit();
  await updateTag(tag);
}

/// Sets `CblNativeBinaries.version` to the current value of `version` from
/// `pubspec.yaml`.
Future<void> updateVersion(String version) async {
  final libFile = File(libPath);
  final libContent = await libFile.readAsString();

  final updatedLib = libContent.replaceFirst(
    RegExp("'([^']+)'; // cbl_native: version"),
    "'$version'; // cbl_native: version",
  );

  await libFile.writeAsString(updatedLib);
}

/// Amends the last commit with changes in `lib/cbl_native.dart`.
Future<void> amendCommit() async {
  await exec('git', ['add', libPath]);
  await exec('git', ['commit', '--amend', '--no-edit']);
}

/// Deletes [tag] and tags the current commit with it.
Future<void> updateTag(String tag) async {
  await exec('git', ['tag', '-d', tag]);
  await exec('git', ['tag', '-m', tag, tag]);
}

Future<void> exec(String cmd, List<String> args) async {
  final result = await Process.run(cmd, args);
  if (result.exitCode != 0) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    exit(result.exitCode);
  }
}

Future<YamlMap> loadPubspec() async {
  final file = File('pubspec.yaml');
  final content = await file.readAsString();
  return loadYaml(content) as YamlMap;
}
