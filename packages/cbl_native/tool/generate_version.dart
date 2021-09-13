import 'dart:io';

import 'package:yaml/yaml.dart';

const versionFilePath = 'lib/version.g.dart';

Future<void> main() async {
  final pubspec = await loadPubspec();
  final version = pubspec['version'] as String;
  await generateVersion(version);
}

Future<YamlMap> loadPubspec() async {
  final file = File('pubspec.yaml');
  final content = await file.readAsString();
  return loadYaml(content) as YamlMap;
}

Future<void> generateVersion(String version) async {
  final versionFile = File(versionFilePath);

  await versionFile.writeAsString('''
// DO NOT EDIT. THIS FILE IS GENERATED.

/// The current version of `cbl_native`.
const cblNativeVersion = '$version';
''');
}
