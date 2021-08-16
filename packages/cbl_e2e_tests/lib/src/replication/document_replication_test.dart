import 'package:cbl/cbl.dart';
import 'package:cbl/src/replication/document_replication.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('DocumentReplication', () {
    test('toString', () async {
      final replicator = _Replicator();
      final doc = ReplicatedDocumentImpl('id');
      final docRep = DocumentReplicationImpl(replicator, true, [doc]);
      expect(
        docRep.toString(),
        'DocumentReplication('
        'replicator: _Replicator(), '
        // ignore: missing_whitespace_between_adjacent_strings
        'PUSH, [ReplicatedDocument(id)]'
        ')',
      );
    });
  });

  group('ReplicatedDocument', () {
    test('toString', () {
      ReplicatedDocumentImpl doc;

      doc = ReplicatedDocumentImpl('id');
      expect(doc.toString(), 'ReplicatedDocument(id)');

      doc = ReplicatedDocumentImpl('id', {
        DocumentFlag.deleted,
        DocumentFlag.accessRemoved,
      });
      expect(doc.toString(), 'ReplicatedDocument(id, DELETED, ACCESS-REMOVED)');

      doc = ReplicatedDocumentImpl('id', {}, StateError(''));
      expect(doc.toString(), 'ReplicatedDocument(id, error: Bad state: )');
    });
  });
}

class _Replicator implements Replicator {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_Replicator()';
}
