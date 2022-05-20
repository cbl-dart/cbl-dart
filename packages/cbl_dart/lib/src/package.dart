// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

/// An archive format, in which [Package]s are distributed.
enum ArchiveFormat {
  zip,
  tarGz,
}

extension ArchiveFormatExt on ArchiveFormat {
  String get ext {
    switch (this) {
      case ArchiveFormat.zip:
        return 'zip';
      case ArchiveFormat.tarGz:
        return 'tar.gz';
    }
  }
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

/// A linux distribution.
enum Distro { ubuntu }

/// A target for which a specific [Package] is distributed.
class Target {
  Target(this.os);

  static final android = Target(OS.android);
  static final ios = Target(OS.ios);
  static final macos = Target(OS.macos);
  static final ubuntu20_04_x86_64 =
      LinuxTarget(OS.linux, Distro.ubuntu, '20.04', 'x86_64');
  static final windows_x86_64 = WindowsTarget(OS.windows, 'x86_64');

  static final all = [android, ios, macos, ubuntu20_04_x86_64, windows_x86_64];

  /// The target of the host machine.
  static Target get host {
    if (Platform.isMacOS) {
      return macos;
    }

    if (Platform.isLinux) {
      // TODO(blaugold): detect distro and throw if not supported
      // The only currently supported Linux target is Ubuntu 20.04 x86_64.
      return ubuntu20_04_x86_64;
    }

    if (Platform.isWindows) {
      return windows_x86_64;
    }

    throw UnsupportedError('Unsupported host platform');
  }

  final OS os;

  /// The identifier for this target, as used in the package file names.
  String get id => os.name;

  ArchiveFormat get archiveFormat => ArchiveFormat.zip;

  String get librariesDir => 'lib';

  String libraryName(Package package) => package.library.name;
}

/// A linux [Target].
class LinuxTarget extends Target {
  LinuxTarget(super.os, this.vendor, this.version, this.arch);

  final Distro vendor;
  final String version;
  final String arch;

  @override
  String get id => '${vendor.name}$version-$arch';

  @override
  ArchiveFormat get archiveFormat => ArchiveFormat.tarGz;

  @override
  String get librariesDir => p.join('lib', '$arch-linux-gnu');
}

/// A windows [Target].
class WindowsTarget extends Target {
  WindowsTarget(super.os, this.arch);

  final String arch;

  @override
  String get id => 'windows-$arch';

  @override
  String get librariesDir => 'bin';

  @override
  String libraryName(Package package) =>
      package.library.name.replaceAll('lib', '');
}

/// A package though which a release of a [Library] is distributed.
class Package {
  Package({
    required this.library,
    required this.release,
    required this.edition,
    required this.target,
  });

  static const latestReleases = {
    Library.libcblite: '3.0.1',
    Library.libcblitedart: '1.0.0',
  };

  static final _archiveUrlResolvers = <Library, String Function(Package)>{
    Library.libcblite: (package) => 'https://packages.couchbase.com/releases/'
        'couchbase-lite-c/${package.release}/'
        'couchbase-lite-c-${package.edition.name}-${package.release}-'
        '${package.target.id}.${package.archiveFormat.ext}',
    Library.libcblitedart: (package) =>
        'https://github.com/cbl-dart/cbl-dart/releases/download/'
        'libcblitedart-v${package.release}/'
        'couchbase-lite-dart-${package.release}-${package.edition.name}-'
        '${package.target.id}.${package.archiveFormat.ext}'
  };

  static String mergedSignature(Iterable<Package> packages) {
    final signatures =
        packages.map((package) => package._signatureContent).toList()..sort();

    return md5
        .convert(utf8.encode(signatures.join()))
        .bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  final Library library;
  final String release;
  final Edition edition;
  final Target target;

  String get version => release.split('-').first;

  ArchiveFormat get archiveFormat => target.archiveFormat;

  String get archiveUrl => _archiveUrlResolvers[library]!(this);

  String get librariesDir => target.librariesDir;

  String get libraryName => target.libraryName(this);

  String get _signatureContent =>
      [library.name, release, edition.name, target.id].join();
}
