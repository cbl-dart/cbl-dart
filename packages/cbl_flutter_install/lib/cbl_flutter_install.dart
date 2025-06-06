// ignore: implementation_imports
import 'package:cbl/src/install.dart';

final class PrebuiltPackageConfiguration {
  const PrebuiltPackageConfiguration({
    required this.name,
    required this.version,
    required this.cblFlutterInstallVersion,
    required this.edition,
    required this.libraries,
  });

  factory PrebuiltPackageConfiguration.fromJson(Map<String, Object?> json) =>
      PrebuiltPackageConfiguration(
        name: json['name']! as String,
        version: json['version']! as String,
        cblFlutterInstallVersion: json['cblFlutterInstallVersion']! as String,
        edition: Edition.values.byName(json['edition']! as String),
        libraries: [
          for (final library in json['libraries']! as List<Object?>)
            LibraryVersionInfo.fromJson(library! as Map<String, Object?>),
        ],
      );

  final String name;
  final String version;
  final String cblFlutterInstallVersion;
  final Edition edition;
  final List<LibraryVersionInfo> libraries;

  Map<String, Object?> toJson() => {
    'name': name,
    'version': version,
    'cblFlutterInstallVersion': cblFlutterInstallVersion,
    'edition': edition.name,
    'libraries': libraries.map((library) => library.toJson()).toList(),
  };
}

final class LibraryVersionInfo {
  const LibraryVersionInfo({
    required this.library,
    required this.version,
    required this.release,
  });

  factory LibraryVersionInfo.fromJson(Map<String, Object?> json) =>
      LibraryVersionInfo(
        library: Library.values.byName(json['library']! as String),
        version: json['version']! as String,
        release: json['release']! as String,
      );

  final Library library;
  final String version;
  final String release;

  Map<String, Object?> toJson() => {
    'library': library.name,
    'version': version,
    'release': release,
  };
}
