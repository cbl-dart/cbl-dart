// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class LibraryConfiguration {
  LibraryConfiguration({
    this.process,
    this.name,
    this.appendExtension,
    this.version,
    this.isAppleFramework,
  }) : assert((process != null && name == null && appendExtension == null) ||
            name != null);

  final bool? process;
  final String? name;
  final bool? appendExtension;
  final String? version;
  final bool? isAppleFramework;
}

class LibrariesConfiguration {
  LibrariesConfiguration({
    required this.cbl,
    required this.cblDart,
    this.enterpriseEdition = false,
    this.directory,
  });

  final LibraryConfiguration cbl;
  final LibraryConfiguration cblDart;

  final bool enterpriseEdition;

  final String? directory;
}

class DynamicLibraries {
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
