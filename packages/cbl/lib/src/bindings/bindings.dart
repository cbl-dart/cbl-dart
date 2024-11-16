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
      : cbl = parent.cbl,
        cblDart = parent.cblDart,
        enterpriseEdition = parent.enterpriseEdition {
    parent._children.add(this);
  }

  Bindings.root(DynamicLibraries libs)
      : cbl = cblite(libs.cbl),
        cblDart = cblitedart(libs.cblDart),
        enterpriseEdition = libs.enterpriseEdition;

  final cblite cbl;
  final cblitedart cblDart;
  final bool enterpriseEdition;

  List<Bindings> get _children => [];
}

final class CBLBindings extends Bindings {
  CBLBindings(LibrariesConfiguration config)
      : super.root(DynamicLibraries.fromConfig(config)) {
    base = BaseBindings(this);
    asyncCallback = AsyncCallbackBindings(this);
    logging = LoggingBindings(this);
    database = DatabaseBindings(this);
    collection = CollectionBindings(this);
    document = DocumentBindings(this);
    mutableDocument = MutableDocumentBindings(this);
    query = QueryBindings(this);
    resultSet = ResultSetBindings(this);
    blobs = BlobsBindings(this);
    replicator = ReplicatorBindings(this);
    fleece = FleeceBindings(this);
  }

  static CBLBindings? _instance;

  static CBLBindings get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('CBLBindings have not been initialized.');
    }

    return instance;
  }

  static CBLBindings? get maybeInstance => _instance;

  static void init(
    LibrariesConfiguration libraries, {
    TracedCallHandler? onTracedCall,
  }) {
    assert(_instance == null, 'CBLBindings have already been initialized.');

    _instance = CBLBindings(libraries);

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
  late final BlobsBindings blobs;
  late final ReplicatorBindings replicator;
  late final FleeceBindings fleece;
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
