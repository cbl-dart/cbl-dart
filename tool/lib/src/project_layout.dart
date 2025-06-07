// ignore: implementation_imports
import 'package:cbl/src/install.dart';
import 'package:path/path.dart' as p;

final class ProjectLayout {
  ProjectLayout(this.rootDir);

  final String rootDir;

  late final native = NativeLayout(p.join(rootDir, 'native'));
  late final packages = PackagesLayout(p.join(rootDir, 'packages'));
}

final class NativeLayout {
  NativeLayout(this.rootDir);

  final String rootDir;

  late final vendor = NativeVendorLayout(p.join(rootDir, 'vendor'));
}

final class NativeVendorLayout {
  NativeVendorLayout(this.rootDir);

  final String rootDir;

  String libraryPackagesDir(Library library) => switch (library) {
    Library.cblite => '$rootDir/couchbase-lite-C-prebuilt',
    Library.cblitedart => '$rootDir/couchbase-lite-Dart-prebuilt',
    Library.vectorSearch => '$rootDir/couchbase-lite-vector-search-prebuilt',
  };

  String libraryPackageDir(PackageConfig config) {
    final packageDir = [
      config.release,
      if (config is DatabasePackageConfig) config.edition.name,
      config.targetId,
    ].join('-');

    return '${libraryPackagesDir(config.library)}/$packageDir';
  }
}

final class PackagesLayout {
  PackagesLayout(this.rootDir);

  final String rootDir;

  late final cbl = PackageLayout(p.join(rootDir, 'cbl'));
}

final class PackageLayout {
  PackageLayout(this.rootDir);

  final String rootDir;
}
