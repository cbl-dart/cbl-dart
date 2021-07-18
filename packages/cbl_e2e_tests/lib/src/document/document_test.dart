import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('Document', () {
    test('toString returns custom String representation', () async {
      final db = await openTestDb('Document-toString');

      final mutableDoc = MutableDocument();
      expect(
        mutableDoc.toString(),
        'MutableDocument('
        'id: ${mutableDoc.id}, '
        'revisionId: ${mutableDoc.revisionId}'
        ')',
      );

      final doc = await db.saveDocument(mutableDoc);
      expect(
        doc.toString(),
        'Document('
        'id: ${doc.id}, '
        'revisionId: ${doc.revisionId}'
        ')',
      );
    });
  });
}
