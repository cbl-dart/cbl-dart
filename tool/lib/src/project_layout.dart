import 'package:path/path.dart' as p;

final class ProjectLayout {
  ProjectLayout(this.rootDir);

  final String rootDir;

  late final packages = PackagesLayout(p.join(rootDir, 'packages'));
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
