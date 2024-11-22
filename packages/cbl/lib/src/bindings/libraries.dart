// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Configuration of a [DynamicLibrary], which can be used to load the
/// `DynamicLibrary` at a later time.
class LibraryConfiguration {
  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.open].
  ///
  /// If [appendExtension] is `true` (default), the file extension which is used
  /// for dynamic libraries on the current platform is appended to [name].
  LibraryConfiguration.dynamic(
    this.name, {
    this.appendExtension = true,
    this.version,
    this.isAppleFramework = false,
  }) : process = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.process].
  LibraryConfiguration.process()
      : process = true,
        name = null,
        appendExtension = null,
        version = null,
        isAppleFramework = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.executable].
  LibraryConfiguration.executable()
      : process = false,
        name = null,
        appendExtension = null,
        version = null,
        isAppleFramework = null;

  /// `true` if the library is available in the globally visible symbols of the
  /// process.
  final bool? process;

  /// The name of the library.
  final String? name;

  /// Whether to append the platform dependent file extension to [name].
  final bool? appendExtension;

  /// The version to use when building the full library path.
  final String? version;

  /// Whether the library is packaged in an Apple framework .
  final bool? isAppleFramework;
}

/// Configuration for the [DynamicLibrary]s which provide the Couchbase Lite C
/// API and the Dart support layer.
class LibrariesConfiguration {
  /// Creates a configuration for the [DynamicLibrary]s which provide the
  /// Couchbase Lite C API and the Dart support layer.
  LibrariesConfiguration({
    this.enterpriseEdition = false,
    this.directory,
    required this.cbl,
    required this.cblDart,
  });

  /// Whether the provided Couchbase Lite C library is the enterprise edition.
  final bool enterpriseEdition;

  /// The directory in which libraries are located.
  final String? directory;

  /// The configuration for the Couchbase Lite C library.
  final LibraryConfiguration cbl;

  /// The configuration for the Dart support library.
  final LibraryConfiguration cblDart;
}

final class DynamicLibraries {
  factory DynamicLibraries.fromConfig(LibrariesConfiguration config) =>
      DynamicLibraries._loadLibraries(
        config,
        (library) => library._createDynamicLibrary(directory: config.directory),
      );

  factory DynamicLibraries._loadLibraries(
    LibrariesConfiguration config,
    DynamicLibrary Function(LibraryConfiguration library) fn,
  ) {
    final directory = config.directory;
    final dllDirectoryCookie = directory != null && Platform.isWindows
        ? _AddDllDirectory(directory)
        : null;

    final libraries = DynamicLibraries._(
      enterpriseEdition: config.enterpriseEdition,
      cbl: fn(config.cbl),
      cblDart: fn(config.cblDart),
    );

    if (dllDirectoryCookie != null) {
      _RemoveDllDirectory(dllDirectoryCookie);
    }

    return libraries;
  }

  DynamicLibraries._({
    required this.enterpriseEdition,
    required this.cbl,
    required this.cblDart,
  });

  final bool enterpriseEdition;
  final DynamicLibrary cbl;
  final DynamicLibrary cblDart;
}

extension on LibraryConfiguration {
  DynamicLibrary _createDynamicLibrary({String? directory}) {
    if (name != null) {
      var name = this.name!;

      if (directory != null) {
        name = [directory, name].join(Platform.pathSeparator);
      }

      if (isAppleFramework ?? false) {
        name = '$name.framework/Versions/A/$name';
      } else if (appendExtension ?? false) {
        name += _dynamicLibraryExtension(version: version);
      }

      return DynamicLibrary.open(name);
    }

    if (process ?? false) {
      return DynamicLibrary.process();
    }

    return DynamicLibrary.executable();
  }
}

// === Library extensions ======================================================

final _isApple = Platform.isIOS || Platform.isMacOS;
final _isUnix = Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isAndroid ||
    Platform.isLinux ||
    Platform.isFuchsia;

String _dynamicLibraryExtension({String? version}) {
  String extension;
  if (_isApple) {
    extension = '.dylib';
  } else if (_isUnix) {
    extension = '.so';
  } else if (Platform.isWindows) {
    extension = '.dll';
  } else {
    throw UnimplementedError();
  }

  if (version != null) {
    if (_isApple) {
      extension = '.$version$extension';
    } else if (_isUnix) {
      extension = '$extension.$version';
    } else {
      throw UnimplementedError();
    }
  }

  return extension;
}

// === Windows DLL Loading =====================================================

final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _AddDllDirectoryFn = _kernel32.lookupFunction<
    Pointer<Void> Function(Pointer<Utf16>),
    Pointer<Void> Function(Pointer<Utf16>)>('AddDllDirectory');

final _RemoveDllDirectoryFn = _kernel32.lookupFunction<
    Bool Function(Pointer<Void>),
    bool Function(Pointer<Void>)>('RemoveDllDirectory');

Pointer<Void> _AddDllDirectory(String directory) {
  final directoryNativeStr = directory.toNativeUtf16();
  final result = _AddDllDirectoryFn(directoryNativeStr);
  malloc.free(directoryNativeStr);
  if (result == nullptr) {
    throw StateError('Failed to add DLL directory: $directory');
  }
  return result;
}

void _RemoveDllDirectory(Pointer<Void> cookie) {
  if (!_RemoveDllDirectoryFn(cookie)) {
    throw StateError('Failed to remove DLL directory');
  }
}
