import 'dart:ffi';

import 'base.dart';
import 'blob.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'libraries.dart';
import 'log.dart';
import 'native_callback.dart';
import 'query.dart';
import 'replicator.dart';

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
        nativeCallback = NativeCallbackBindings(libs),
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
  final NativeCallbackBindings nativeCallback;
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
