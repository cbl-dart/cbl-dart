import 'package:meta/meta.dart';

import 'async_callback.dart';
import 'base.dart';
import 'blob.dart';
import 'database.dart';
import 'document.dart';
import 'fleece.dart';
import 'libraries.dart';
import 'logging.dart';
import 'query.dart';
import 'replicator.dart';
import 'string_table.dart';

abstract class Bindings {
  Bindings(Bindings parent)
      : libs = parent.libs,
        stringTable = parent.stringTable {
    parent._children.add(this);
  }

  Bindings.root(Libraries libs, StringTable stringTable)
      : libs = libs,
        stringTable = stringTable;

  final Libraries libs;

  final StringTable stringTable;

  List<Bindings> get _children => [];

  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  @mustCallSuper
  void dispose() {
    assert(!_isDisposed);

    _isDisposed = true;

    _children.forEach((element) {
      element.dispose();
    });
  }
}

class CBLBindings extends Bindings {
  static CBLBindings? _instance;

  static CBLBindings get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('CBLBindings have not been initialized.');
    }

    return instance;
  }

  static void initInstance(Libraries libraries) {
    _instance ??= CBLBindings(
      libraries,
      StringTable(
        maxCacheSize: 512,
        minCachedStringSize: 0,
        maxCachedStringSize: 512,
      ),
    )..base.initDartApiDL();
  }

  CBLBindings(Libraries libs, StringTable stringTable)
      : super.root(libs, stringTable) {
    base = BaseBindings(this);
    asyncCallback = AsyncCallbackBindings(this);
    logging = LoggingBindings(this);
    database = asynchronously(this);
    document = DocumentBindings(this);
    mutableDocument = MutableDocumentBindings(this);
    query = QueryBindings(this);
    resultSet = ResultSetBindings(this);
    blobs = BlobsBindings(this);
    replicator = ReplicatorBindings(this);
    fleece = FleeceBindings(this);
  }

  late final BaseBindings base;
  late final AsyncCallbackBindings asyncCallback;
  late final LoggingBindings logging;
  late final asynchronously database;
  late final DocumentBindings document;
  late final MutableDocumentBindings mutableDocument;
  late final QueryBindings query;
  late final ResultSetBindings resultSet;
  late final BlobsBindings blobs;
  late final ReplicatorBindings replicator;
  late final FleeceBindings fleece;

  @override
  void dispose() {
    stringTable.dispose();
    super.dispose();
  }
}
