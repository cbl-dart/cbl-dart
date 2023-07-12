import 'package:cbl/cbl.dart';
import 'package:cbl/src/replication/document_replication.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DocumentReplication', () {
    test('toString', () async {
      final replicator = _Replicator();
      final doc = ReplicatedDocumentImpl('id', 'scope', 'collection');
      final docRep = DocumentReplicationImpl(replicator, true, [doc]);
      expect(
        docRep.toString(),
        'DocumentReplication('
        'replicator: _Replicator(), '
        // ignore: missing_whitespace_between_adjacent_strings
        'PUSH, [ReplicatedDocument(id, collection: scope.collection)]'
        ')',
      );
    });
  });

  group('ReplicatedDocument', () {
    test('toString', () {
      ReplicatedDocumentImpl doc;

      doc = ReplicatedDocumentImpl('id', 'scope', 'collection');
      expect(
        doc.toString(),
        'ReplicatedDocument(id, collection: scope.collection)',
      );

      doc = ReplicatedDocumentImpl('id', 'scope', 'collection', {
        DocumentFlag.deleted,
        DocumentFlag.accessRemoved,
      });
      expect(
        doc.toString(),
        'ReplicatedDocument(id, collection: scope.collection, '
        'DELETED, ACCESS-REMOVED)',
      );

      doc = ReplicatedDocumentImpl(
        'id',
        'scope',
        'collection',
        {},
        StateError(''),
      );
      expect(
        doc.toString(),
        'ReplicatedDocument(id, collection: scope.collection, '
        'error: Bad state: )',
      );
    });
  });
}

class _Replicator implements Replicator {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_Replicator()';
}
