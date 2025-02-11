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

abstract base class Bindings {
  Bindings(Bindings parent)
      : enterpriseEdition = parent.enterpriseEdition,
        cbl = parent.cbl,
        cblDart = parent.cblDart,
        vectorSearchLibraryPath = parent.vectorSearchLibraryPath {
    parent._children.add(this);
  }

  Bindings.root({
    required this.enterpriseEdition,
    required this.cbl,
    required this.cblDart,
    required this.vectorSearchLibraryPath,
  });

  final bool enterpriseEdition;
  final cblite cbl;
  final cblitedart cblDart;
  final String? vectorSearchLibraryPath;

  List<Bindings> get _children => [];
}

final class CBLBindings extends Bindings {
  CBLBindings({
    required super.enterpriseEdition,
    required super.cbl,
    required super.cblDart,
    super.vectorSearchLibraryPath,
  }) : super.root() {
    base = BaseBindings(this);
    asyncCallback = AsyncCallbackBindings(this);
    logging = LoggingBindings(this);
    database = DatabaseBindings(this);
    collection = CollectionBindings(this);
    document = DocumentBindings(this);
    mutableDocument = MutableDocumentBindings(this);
    query = QueryBindings(this);
    resultSet = ResultSetBindings(this);
    queryIndex = QueryIndexBindings(this);
    indexUpdater = IndexUpdaterBindings(this);
    blobs = BlobsBindings(this);
    replicator = ReplicatorBindings(this);
    fleece = FleeceBindings(this);
  }

  factory CBLBindings.fromLibraries(LibrariesConfiguration libraries) {
    final dynamicLibraries = DynamicLibraries.fromConfig(libraries);
    return CBLBindings(
      enterpriseEdition: libraries.enterpriseEdition,
      cbl: cblite(dynamicLibraries.cbl),
      cblDart: cblitedart(dynamicLibraries.cblDart),
      vectorSearchLibraryPath: dynamicLibraries.vectorSearchLibraryPath,
    );
  }

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

  late final BaseBindings base;
  late final AsyncCallbackBindings asyncCallback;
  late final LoggingBindings logging;
  late final DatabaseBindings database;
  late final CollectionBindings collection;
  late final DocumentBindings document;
  late final MutableDocumentBindings mutableDocument;
  late final QueryBindings query;
  late final ResultSetBindings resultSet;
  late final QueryIndexBindings queryIndex;
  late final IndexUpdaterBindings indexUpdater;
  late final BlobsBindings blobs;
  late final ReplicatorBindings replicator;
  late final FleeceBindings fleece;
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
