// ignore: implementation_imports
import 'package:cbl/src/install.dart';

final class PrebuiltPackageConfiguration {
  const PrebuiltPackageConfiguration({
    required this.name,
    required this.version,
    required this.edition,
    required this.couchbaseLiteC,
    required this.couchbaseLiteDart,
  });

  factory PrebuiltPackageConfiguration.fromJson(Map<String, Object?> json) =>
      PrebuiltPackageConfiguration(
        name: json['name']! as String,
        version: json['version']! as String,
        edition: Edition.values.byName(json['edition']! as String),
        couchbaseLiteC: LibraryVersionInfo.fromJson(
          json['couchbaseLiteC']! as Map<String, Object?>,
        ),
        couchbaseLiteDart: LibraryVersionInfo.fromJson(
          json['couchbaseLiteDart']! as Map<String, Object?>,
        ),
      );

  final String name;
  final String version;
  final Edition edition;
  final LibraryVersionInfo couchbaseLiteC;
  final LibraryVersionInfo couchbaseLiteDart;

  Map<String, Object?> toJson() => {
        'name': name,
        'version': version,
        'edition': edition.name,
        'couchbaseLiteC': couchbaseLiteC.toJson(),
        'couchbaseLiteDart': couchbaseLiteDart.toJson(),
      };
}

final class LibraryVersionInfo {
  const LibraryVersionInfo({
    required this.version,
    required this.release,
  });

  factory LibraryVersionInfo.fromJson(Map<String, Object?> json) =>
      LibraryVersionInfo(
        version: json['version']! as String,
        release: json['release']! as String,
      );

  final String version;
  final String release;

  Map<String, Object?> toJson() => {
        'version': version,
        'release': release,
      };
}
