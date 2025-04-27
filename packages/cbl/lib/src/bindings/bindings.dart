import '../support/errors.dart';
import 'async_callback.dart';
import 'base.dart';
import 'blob.dart';
import 'cblite.dart';
import 'cblitedart.dart';
import 'collection.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'libraries.dart';
import 'logging.dart';
import 'query.dart';
import 'replicator.dart';
import 'tracing.dart';

class BindingsLibraries {
  BindingsLibraries({
    required this.enterpriseEdition,
    this.vectorSearchLibraryPath,
    required this.cbl,
    required this.cblDart,
  });

  BindingsLibraries.fromDynamicLibraries(DynamicLibraries dynamicLibraries)
      : enterpriseEdition = dynamicLibraries.enterpriseEdition,
        vectorSearchLibraryPath = dynamicLibraries.vectorSearchLibraryPath,
        cbl = cblite(dynamicLibraries.cbl),
        cblDart = cblitedart(dynamicLibraries.cblDart);

  final bool enterpriseEdition;
  final String? vectorSearchLibraryPath;
  final cblite cbl;
  final cblitedart cblDart;
}

abstract base class Bindings {
  Bindings(this.libraries)
      : cbl = libraries.cbl,
        cblDart = libraries.cblDart;

  final BindingsLibraries libraries;
  final cblite cbl;
  final cblitedart cblDart;
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
  final FleeceBindings fleece;
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
