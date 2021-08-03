import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart' as ffi;

import 'document/blob.dart';
import 'document/common.dart';
import 'fleece/fleece.dart';
import 'fleece/integration/integration.dart';
import 'support/utils.dart';

/// Configuration of a [DynamicLibrary], which can be used to load the
/// `DynamicLibrary` at a later time.
class LibraryConfiguration {
  /// Creates a configuration for a dynamic library opened with
  /// [DynamicLibrary.open].
  ///
  /// If [appendExtension] is `true` (default), the file extension which is used
  /// for dynamic libraries on the current platform is appended to [name].
  LibraryConfiguration.dynamic(String name,
      {bool appendExtension = true, String? version})
      : process = null,
        name = name,
        appendExtension = appendExtension,
        version = version;

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

  ffi.LibraryConfiguration _toFfi() => ffi.LibraryConfiguration(
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
    this.enterpriseEdition = false,
    required LibraryConfiguration cbl,
    required LibraryConfiguration cblDart,
  })  : cbl = cbl,
        cblDart = cblDart;

  final LibraryConfiguration cbl;
  final LibraryConfiguration cblDart;

  /// Whether the provided Couchbase Lite C library is the enterprise edition.
  final bool enterpriseEdition;

  ffi.Libraries _toFfi() => ffi.Libraries(
        enterpriseEdition: enterpriseEdition,
        cbl: cbl._toFfi(),
        cblDart: cblDart._toFfi(),
      );
}

/// Initializes global resources and configures global settings, such as
/// logging.
class CouchbaseLite {
  static final _initialization = Once<void>(
    rejectMultipleExecutions: true,
    debugName: 'CouchbaseLite.init()',
  );

  /// Initializes the `cbl` package.
  static void init({required Libraries libraries}) =>
      _initialization.execute(() {
        ffi.CBLBindings.initInstance(libraries._toFfi());
        MDelegate.instance = CblMDelegate();
        SlotSetter.register(BlobImplSetter());
      });

  /// Private constructor to allow control over instance creation.
  CouchbaseLite._();
}
