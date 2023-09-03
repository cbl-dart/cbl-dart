// TODO(blaugold): Migrate to collection API.
// ignore_for_file: deprecated_member_use

import 'dart:convert' hide json;
import 'dart:math';
import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/document/blob.dart';
import 'package:cbl/src/support/streams.dart';

import '../../test_binding_impl.dart';
import '../fixtures/values.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';
import '../utils/test_variant.dart';

void main() {
  setupTestBinding();

  group('Blob', () {
    group('from data', () {
      test('initial properties', () {
        final blob = blobFromData();
        expect(blob.contentType, contentType);
        expect(blob.length, fixedTestContent.length);
        expect(blob.digest, isNull);
        expect(blob.properties, {
          '@type': 'blob',
          'content_type': contentType,
          'length': fixedTestContent.length,
        });
      });
    });

    group('from properties', () {
      test('initial properties', () {
        final blob = BlobImpl.fromProperties({
          '@type': 'blob',
          'digest': 'digest',
          'length': 0,
          'content_type': contentType,
        });

        expect(blob.digest, 'digest');
        expect(blob.length, 0);
        expect(blob.contentType, contentType);
      });

      test('throws when reading content before saving', () {
        final blob = BlobImpl.fromProperties({
          '@type': 'blob',
          'digest': 'digest',
          'length': 0,
          'content_type': contentType,
        });
        expect(
          blob.content,
          throwsA(isStateError.having(
            (it) => it.message,
            'message',
            "Cannot load Blob's content. "
                'Save the Blob or a Document containing the Blob, first.',
          )),
        );
        expect(
          blob.contentStream,
          throwsA(isStateError.having(
            (it) => it.message,
            'message',
            "Cannot load Blob's content. "
                'Save the Blob or a Document containing the Blob, first.',
          )),
        );
      });
    });

    apiTest('throws error when saving blob from different database', () async {
      final db = await openTestDatabase();
      final otherDb = await openTestDatabase(name: 'other');
      final blob = Blob.fromData(contentType, randomTestContent());
      final doc = MutableDocument({'blob': blob});
      await otherDb.saveDocument(doc);

      final docB = MutableDocument({'blob': blob});
      expect(() => db.saveDocument(docB), throwsStateError);
    });

    test('throws when saving document with stream blob into sync db', () {
      final db = openSyncTestDatabase();
      final blob =
          Blob.fromStream(contentType, Stream.value(randomTestContent()));
      final doc = MutableDocument({'blob': blob});
      expect(() => db.saveDocument(doc), throwsStateError);
    });

    apiTest(
      'read',
      () async {
        final db = await openTestDatabase();

        final content =
            randomTestContent(large: blobSize.value == BlobSize.large);
        Blob? writeBlobInstance;
        final doc = MutableDocument();

        switch (writeBlob.value) {
          case WriteBlob.data:
            writeBlobInstance = Blob.fromData(contentType, content);
            break;
          case WriteBlob.properties:
            final blob = Blob.fromData(contentType, content);
            await db.saveBlob(blob);
            doc['blob'].value = blob.properties;
            break;
          case WriteBlob.stream:
            writeBlobInstance =
                Blob.fromStream(contentType, Stream.value(content));

            if (api.value == Api.sync) {
              await db.saveBlob(writeBlobInstance);
            }
            break;
        }

        if (writeBlobInstance != null) {
          doc['blob'].value = writeBlobInstance;
        }

        Future<void> read() async {
          Blob readBlobInstance;
          switch (readBlob.value) {
            case ReadBlob.sourceBlob:
              readBlobInstance = writeBlobInstance!;
              break;
            case ReadBlob.loadedBlob:
              final loadedDoc = (await db.document(doc.id))!;
              readBlobInstance = loadedDoc.blob('blob')!;
              break;
          }

          switch (readMode.value) {
            case ReadMode.future:
              expect(await readBlobInstance.content(), content);
              break;
            case ReadMode.stream:
              expect(
                await byteStreamToFuture(readBlobInstance.contentStream()),
                content,
              );
              break;
          }
        }

        switch (readTime.value) {
          case ReadTime.beforeSave:
            await read();
            break;
          case ReadTime.afterSave:
            await db.saveDocument(doc);
            await read();
            break;
        }
      },
      variants: [writeBlob, readTime, readMode, readBlob, blobSize],
    );

    apiTest('remove from document', () async {
      final db = await openTestDatabase();
      final blob = blobFromData();
      final doc = MutableDocument({'blob': blob});
      await db.saveDocument(doc);
      doc.removeValue('blob');
      await db.saveDocument(doc);
      final loadedDoc = (await db.document(doc.id))!;
      expect(loadedDoc.value('blob'), isNull);
    });

    test('toJson returns JSON representation of saved blob', () async {
      final db = openSyncTestDatabase();
      final blob = blobFromDataWithLength();
      final doc = MutableDocument({'blob': blob});
      db.saveDocument(doc);

      expect(
        blob.toJson(),
        json('''
          {
            "@type": "blob",
            "content_type": "application/octet-stream",
            "length": 0,
            "digest":"sha1-2jmj7l5rSw0yVb/vlWAYkK/YBwk="
          }
          '''),
      );
    });

    test('toJson throws when blob has not been saved', () {
      final blob = blobFromData();
      expect(blob.toJson, throwsStateError);
    });

    test('replace unsaved blob in document', () {
      final doc = MutableDocument({'blob': blobFromData()});
      final newBlob = blobFromData();
      doc['blob'].value = newBlob;
      expect(doc['blob'].value, newBlob);
    });

    test('==', () {
      Blob a;
      Blob b;

      // Identical blobs are equal.
      a = blobFromData();
      expect(a, a);

      // Blobs with same digest are equal.
      a = testBlob;
      b = BlobImpl.fromProperties(testBlob.properties);
      expect(a, equality(b));
    });

    test('== return false if either blob has no digest', () {
      final blobWithDigest = testBlob;
      final blobWithoutDigest = blobFromData();

      expect(blobWithDigest, isNot(blobWithoutDigest));
      expect(blobWithoutDigest, isNot(blobWithDigest));
    });

    test('hashCode', () {
      expect(testBlob.hashCode, testBlob.digest.hashCode);
    });

    test('hashCode returns fixed hashCode if blob has no digest', () {
      expect(
        blobFromData().hashCode,
        31,
      );
    });

    test('toString', () {
      expect(
        blobFromDataWithLength(1024).toString(),
        'Blob($contentType; 1.5 KB)',
      );

      expect(
        blobFromDataWithLength().toString(),
        'Blob($contentType; 0.5 KB)',
      );

      // Blob without content type.
      expect(
        BlobImpl.fromProperties({
          '@type': 'blob',
          'length': 0,
          'digest': '',
        }).toString(),
        'Blob(0.5 KB)',
      );
    });

    test('isBlob', () {
      final isBlob = predicate<Map<String, Object?>>(Blob.isBlob, 'is Blob');

      expect(<String, Object?>{}, isNot(isBlob));
      expect({'@type': 'blob'}, isNot(isBlob));
      expect({'digest': ''}, isNot(isBlob));
      expect({'@type': 0, 'digest': ''}, isNot(isBlob));
      expect({'@type': '', 'digest': ''}, isNot(isBlob));
      expect({'@type': 'blob', 'digest': null}, isNot(isBlob));
      expect({'@type': 'blob', 'digest': '', 'length': '0'}, isNot(isBlob));
      expect({'@type': 'blob', 'digest': '', 'content_type': 0}, isNot(isBlob));

      expect({'@type': 'blob', 'digest': ''}, isBlob);
      expect({
        '@type': 'blob',
        'digest': '',
        'content_type': 'text/plain',
      }, isBlob);
      expect({
        '@type': 'blob',
        'digest': '',
        'length': 0,
      }, isBlob);
      expect({
        '@type': 'blob',
        'digest': '',
        'content_type': 'text/plain',
        'length': 0,
      }, isBlob);
    });
  });
}

