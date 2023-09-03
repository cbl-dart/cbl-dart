// TODO(blaugold): Migrate to collection API.
// ignore_for_file: deprecated_member_use

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('Typed Database', () {
    group('saveTypedDocument', () {
      apiTest('throws if database does not support typed data', () async {
        final db = await openTestDatabase();
        final doc = MutableTestDocA();

        expect(
          () => db.saveTypedDocument(doc).withConcurrencyControl(),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      apiTest('with concurrency control', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();

        expect(
          await db.saveTypedDocument(doc).withConcurrencyControl(),
          isTrue,
        );
        expect(doc.internal.revisionId, isNotNull);
      });

      group('with conflict handler', () {
        apiTest('no conflict', () async {
          final db = await openTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableTestDocA();

          expect(
            await db
                .saveTypedDocument(doc)
                .withConflictHandler((oldDoc, newDoc) => true),
            isTrue,
          );
          expect(
            (await db.document(doc.internal.id))!.revisionId,
            doc.internal.revisionId,
          );
        });

        apiTest('resolving to abort save', () async {
          final db = await openTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableTestDocA();
          await db.saveTypedDocument(doc).withConcurrencyControl();
          final conflictingDoc = doc.toMutable();
          await db.saveTypedDocument(conflictingDoc).withConcurrencyControl();

          expect(
            await db.saveTypedDocument(doc).withConflictHandler(
              expectAsync2((documentBeingSaved, conflictingDocument) {
                expect(documentBeingSaved, same(doc));
                expect(
                  conflictingDocument!.internal.revisionId,
                  conflictingDoc.internal.revisionId,
                );
                return false;
              }),
            ),
            isFalse,
          );
          expect(
            (await db.document(doc.internal.id))!.revisionId,
            conflictingDoc.internal.revisionId,
          );
        });

        apiTest('resolving to retry save', () async {
          final db = await openTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableTestDocA();
          await db.saveTypedDocument(doc).withConcurrencyControl();
          final conflictingDoc = doc.toMutable();
          await db.saveTypedDocument(conflictingDoc).withConcurrencyControl();

          expect(
            await db.saveTypedDocument(doc).withConflictHandler(
              expectAsync2((documentBeingSaved, conflictingDocument) {
                expect(documentBeingSaved, same(doc));
                expect(
                  conflictingDocument!.internal.revisionId,
                  conflictingDoc.internal.revisionId,
                );
                return true;
              }),
            ),
            isTrue,
          );
          expect(
            (await db.document(doc.internal.id))!.revisionId,
            doc.internal.revisionId,
          );
        });
      });

      group('with sync conflict handler', () {
        test('no conflict', () {
          final db = openSyncTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableTestDocA();

          expect(
            db
                .saveTypedDocument(doc)
                .withConflictHandlerSync((oldDoc, newDoc) => true),
            isTrue,
          );
          expect(
            db.document(doc.internal.id)!.revisionId,
            doc.internal.revisionId,
          );
        });

        apiTest('resolving to abort save', () {
          final db = openSyncTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableTestDocA();
          db.saveTypedDocument(doc).withConcurrencyControl();
          final conflictingDoc = doc.toMutable();
          db.saveTypedDocument(conflictingDoc).withConcurrencyControl();

          expect(
            db.saveTypedDocument(doc).withConflictHandlerSync(
              expectAsync2((documentBeingSaved, conflictingDocument) {
                expect(documentBeingSaved, same(doc));
                expect(
                  conflictingDocument!.internal.revisionId,
                  conflictingDoc.internal.revisionId,
                );
                return false;
              }),
            ),
            isFalse,
          );
          expect(
            db.document(doc.internal.id)!.revisionId,
            conflictingDoc.internal.revisionId,
          );
        });

        apiTest('resolving to retry save', () {
          final db = openSyncTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableTestDocA();
          db.saveTypedDocument(doc).withConcurrencyControl();
          final conflictingDoc = doc.toMutable();
          db.saveTypedDocument(conflictingDoc).withConcurrencyControl();

          expect(
            db.saveTypedDocument(doc).withConflictHandlerSync(
              expectAsync2((documentBeingSaved, conflictingDocument) {
                expect(documentBeingSaved, same(doc));
                expect(
                  conflictingDocument!.internal.revisionId,
                  conflictingDoc.internal.revisionId,
                );
                return true;
              }),
            ),
            isTrue,
          );
          expect(
            db.document(doc.internal.id)!.revisionId,
            doc.internal.revisionId,
          );
        });
      });
    });

    group('typedDocument', () {
      apiTest('throws if database does not support typed data', () async {
        final db = await openTestDatabase();

        expect(
          () => db.typedDocument<TestDocA>('a'),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      apiTest('document does not exist', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);

        final loadedDoc = await db.typedDocument<TestDocA>('a');
        expect(loadedDoc, isNull);
      });

      apiTest('load immutable doc with static type', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();
        await db.saveTypedDocument(doc).withConcurrencyControl();

        final loadedDoc = await db.typedDocument<TestDocA>(doc.internal.id);
        expect(loadedDoc, isNotNull);
        expect(loadedDoc!.internal.id, doc.internal.id);
        expect(loadedDoc.internal.sequence, doc.internal.sequence);
        expect(loadedDoc.internal.revisionId, doc.internal.revisionId);
      });

      apiTest('load mutable doc with static type', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();
        await db.saveTypedDocument(doc).withConcurrencyControl();

        final loadedDoc =
            await db.typedDocument<MutableTestDocA>(doc.internal.id);
        expect(loadedDoc, isNotNull);
        expect(loadedDoc!.internal.id, doc.internal.id);
        expect(loadedDoc.internal.sequence, doc.internal.sequence);
        expect(loadedDoc.internal.revisionId, doc.internal.revisionId);
      });

      apiTest('load immutable doc with dynamic type', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();
        await db.saveTypedDocument(doc).withConcurrencyControl();

        expect(
          await db.typedDocument(doc.internal.id),
          isA<TestDocA>(),
        );
      });

      apiTest('load mutable doc with dynamic type', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();
        await db.saveTypedDocument(doc).withConcurrencyControl();

        expect(
          await db.typedDocument<TypedMutableDocumentObject>(doc.internal.id),
          isA<MutableTestDocA>(),
        );
      });

      apiTest('loaded document fails type check', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableDocument({'type': 'WrongType'});
        await db.saveDocument(doc);

        expect(
          () => db.typedDocument<TestDocA>(doc.id),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typeMatchingConflict)
                .havingMessage(
                  'Expected to find a document that matches the type matcher '
                  'of TestDocA, but found a document that matches the type '
                  'matchers of the following types: []',
                ),
          ),
        );
      });

      apiTest('loaded document matches incorrect type check', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableDocument({'type': 'TestDocB'});
        await db.saveDocument(doc);

        expect(
          () => db.typedDocument<TestDocA>(doc.id),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typeMatchingConflict)
                .havingMessage(
                  'Expected to find a document that matches the type matcher '
                  'of TestDocA, but found a document that matches the type '
                  'matchers of the following types: [TestDocB]',
                ),
          ),
        );
      });

      apiTest(
        'loaded document matches type check(s) for type without type matcher',
        () async {
          final db = await openTestDatabase(typedDataAdapter: testAdapter);
          final doc = MutableDocument({'type': 'TestDocA'});
          await db.saveDocument(doc);

          expect(
            () => db.typedDocument<TestDocWithoutTypeMatcher>(doc.id),
            throwsA(
              isTypedDataException
                  .havingCode(TypedDataErrorCode.typeMatchingConflict)
                  .havingMessage(
                    'Expected to find a document that matches no type matcher, '
                    'but found a document that matches the type matchers of '
                    'the following types: [TestDocA]',
                  ),
            ),
          );
        },
      );
    });

    group('deleteTypedDocument', () {
      apiTest('throws if database does not support typed data', () async {
        final db = await openTestDatabase();
        final doc = MutableTestDocA();

        expect(
          () => db.deleteTypedDocument(doc),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      apiTest('deletes document', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();
        await db.saveTypedDocument(doc).withConcurrencyControl();

        expect(await db.deleteTypedDocument(doc), isTrue);
        expect(await db.typedDocument<TestDocA>(doc.internal.id), isNull);
      });
    });

    group('purgeTypedDocument', () {
      apiTest('throws if database does not support typed data', () async {
        final db = await openTestDatabase();
        final doc = MutableTestDocA();

        expect(
          () => db.purgeTypedDocument(doc),
          throwsA(
            isTypedDataException
                .havingCode(TypedDataErrorCode.typedDataNotSupported),
          ),
        );
      });

      apiTest('purges document', () async {
        final db = await openTestDatabase(typedDataAdapter: testAdapter);
        final doc = MutableTestDocA();
        await db.saveTypedDocument(doc).withConcurrencyControl();

        await db.purgeTypedDocument(doc);
        expect(await db.typedDocument<TestDocA>(doc.internal.id), isNull);
      });
    });
  });
}

