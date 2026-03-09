import '../support/errors.dart';
import 'async_callback.dart';
import 'base.dart';
import 'blob.dart';
import 'collection.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'logging.dart';
import 'query.dart';
import 'replicator.dart';
import 'tls_identity.dart';
import 'tracing.dart';
import 'url_endpoint_listener.dart';

final class CBLBindings {
  const CBLBindings();

  static CBLBindings? _instance;

  static CBLBindings get instance {
    final instance = _instance;
    if (instance == null) {
      throwNotInitializedError();
    }

    return instance;
  }

  static void init({
    required CBLBindings instance,
    TracedCallHandler? onTracedCall,
  }) {
    assert(_instance == null, 'CBLBindings have already been initialized.');

    _instance = instance;

    if (onTracedCall != null) {
      _onTracedCall = onTracedCall;
    }
  }

  BaseBindings get base => const BaseBindings();
  AsyncCallbackBindings get asyncCallback => const AsyncCallbackBindings();
  LoggingBindings get logging => const LoggingBindings();
  DatabaseBindings get database => const DatabaseBindings();
  CollectionBindings get collection => const CollectionBindings();
  DocumentBindings get document => const DocumentBindings();
  MutableDocumentBindings get mutableDocument =>
      const MutableDocumentBindings();
  QueryBindings get query => const QueryBindings();
  ResultSetBindings get resultSet => const ResultSetBindings();
  QueryIndexBindings get queryIndex => const QueryIndexBindings();
  IndexUpdaterBindings get indexUpdater => const IndexUpdaterBindings();
  BlobsBindings get blobs => const BlobsBindings();
  ReplicatorBindings get replicator => const ReplicatorBindings();
  TlsIdentityBindings get tlsIdentity => const TlsIdentityBindings();
  UrlEndpointListenerBindings get urlEndpointListener =>
      const UrlEndpointListenerBindings();
  FleeceBindings get fleece => const FleeceBindings();
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
