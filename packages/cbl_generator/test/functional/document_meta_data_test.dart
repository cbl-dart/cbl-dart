import 'package:test/test.dart';

import '../fixtures/document_meta_data.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  group('document id', () {
    test('pass id to constructor', () {
      final doc = DocWithId('a');
      expect(doc.id, 'a');
    });

    test('auto generate by passing null to constructor', () {
      final doc = DocWithOptionalId();
      expect(doc.id, startsWith('-'));
    });

    test('pass id to constructor when nullable', () {
      final doc = DocWithOptionalId('a');
      expect(doc.id, 'a');
    });
  });

  test('sequence returns correct value', () async {
    final db = await openTestDatabase();
    final doc = MutableDocWithSequenceGetter();

    expect(doc.sequence, 0);
    await db.saveDocument(doc.internal);
    expect(doc.sequence, 1);
  });

  test('revisionId returns correct value', () async {
    final db = await openTestDatabase();
    final doc = MutableDocWithRevisionIdGetter();

    expect(doc.revisionId, isNull);
    await db.saveDocument(doc.internal);
    expect(doc.revisionId, isNot(isNull));
  });
}
