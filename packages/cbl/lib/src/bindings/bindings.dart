import 'dart:ffi';
import 'dart:io';

import 'base.dart';
import 'blob.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'log.dart';
import 'native_callbacks.dart';
import 'query.dart';
import 'replicator.dart';

export 'base.dart';
export 'blob.dart';
export 'database.dart';
export 'document.dart';
export 'fleece.dart';
export 'log.dart';
export 'native_callbacks.dart';
export 'query.dart';
export 'replicator.dart';

class LibraryConfiguration {
  LibraryConfiguration.dynamic(String name, {bool appendExtension = true})
      : process = null,
        name = name,
        appendExtension = appendExtension;

  LibraryConfiguration.process()
      : process = true,
        name = null,
        appendExtension = null;

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

/// The libraries to lookup symbols from in the bindings and metadata about
/// those libraries.
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

class CBLBindings {
  static CBLBindings? _instance;

  static CBLBindings get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('CBLBindings have not been initialized.');
    }

    return instance;
  }

  static void initInstance(Libraries libraries) {
    _instance ??= CBLBindings(libraries)
      ..base.initDartApiDL(NativeApi.initializeApiDLData);
  }

  CBLBindings(Libraries libs)
      : base = BaseBindings(libs),
        nativeCallbacks = NativeCallbacksBindings(libs),
        log = LogBindings(libs),
        database = DatabaseBindings(libs),
        document = DocumentBindings(libs),
        mutableDocument = MutableDocumentBindings(libs),
        query = QueryBindings(libs),
        resultSet = ResultSetBindings(libs),
        blobs = BlobsBindings(libs),
        replicator = ReplicatorBindings(libs),
        fleece = FleeceBindings(libs);

  final BaseBindings base;
  final NativeCallbacksBindings nativeCallbacks;
  final LogBindings log;
  final DatabaseBindings database;
  final DocumentBindings document;
  final MutableDocumentBindings mutableDocument;
  final QueryBindings query;
  final ResultSetBindings resultSet;
  final BlobsBindings blobs;
  final ReplicatorBindings replicator;
  final FleeceBindings fleece;
}
