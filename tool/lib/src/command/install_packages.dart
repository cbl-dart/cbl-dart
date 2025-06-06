import 'dart:io';

// ignore: implementation_imports
import 'package:cbl/src/install.dart';

import '../project_layout.dart';
import 'base_command.dart';

final class InstallPackages extends BaseCommand {
  InstallPackages() {
    argParser
      ..addOption(
        'library',
        abbr: 'l',
        help: 'The library to install packages for.',
        allowed: Library.values.map((value) => value.name),
        mandatory: true,
      )
      ..addOption(
        'edition',
        abbr: 'e',
        help: 'The Couchbase Lite edition to install packages for.',
        allowed: Edition.values.map((value) => value.name),
        mandatory: true,
      )
      ..addOption(
        'release',
        abbr: 'r',
        help: 'The release version of the packages to install.',
        mandatory: true,
      )
      ..addOption(
        'os',
        help:
            'Optionally only install the package for the given OS. If not '
            'provided, the packages for all supported OSes will be installed.',
        allowed: OS.values.map((value) => value.name),
      );
  }

  @override
  String get description => 'Installs Couchbase Lite native packages.';

  @override
  String get name => 'install-packages';

  Library get _library => Library.values.byName(arg('library'));

  Edition get _edition => Edition.values.byName(arg('edition'));

  String get _release => arg('release');

  OS? get _os {
    if (optionalArg<String>('os') case final os?) {
      return OS.values.byName(os);
    } else {
      return null;
    }
  }

  @override
  Future<void> doRun() async {
    List<PackageConfig> packageConfigs;

    switch (_library) {
      case Library.cblite || Library.cblitedart:
        packageConfigs = [
          ...DatabasePackageConfig.all(
            releases: {_library: _release},
            edition: _edition,
          ),
        ];
      case Library.vectorSearch:
        if (_edition != Edition.enterprise) {
          throw Exception(
            'Vector Search is only available for the Enterprise edition.',
          );
        }
        packageConfigs = VectorSearchPackageConfig.all(release: _release);
    }

    if (_os case final os?) {
      packageConfigs = packageConfigs
          .where((config) => config.os == os)
          .toList();
    }

    await Future.wait(
      packageConfigs.map(
        (config) => installPackageForDevelopment(projectLayout, config),
      ),
    );
  }
}

Future<void> installPackageForDevelopment(
  ProjectLayout projectLayout,
  PackageConfig config,
) async {
  final installDir = projectLayout.native.vendor.libraryPackageDir(config);

  if (Directory(installDir).existsSync()) {
    return;
  }

  final loader = RemotePackageLoader();
  final package = await loader.load(config);

  await copyDirectoryContents(package.packageDir, installDir);
}
