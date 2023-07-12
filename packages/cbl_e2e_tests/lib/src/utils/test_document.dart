/// This file contains helpers for testing with a single simple document.
library test_document;

import 'package:cbl/cbl.dart';

import '../test_binding.dart';

/// The id of the test document if it has been written to at least once.
String? testDocumentId;

/// Set up a test hook which resets [testDocumentId] for each test.
void setupTestDocument() {
  setUp(() {
    testDocumentId = null;
  });
}

/// Returns a matcher which checks that the matched value is a [Document] with
/// [testDocumentId] which has [value] in its properties.
Matcher isTestDocument(String value) =>
    isA<Document>().having((it) => it.id, 'id', testDocumentId).having(
      (it) => it.toPlainMap()..remove('type'),
      'toPlainMap()',
      {'value': value},
    );

extension TestDocumentDatabaseExtension on Database {
  /// Writes [value] in the properties of the test document. If its does not
  /// exist already in this database, it is created.
  Future<Document> writeTestDocument(String value, {String? type}) async {
    final doc = (await getTestDocumentOrNull()) ?? MutableDocument();
    testDocumentId ??= doc.id;
    doc.setValue(value, key: 'value');
    if (type != null) {
      doc.setValue(type, key: 'type');
    }
    await (await defaultCollection).saveDocument(doc);
    return doc;
  }

  /// Gets the test document or `null` if does not exist.
  Future<MutableDocument?> getTestDocumentOrNull() async =>
      testDocumentId == null
          ? null
          : (await (await defaultCollection).document(testDocumentId!))
              ?.toMutable();
}
