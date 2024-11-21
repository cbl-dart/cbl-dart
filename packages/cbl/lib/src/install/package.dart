// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

/// An archive format, in which [Package]s are distributed.
enum ArchiveFormat {
  zip,
  tarGz;

  String get _ext => switch (this) {
        ArchiveFormat.zip => 'zip',
        ArchiveFormat.tarGz => 'tar.gz'
      };
}

/// A library that is distributed as part of cbl-dart.
enum Library {
  libcblite,
  libcblitedart,
}

/// A Couchbase Lite edition.
enum Edition {
  community,
  enterprise,
}

/// An operating system.
enum OS {
  android,
  ios,
  macos,
  linux,
  windows,
}

/// A target for which a specific [Package] is distributed.
final class Target {
  Target._(this.os);

  static final android = Target._(OS.android);
  static final ios = Target._(OS.ios);
  static final macos = Target._(OS.macos);
  static final linux_x86_64 = _LinuxTarget('x86_64');
  static final windows_x86_64 = _WindowsTarget('x86_64');

  static final all = [android, ios, macos, linux_x86_64, windows_x86_64];

  static Target byId(String id) =>
      all.firstWhereOrNull((target) => target.id == id) ??
      (throw ArgumentError.value(id, 'id', 'Unknown target'));

  /// The target of the host machine.
  static Target get host {
    if (Platform.isMacOS) {
      return macos;
    }

    if (Platform.isLinux) {
      return linux_x86_64;
    }

    if (Platform.isWindows) {
      return windows_x86_64;
    }

    throw UnsupportedError('Unsupported host platform');
  }

  final OS os;

  /// The identifier for this target, as used in the package file names.
  String get id => os.name;

  ArchiveFormat get _archiveFormat => ArchiveFormat.zip;

  String get _libDir => 'lib';

  String _libraryName(Package package) => package.library.name;

  @override
  String toString() => id;
}

/// A linux [Target].
final class _LinuxTarget extends Target {
  _LinuxTarget(this.arch) : super._(OS.linux);

  final String arch;

  @override
  String get id => 'linux-$arch';

  @override
  ArchiveFormat get _archiveFormat => ArchiveFormat.tarGz;

  @override
  String get _libDir => p.join('lib', '$arch-linux-gnu');
}

/// A windows [Target].
final class _WindowsTarget extends Target {
  _WindowsTarget(this.arch) : super._(OS.windows);

  final String arch;

  @override
  String get id => 'windows-$arch';

  @override
  String get _libDir => 'bin';

  @override
  String _libraryName(Package package) =>
      package.library.name.replaceAll('lib', '');
}

/// A package though which a release of a [Library] is distributed.
final class Package {
  Package({
    required this.library,
    required this.release,
    required this.edition,
    required this.target,
  });

  static final _cacheDir = p.join(userCachesDir, 'cbl_native_package');

  static final _archiveUrlResolvers = <Library, String Function(Package)>{
    Library.libcblite: (package) => 'https://packages.couchbase.com/releases/'
        'couchbase-lite-c/${package.release}/'
        'couchbase-lite-c-${package.edition.name}-${package.release}-'
        '${package.target.id}.${package._archiveFormat._ext}',
    Library.libcblitedart: (package) =>
        'https://github.com/cbl-dart/cbl-dart/releases/download/'
        'libcblitedart-v${package.release}/'
        'couchbase-lite-dart-${package.release}-${package.edition.name}-'
        '${package.target.id}.${package._archiveFormat._ext}'
  };

  final Library library;
  final String release;
  final Edition edition;
  final Target target;

  String get version => release.split('-').first;

  String get includeDir => p.join(packageDir, 'include');

  String get libDir => p.join(packageDir, target._libDir);

  String get libraryName => target._libraryName(this);

  ArchiveFormat get _archiveFormat => target._archiveFormat;

  String get _archiveUrl => _archiveUrlResolvers[library]!(this);

  String get _archiveBaseName =>
      p.basenameWithoutExtension(Uri.parse(_archiveUrl).path);

  String get archiveDir => p.join(_cacheDir, _archiveBaseName);

  String get packageDir => p.join(archiveDir, '${library.name}-$version');

  Future<void> acquire() async {
    final archiveDirectory = Directory(archiveDir);
    if (archiveDirectory.existsSync()) {
      return;
    }

    final tempDirectory = await Directory.systemTemp.createTemp();
    try {
      final archiveData = await downloadUrl(_archiveUrl);
      await unpackArchive(
        archiveData,
        format: _archiveFormat,
        outputDir: tempDirectory.path,
      );
      try {
        await moveDirectory(tempDirectory, archiveDirectory);
      } on PathExistsException {
        // Another process has already downloaded the archive.
      }
    } finally {
      await tempDirectory.delete(recursive: true);
    }
  }
}