const contentType = 'application/octet-stream';
// TODO(blaugold): Remove ignore when Dart 3.2 is a minimum requirement.
// ignore: unnecessary_cast
final fixedTestContent = utf8.encode('content') as Uint8List;
const fixedTestContentDigest = 'sha1-BA8G/XdAkkeNRQd09bowxdp4rMg=';

Blob blobFromData() => Blob.fromData(contentType, fixedTestContent);

Blob blobFromDataWithLength([int length = 0]) =>
    Blob.fromData(contentType, Uint8List(length));

/// Returns random bytes for blob.
///
/// When [large] is true the content is to large to be cached and results in
/// multiple chunks when streamed.
Uint8List randomTestContent({bool large = false}) =>
    randomBytes(large ? 8 * 1024 * 2 : 16);

final random = Random(0);

Uint8List randomBytes(int size) {
  final data = Uint32List(size ~/ 4);
  for (var i = 0; i < data.length; i++) {
    data[i] = random.nextInt(1 << 32);
  }
  return data.buffer.asUint8List(0, size);
}

enum WriteBlob { data, properties, stream }

enum ReadTime { beforeSave, afterSave }

enum ReadMode { future, stream }

enum ReadBlob { sourceBlob, loadedBlob }

enum BlobSize { small, large }

final writeBlob = EnumVariant<WriteBlob>(
  WriteBlob.values,
  isCompatible: (value, other, otherValue) {
    if (value == WriteBlob.properties) {
      if (other == readBlob) {
        return otherValue == ReadBlob.loadedBlob;
      }
    }

    return true;
  },
  order: 100,
);
final readTime = EnumVariant(ReadTime.values, order: 90);
final readMode = EnumVariant(ReadMode.values, order: 80);
final readBlob = EnumVariant<ReadBlob>(
  ReadBlob.values,
  isCompatible: (value, other, otherValue) {
    if (value == ReadBlob.loadedBlob && other == readTime) {
      return otherValue == ReadTime.afterSave;
    }
    return true;
  },
  order: 70,
);
final blobSize = EnumVariant(BlobSize.values, order: 60);