class TestDocA<I extends Document>
    implements TypedDocumentObject<MutableTestDocA> {
  TestDocA(this.internal);

  @override
  final I internal;

  @override
  MutableTestDocA toMutable() => MutableTestDocA(internal.toMutable());

  @override
  String toString({String? indent}) => super.toString();
}

class MutableTestDocA extends TestDocA<MutableDocument>
    implements TypedMutableDocumentObject<TestDocA, MutableTestDocA> {
  MutableTestDocA([MutableDocument? document])
      : super(document ?? MutableDocument());

  @override
  String toString({String? indent}) => super.toString();
}

class TestDocB<I extends Document>
    implements TypedDocumentObject<MutableTestDocB> {
  TestDocB(this.internal);

  @override
  final I internal;

  @override
  MutableTestDocB toMutable() => MutableTestDocB(internal.toMutable());

  @override
  String toString({String? indent}) => super.toString();
}

class MutableTestDocB extends TestDocB<MutableDocument>
    implements TypedMutableDocumentObject<TestDocB, MutableTestDocB> {
  MutableTestDocB([MutableDocument? document])
      : super(document ?? MutableDocument());
}

class TestDocWithoutTypeMatcher<I extends Document>
    implements TypedDocumentObject<MutableTestDocWithoutTypeMatcher> {
  TestDocWithoutTypeMatcher(this.internal);

  @override
  final I internal;

  @override
  MutableTestDocWithoutTypeMatcher toMutable() =>
      MutableTestDocWithoutTypeMatcher(internal.toMutable());

  @override
  String toString({String? indent}) => super.toString();
}

