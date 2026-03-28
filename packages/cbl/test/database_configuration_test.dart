import 'dart:ffi';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings/base.dart';
import 'package:cbl/src/bindings/cblite.dart' as cblite;
import 'package:cbl/src/bindings/cblitedart.dart' as cblitedart;
import 'package:cbl/src/bindings/collection.dart';
import 'package:cbl/src/bindings/database.dart';
import 'package:cbl/src/bindings/document.dart';
import 'package:cbl/src/bindings/global.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('DatabaseConfiguration', () {
    test('copies fullSync in DatabaseConfiguration.from', () {
      final config = DatabaseConfiguration(fullSync: true);

      final copiedConfig = DatabaseConfiguration.from(config);

      expect(copiedConfig.fullSync, isTrue);
      expect(copiedConfig.directory, config.directory);
      expect(copiedConfig.encryptionKey, isNull);
    });

    test(
      'opening databases with fullSync disabled produces valid timestamps',
      () {
        final directory = tempTestDirectory();

        for (var i = 0; i < 20; i++) {
          final db = DatabaseBindings.open(
            'db_${i.toString().padLeft(4, '0')}',
            CBLDatabaseConfiguration(
              directory: directory.path,
              fullSync: false,
            ),
          );
          final collection = _defaultCollection(db);
          final document = MutableDocumentBindings.createWithID('doc');

          MutableDocumentBindings.setJSON(document, '{"iter":$i}');
          CollectionBindings.saveDocumentWithConcurrencyControl(
            collection,
            document,
            CBLConcurrencyControl.lastWriteWins,
          );

          final revisionId = DocumentBindings.revisionId(document);
          final timestamp = DocumentBindings.timestamp(document);

          expect(revisionId, isNotNull, reason: 'iteration $i');
          expect(
            _parseRevisionPrefix(revisionId!),
            greaterThanOrEqualTo(_minValidTimestamp),
          );
          expect(
            timestamp,
            greaterThanOrEqualTo(_minValidTimestamp),
            reason: 'iteration $i',
          );

          BaseBindings.releaseRefCounted(document.cast());
          BaseBindings.releaseRefCounted(collection.cast());
          DatabaseBindings.close(db);
          cblitedart.CBLDart_CBLDatabase_Release(db);
        }
      },
      skip: Platform.isWindows
          ? 'Windows keeps the DB file locked during cleanup in this test.'
          : false,
    );
  });
}

Pointer<cblite.CBLCollection> _defaultCollection(
  Pointer<cblite.CBLDatabase> db,
) => cblite.CBLDatabase_DefaultCollection(db, globalCBLError).checkError();

int _parseRevisionPrefix(String revisionId) =>
    int.parse(revisionId.substring(0, revisionId.indexOf('@')), radix: 16);

const _minValidTimestamp = 0x10000000000;
