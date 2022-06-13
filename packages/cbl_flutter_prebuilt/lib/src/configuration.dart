import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

const templatePackageDir = './template_package';
const templateFileMarker = '__template__';
const buildDir = '..';

final packageNames = {
  Edition.community: 'cbl_flutter_ce',
  Edition.enterprise: 'cbl_flutter_ee',
};

const _couchbaseLiteCReleaseOverrides = <String, String>{};
const _couchbaseLiteDartReleaseOverrides = <String, String>{};

PackageConfiguration _loadPackageConfiguration(Edition edition) {
  final name = packageNames[edition]!;
  final pubspecPath = p.join(buildDir, name, 'pubspec.yaml');
  final pubspecFile = File(pubspecPath);
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final version = pubspec['version']! as String;
  final dependencies = pubspec['dependencies']! as YamlMap;
  final couchbaseLiteCVersion = dependencies['cbl_libcblite_api']! as String;
  final couchbaseLiteDartVersion =
      dependencies['cbl_libcblitedart_api']! as String;

  return PackageConfiguration(
    name: name,
    version: version,
    edition: edition,
    couchbaseLiteC: LibraryInfo(
      version: couchbaseLiteCVersion,
      release: _couchbaseLiteCReleaseOverrides[couchbaseLiteCVersion] ??
          couchbaseLiteCVersion,
    ),
    couchbaseLiteDart: LibraryInfo(
      version: couchbaseLiteDartVersion,
      release: _couchbaseLiteDartReleaseOverrides[couchbaseLiteDartVersion] ??
          couchbaseLiteDartVersion,
    ),
  );
}

final packageConfigurations = [
  for (final edition in Edition.values) _loadPackageConfiguration(edition)
];

enum Edition { community, enterprise }

class LibraryInfo {
  const LibraryInfo({
    required this.version,
    required this.release,
    String? apiPackageRelease,
  }) : apiPackageRelease = apiPackageRelease ?? release;

  final String version;
  final String release;
  final String apiPackageRelease;
}

class PackageConfiguration {
  const PackageConfiguration({
    required this.name,
    required this.version,
    required this.edition,
    required this.couchbaseLiteC,
    required this.couchbaseLiteDart,
  });

  final String name;
  final String version;
  final Edition edition;
  final LibraryInfo couchbaseLiteC;
  final LibraryInfo couchbaseLiteDart;
}