class MutableTestDocWithoutTypeMatcher
    extends TestDocWithoutTypeMatcher<MutableDocument>
    implements
        TypedMutableDocumentObject<TestDocWithoutTypeMatcher,
            MutableTestDocWithoutTypeMatcher> {
  MutableTestDocWithoutTypeMatcher([MutableDocument? document])
      : super(document ?? MutableDocument());
}

final testAdapter = TypedDataRegistry(
  types: [
    TypedDocumentMetadata<TestDocA, MutableTestDocA>(
      dartName: 'TestDocA',
      factory: TestDocA.new,
      mutableFactory: MutableTestDocA.new,
      typeMatcher: const ValueTypeMatcher(),
    ),
    TypedDocumentMetadata<TestDocB, MutableTestDocB>(
      dartName: 'TestDocB',
      factory: TestDocB.new,
      mutableFactory: MutableTestDocB.new,
      typeMatcher: const ValueTypeMatcher(),
    ),
    TypedDocumentMetadata<TestDocWithoutTypeMatcher,
        MutableTestDocWithoutTypeMatcher>(
      dartName: 'TestDocWithoutTypeMatcher',
      factory: TestDocWithoutTypeMatcher.new,
      mutableFactory: MutableTestDocWithoutTypeMatcher.new,
    ),
  ],
);
