import 'dart:io';

import 'package:cbl/cbl.dart';

// Run by test-hook-compatibility.sh with independently resolved dependencies.
Future<void> main() async {
  final directory = Directory.systemTemp.createTempSync('cbl-hook-');
  try {
    final config = DatabaseConfiguration(directory: directory.path);
    final database = Database.openSync('compatibility', config);
    final collection = database.createCollection('documents');
    final document = MutableDocument({'value': 42});
    collection.saveDocument(document);
    final documentId = document.id;
    await database.close();

    // Reopen through the worker isolate, verifying persistence and native
    // asset availability in both the main isolate and the worker isolate.
    final reopened = await Database.openAsync('compatibility', config);
    try {
      final documents = await reopened.collection('documents');
      final loaded = await documents!.document(documentId);
      if (loaded?.toPlainMap()['value'] != 42) {
        throw StateError('Document did not survive closing and reopening.');
      }
    } finally {
      await reopened.close();
    }
    stdout.writeln('Native database round trip passed.');
  } finally {
    directory.deleteSync(recursive: true);
  }
}
