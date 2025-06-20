import '../support/errors.dart';
import 'async_callback.dart';
import 'base.dart';
import 'blob.dart';
import 'cblite.dart' as cblite_lib;
import 'cblite_native_assets_bridge.dart';
import 'cblitedart.dart' as cblitedart_lib;
import 'cblitedart_native_assets_bridge.dart';
import 'collection.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'libraries.dart';
import 'logging.dart';
import 'query.dart';
import 'replicator.dart';
import 'tls_identity.dart';
import 'tracing.dart';
import 'url_endpoint_listener.dart';

class BindingsLibraries {
  BindingsLibraries({
    required this.enterpriseEdition,
    this.vectorSearchLibraryPath,
    required this.cblite,
    required this.cblitedart,
  });

  BindingsLibraries.fromDynamicLibraries(DynamicLibraries dynamicLibraries)
    : enterpriseEdition = dynamicLibraries.enterpriseEdition,
      vectorSearchLibraryPath = dynamicLibraries.vectorSearchLibraryPath,
      cblite = const cbliteNativeAssetsBridge(),
      cblitedart = const cblitedartNativeAssetsBridge();

  final bool enterpriseEdition;
  final String? vectorSearchLibraryPath;
  final cblite_lib.cblite cblite;
  final cblitedart_lib.cblitedart cblitedart;
}

abstract base class Bindings {
  Bindings(this.libraries)
    : cblite = libraries.cblite,
      cblitedart = libraries.cblitedart;

  final BindingsLibraries libraries;
  final cblite_lib.cblite cblite;
  final cblitedart_lib.cblitedart cblitedart;
}

final class CBLBindings extends Bindings {
  CBLBindings(super.libraries)
    : base = BaseBindings(libraries),
      asyncCallback = AsyncCallbackBindings(libraries),
      logging = LoggingBindings(libraries),
      database = DatabaseBindings(libraries),
      collection = CollectionBindings(libraries),
      document = DocumentBindings(libraries),
      mutableDocument = MutableDocumentBindings(libraries),
      query = QueryBindings(libraries),
      resultSet = ResultSetBindings(libraries),
      queryIndex = QueryIndexBindings(libraries),
      indexUpdater = IndexUpdaterBindings(libraries),
      blobs = BlobsBindings(libraries),
      replicator = ReplicatorBindings(libraries),
      tlsIdentity = TlsIdentityBindings(libraries),
      urlEndpointListener = UrlEndpointListenerBindings(libraries),
      fleece = FleeceBindings(libraries);

  factory CBLBindings.fromLibraries(LibrariesConfiguration libraries) =>
      CBLBindings(
        BindingsLibraries.fromDynamicLibraries(
          DynamicLibraries.fromConfig(libraries),
        ),
      );

  static CBLBindings? _instance;

  static CBLBindings get instance {
    final instance = _instance;
    if (instance == null) {
      throwNotInitializedError();
    }

    return instance;
  }

  static void init({
    CBLBindings? instance,
    LibrariesConfiguration? libraries,
    TracedCallHandler? onTracedCall,
  }) {
    assert(_instance == null, 'CBLBindings have already been initialized.');

    _instance = instance ?? CBLBindings.fromLibraries(libraries!);

    if (onTracedCall != null) {
      _onTracedCall = onTracedCall;
    }
  }

  final BaseBindings base;
  final AsyncCallbackBindings asyncCallback;
  final LoggingBindings logging;
  final DatabaseBindings database;
  final CollectionBindings collection;
  final DocumentBindings document;
  final MutableDocumentBindings mutableDocument;
  final QueryBindings query;
  final ResultSetBindings resultSet;
  final QueryIndexBindings queryIndex;
  final IndexUpdaterBindings indexUpdater;
  final BlobsBindings blobs;
  final ReplicatorBindings replicator;
  final TlsIdentityBindings tlsIdentity;
  final UrlEndpointListenerBindings urlEndpointListener;
  final FleeceBindings fleece;
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
