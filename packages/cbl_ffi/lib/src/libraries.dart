import 'dart:ffi';
import 'dart:io';

/// Configuration of a [DynamicLibrary], which can be used to load the
/// `DynamicLibrary` at a later time.
class LibraryConfiguration {
  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.open].
  ///
  /// If [appendExtension] is `true` (default), the file extension which is used
  /// for dynamic libraries on the current platform is appended to [name].
  LibraryConfiguration.dynamic(String name, {bool appendExtension = true})
      : process = null,
        name = name,
        appendExtension = appendExtension;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.process].
  LibraryConfiguration.process()
      : process = true,
        name = null,
        appendExtension = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.executable].
  LibraryConfiguration.executable()
      : process = false,
        name = null,
        appendExtension = null;

  final bool? process;
  final String? name;
  final bool? appendExtension;

  DynamicLibrary get library {
    if (name != null) {
      final name =
          this.name! + (appendExtension == true ? dynamicLibraryExtension : '');
      return DynamicLibrary.open(name);
    }
    if (process == true) return DynamicLibrary.process();
    return DynamicLibrary.executable();
  }

  static late final String dynamicLibraryExtension = (() {
    if (Platform.isAndroid || Platform.isLinux || Platform.isFuchsia) {
      return '.so';
    }
    if (Platform.isIOS || Platform.isMacOS) return '.dylib';
    if (Platform.isWindows) return '.dll';
    throw UnimplementedError('Support for platform is not implemented');
  })();
}

/// The [DynamicLibrary]s which provide the Couchbase Lite C API and the Dart
/// support layer.
class Libraries {
  Libraries({
    this.enterpriseEdition = false,
    required LibraryConfiguration cbl,
    required LibraryConfiguration cblDart,
  })   : _cbl = cbl,
        _cblDart = cblDart;

  final LibraryConfiguration _cbl;
  final LibraryConfiguration _cblDart;

  /// Whether the provided Couchbase Lite C library is the enterprise edition.
  final bool enterpriseEdition;

  /// The library which contains Couchbase Lite C.
  DynamicLibrary get cbl => _cbl.library;

  /// Convenience accessor which returns [cbl] if it is the [enterpriseEdition],
  /// otherwise null.
  DynamicLibrary? get cblEE => enterpriseEdition ? cbl : null;

  /// The library which contains the Couchbase Lite C Dart compatibility layer.
  DynamicLibrary get cblDart => _cblDart.library;
}
