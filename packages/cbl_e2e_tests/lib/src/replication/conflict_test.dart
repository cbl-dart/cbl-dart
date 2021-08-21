import 'package:cbl/cbl.dart';
import 'package:cbl/src/replication/conflict.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('Conflict', () {
    test('toString', () {
      final local = MutableDocument.withId('local');
      final remote = MutableDocument.withId('remote');
      final conflict = ConflictImpl(local.id, local, remote);
      expect(
        conflict.toString(),
        'Conflict('
        'local: MutableDocument(id: local, revisionId: null, sequence: 0), '
        // ignore: missing_whitespace_between_adjacent_strings
        'remote: MutableDocument(id: remote, revisionId: null, sequence: 0)'
        ')',
      );
    });
  });
}
