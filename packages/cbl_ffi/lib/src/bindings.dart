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

abstract class Bindings {
  Bindings(Bindings parent) : libs = parent.libs {
    parent._children.add(this);
  }

  Bindings.root(this.libs);

  final Libraries libs;

  List<Bindings> get _children => [];

  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  @mustCallSuper
  void dispose() {
    assert(!_isDisposed);

    _isDisposed = true;

    for (final child in _children) {
      child.dispose();
    }
  }
}

class CBLBindings extends Bindings {
  CBLBindings(Libraries libs) : super.root(libs) {
    base = BaseBindings(this);
    asyncCallback = AsyncCallbackBindings(this);
    logging = LoggingBindings(this);
    database = DatabaseBindings(this);
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

  static void initInstance(Libraries libraries) {
    _instance ??= CBLBindings(libraries)..base.init();
  }

  late final BaseBindings base;
  late final AsyncCallbackBindings asyncCallback;
  late final LoggingBindings logging;
  late final DatabaseBindings database;
  late final DocumentBindings document;
  late final MutableDocumentBindings mutableDocument;
  late final QueryBindings query;
  late final ResultSetBindings resultSet;
  late final BlobsBindings blobs;
  late final ReplicatorBindings replicator;
  late final FleeceBindings fleece;
}
