import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart' as ffi;

import '../errors.dart';

/// Convenience accessor for `CBLBindings.instance`, which throws an informative
/// error when used before the bindings are initialized.
late final ffi.CBLBindings cblBindings = () {
  final bindings = ffi.CBLBindings.maybeInstance;
  if (bindings == null) {
    throwNotInitializedError();
  }
  return bindings;
}();

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
  }) : process = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.process].
  LibraryConfiguration.process()
      : process = true,
        name = null,
        appendExtension = null,
        version = null;

  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.executable].
  LibraryConfiguration.executable()
      : process = false,
        name = null,
        appendExtension = null,
        version = null;

  final bool? process;
  final String? name;
  final bool? appendExtension;
  final String? version;

  ffi.LibraryConfiguration _toCblFfi() => ffi.LibraryConfiguration(
        process: process,
        name: name,
        appendExtension: appendExtension,
        version: version,
      );
}

/// The [DynamicLibrary]s which provide the Couchbase Lite C API and the Dart
/// support layer.
class Libraries {
  Libraries({
    required this.cbl,
    required this.cblDart,
    this.enterpriseEdition = false,
  });

  final LibraryConfiguration cbl;
  final LibraryConfiguration cblDart;

  /// Whether the provided Couchbase Lite C library is the enterprise edition.
  final bool enterpriseEdition;

  ffi.Libraries _toCblFfi() => ffi.Libraries(
        enterpriseEdition: enterpriseEdition,
        cbl: cbl._toCblFfi(),
        cblDart: cblDart._toCblFfi(),
      );
}

extension CblFfiLibraries on Libraries {
  ffi.Libraries toCblFfi() => _toCblFfi();
}
