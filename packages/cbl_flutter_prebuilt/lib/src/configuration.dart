import 'dart:io';

// ignore: implementation_imports
import 'package:cbl/src/install.dart';
// ignore: implementation_imports
import 'package:cbl_flutter/src/install.dart';
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

PrebuiltPackageConfiguration _loadPackageConfiguration(Edition edition) {
  final name = packageNames[edition]!;
  final pubspecPath = p.join(buildDir, name, 'pubspec.yaml');
  final pubspecFile = File(pubspecPath);
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final version = pubspec['version']! as String;
  final dependencies = pubspec['dependencies']! as YamlMap;
  final couchbaseLiteCVersion = dependencies['cbl_libcblite_api']! as String;
  final couchbaseLiteDartVersion =
      dependencies['cbl_libcblitedart_api']! as String;

  return PrebuiltPackageConfiguration(
    name: name,
    version: version,
    edition: edition,
    libraries: [
      LibraryVersionInfo(
        library: Library.libcblite,
        version: couchbaseLiteCVersion,
        release: _couchbaseLiteCReleaseOverrides[couchbaseLiteCVersion] ??
            couchbaseLiteCVersion,
      ),
      LibraryVersionInfo(
        library: Library.libcblitedart,
        version: couchbaseLiteDartVersion,
        release: _couchbaseLiteDartReleaseOverrides[couchbaseLiteDartVersion] ??
            couchbaseLiteDartVersion,
      )
    ],
  );
}

final packageConfigurations = [
  for (final edition in Edition.values) _loadPackageConfiguration(edition)
];
