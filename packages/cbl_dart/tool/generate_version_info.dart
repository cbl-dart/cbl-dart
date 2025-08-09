import 'dart:io';

import 'package:cbl/src/install.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main() {
  const versionInfoFilePath = 'lib/src/version_info.dart';
  final latestReleases = _readLatestReleasesFromPubspec();
  File(
    p.absolute(versionInfoFilePath),
  ).writeAsStringSync(_generateVersionInfoFile(latestReleases));

  // Format file with daco format .
  final formatResult = Process.runSync('daco', ['format', versionInfoFilePath]);

  if (formatResult.exitCode != 0) {
    throw Exception(
      'Failed to format $versionInfoFilePath:\n'
      'Exit code: ${formatResult.exitCode}\n'
      '${formatResult.stdout}\n'
      '${formatResult.stderr}',
    );
  }
}

Map<Library, String> _readLatestReleasesFromPubspec() {
  final pubspecPath = p.absolute('pubspec.yaml');
  final pubspecContent = File(pubspecPath).readAsStringSync();
  final pubspecYaml =
      loadYamlDocument(
            pubspecContent,
            sourceUrl: Uri.parse(pubspecPath),
          ).contents
          as YamlMap;
  final dependencies = pubspecYaml['dependencies'] as YamlMap;
  return {
    Library.cblite: dependencies['cbl_libcblite_api']! as String,
    Library.cblitedart: dependencies['cbl_libcblitedart_api']! as String,
  };
}

String _generateVersionInfoFile(Map<Library, String> latestReleases) =>
    '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore: implementation_imports
import 'package:cbl/src/install.dart';

const latestReleases = {
  ${latestReleases.entries.map((entry) => "${entry.key}: '${entry.value}',").join('\n  ')}
};
''';
