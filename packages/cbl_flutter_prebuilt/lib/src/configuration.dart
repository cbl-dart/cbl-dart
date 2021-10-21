const templatePackageDir = './template_package';
const templateFileMarker = '__template__';
const buildDir = './build';

final packageNames = {
  Edition.community: 'cbl_flutter_ce',
  Edition.enterprise: 'cbl_flutter_ee',
};

final packageConfigurations = [
  for (final edition in Edition.values)
    PackageConfiguration(
      name: packageNames[edition]!,
      edition: edition,
      couchbaseLiteC: const LibraryInfo(
        version: '3.0.0',
        release: '3.0.0-beta01',
      ),
      couchbaseLiteDart: const LibraryInfo(
        version: '1.0.0',
        release: '1.0.0-beta.0',
      ),
    )
];

enum Edition { community, enterprise }

class LibraryInfo {
  const LibraryInfo({required this.version, required this.release});

  final String version;
  final String release;
}

class PackageConfiguration {
  const PackageConfiguration({
    required this.name,
    required this.edition,
    required this.couchbaseLiteC,
    required this.couchbaseLiteDart,
  });

  final String name;
  final Edition edition;
  final LibraryInfo couchbaseLiteC;
  final LibraryInfo couchbaseLiteDart;
}
