// ignore_for_file: non_constant_identifier_names, constant_identifier_names

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

  DynamicLibrary _load({String? directory}) {
    if (name != null) {
      var name = this.name!;

      if (directory != null) {
        name = [directory, name].join(Platform.pathSeparator);
      }

      if (isAppleFramework ?? false) {
        name = '$name.framework/Versions/A/${this.name}';
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

  String? _tryResolvePath({String? directory, required String symbol}) {
    final DynamicLibrary library;
    try {
      library = _load(directory: directory);
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }

    if (!library.providesSymbol(symbol)) {
      return null;
    }

    return _tryResolvePathFromSymbol(library.lookup(symbol));
  }

  String? _tryResolvePathFromSymbol(Pointer<Void> address) {
    if (Platform.isAndroid ||
        Platform.isLinux ||
        Platform.isMacOS ||
        Platform.isIOS) {
      final info = calloc<_Dl_info>();
      try {
        if (_dladdr(address, info) == 0) {
          return null;
        }

        return info.ref.dli_fname.toDartString();
      } finally {
        calloc.free(info);
      }
    }

    if (Platform.isWindows) {
      final hModule = calloc<Pointer<Void>>();
      try {
        if (_GetModuleHandleExA(
              _GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                  _GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
              address.cast(),
              hModule,
            ) ==
            0) {
          return null;
        }

        const maxPath = 4096;
        final path = calloc<Uint8>(maxPath);
        try {
          if (_GetModuleFileNameA(hModule.value, path.cast(), maxPath) == 0) {
            return null;
          }

          return path.cast<Utf8>().toDartString();
        } finally {
          calloc.free(path);
        }
      } finally {
        calloc.free(hModule);
      }
    }

    throw UnimplementedError();
  }
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
    required this.vectorSearch,
  });

  /// Whether the provided Couchbase Lite C library is the enterprise edition.
  final bool enterpriseEdition;

  /// The directory in which libraries are located.
  final String? directory;

  /// The configuration for the Couchbase Lite C library.
  final LibraryConfiguration cbl;

  /// The configuration for the Dart support library.
  final LibraryConfiguration cblDart;

  /// The configuration for the Vector Search extension library.
  final LibraryConfiguration? vectorSearch;
}

final class DynamicLibraries {
  factory DynamicLibraries.fromConfig(LibrariesConfiguration config) {
    final directory = config.directory;
    final dllDirectoryCookie = directory != null && Platform.isWindows
        ? _AddDllDirectory(directory)
        : null;

    final libraries = DynamicLibraries._(
      enterpriseEdition: config.enterpriseEdition,
      cbl: config.cbl._load(directory: config.directory),
      cblDart: config.cblDart._load(directory: config.directory),
      vectorSearchLibraryPath: switch (Abi.current()) {
        // TODO(blaugold): https://github.com/cbl-dart/cbl-dart/issues/657
        Abi.windowsArm64 => null,
        _ => config.vectorSearch?._tryResolvePath(
            directory: config.directory,
            symbol: 'couchbaselitevectorsearch_version',
          ),
      },
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
    required this.vectorSearchLibraryPath,
  });

  final bool enterpriseEdition;
  final DynamicLibrary cbl;
  final DynamicLibrary cblDart;
  final String? vectorSearchLibraryPath;
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

// === POSIX Dynamic Linking ===================================================

final _process = DynamicLibrary.process();

// ignore: camel_case_types
final class _Dl_info extends Struct {
  external Pointer<Utf8> dli_fname;
  external Pointer<Utf8> dli_fbase;
  external Pointer<Utf8> dli_sname;
  external Pointer<Utf8> dli_saddr;
}

final _dladdr = _process.lookupFunction<
    Int32 Function(Pointer<Void>, Pointer<_Dl_info>),
    int Function(Pointer<Void>, Pointer<_Dl_info>)>('dladdr');

// === Windows Dynamic Linking =================================================

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

final _GetModuleHandleExA = _kernel32.lookupFunction<
    Int32 Function(Uint32, Pointer<Utf8>, Pointer<Pointer<Void>>),
    int Function(
        int, Pointer<Utf8>, Pointer<Pointer<Void>>)>('GetModuleHandleExA');

const _GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = 0x00000004;
const _GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = 0x00000002;

final _GetModuleFileNameA = _kernel32.lookupFunction<
    Uint32 Function(Pointer<Void>, Pointer<Utf8>, Uint32),
    int Function(Pointer<Void>, Pointer<Utf8>, int)>('GetModuleFileNameA');
