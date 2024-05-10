import 'collection.dart';
import 'database.dart';
import 'document.dart';
import 'libraries.dart';
import 'query.dart';
import 'replicator.dart';
import 'tracing.dart';

/// Wether to use the `isLeaf` flag when looking up native functions.
// ignore: do_not_use_environment
const useIsLeaf = bool.fromEnvironment('cblFfiUseIsLeaf');

abstract base class Bindings {
  Bindings(Bindings parent) : libs = parent.libs {
    parent._children.add(this);
  }

  Bindings.root(this.libs);

  final DynamicLibraries libs;

  List<Bindings> get _children => [];
}

final class CBLBindings extends Bindings {
  CBLBindings(LibrariesConfiguration config)
      : super.root(DynamicLibraries.fromConfig(config)) {
    database = DatabaseBindings(this);
    collection = CollectionBindings(this);
    document = DocumentBindings(this);
    mutableDocument = MutableDocumentBindings(this);
    query = QueryBindings(this);
    resultSet = ResultSetBindings(this);
    replicator = ReplicatorBindings(this);
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

  late final DatabaseBindings database;
  late final CollectionBindings collection;
  late final DocumentBindings document;
  late final MutableDocumentBindings mutableDocument;
  late final QueryBindings query;
  late final ResultSetBindings resultSet;
  late final ReplicatorBindings replicator;
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
