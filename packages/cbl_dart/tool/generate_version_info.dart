import 'dart:io';

import 'package:cbl/src/install.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main() {
  final latestReleases = _readLatestReleasesFromPubspec();
  File(
    p.absolute('lib/src/version_info.dart'),
  ).writeAsStringSync(_generateVersionInfoFile(latestReleases));
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
