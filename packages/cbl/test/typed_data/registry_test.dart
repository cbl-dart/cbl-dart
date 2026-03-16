import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';
import 'package:test/test.dart';

// --- Test typed dictionary classes ---

class TestDict<I extends Dictionary>
    implements TypedDictionaryObject<MutableTestDict> {
  TestDict(this.internal);

  @override
  final I internal;

  @override
  MutableTestDict toMutable() => MutableTestDict(internal.toMutable());

  @override
  String toString({String? indent}) => 'TestDict()';
}

class MutableTestDict extends TestDict<MutableDictionary>
    implements TypedMutableDictionaryObject<TestDict, MutableTestDict> {
  MutableTestDict([MutableDictionary? internal])
    : super(internal ?? MutableDictionary());
}

// --- Test typed document classes ---

class TestDoc<I extends Document>
    implements TypedDocumentObject<MutableTestDoc> {
  TestDoc(this.internal);

  @override
  final I internal;

  String get id => internal.id;

  @override
  MutableTestDoc toMutable() => MutableTestDoc(internal.toMutable());

  @override
  String toString({String? indent}) => 'TestDoc(id: $id)';
}

class MutableTestDoc extends TestDoc<MutableDocument>
    implements TypedMutableDocumentObject<TestDoc, MutableTestDoc> {
  MutableTestDoc([MutableDocument? internal])
    : super(internal ?? MutableDocument({}));
}

void main() {
  group('TypedDataRegistry', () {
    group('dictionaryFactoryForType', () {
      test('returns factory for registered dictionary type', () {
        final registry = TypedDataRegistry(
          types: [
            TypedDictionaryMetadata<TestDict, MutableTestDict>(
              dartName: 'TestDict',
              factory: TestDict.new,
              mutableFactory: MutableTestDict.new,
            ),
          ],
        );

        final factory = registry.dictionaryFactoryForType<TestDict>();
        final dict = MutableDictionary({'key': 'value'});
        final result = factory(dict);
        expect(result, isA<TestDict>());
        expect(result.internal.value('key'), 'value');
      });

      test('throws with guidance when document type is used', () {
        final registry = TypedDataRegistry(
          types: [
            TypedDocumentMetadata<TestDoc, MutableTestDoc>(
              dartName: 'TestDoc',
              factory: TestDoc.new,
              mutableFactory: MutableTestDoc.new,
            ),
          ],
        );

        expect(
          () => registry.dictionaryFactoryForType<TestDoc>(),
          throwsA(
            isA<TypedDataException>()
                .having((e) => e.code, 'code', TypedDataErrorCode.unknownType)
                .having(
                  (e) => e.message,
                  'message',
                  contains('@TypedDictionary'),
                ),
          ),
        );
      });

      test('throws with guidance when mutable document type is used', () {
        final registry = TypedDataRegistry(
          types: [
            TypedDocumentMetadata<TestDoc, MutableTestDoc>(
              dartName: 'TestDoc',
              factory: TestDoc.new,
              mutableFactory: MutableTestDoc.new,
            ),
          ],
        );

        expect(
          () => registry.dictionaryFactoryForType<MutableTestDoc>(),
          throwsA(
            isA<TypedDataException>()
                .having((e) => e.code, 'code', TypedDataErrorCode.unknownType)
                .having(
                  (e) => e.message,
                  'message',
                  contains('@TypedDictionary'),
                ),
          ),
        );
      });

      test('throws for unregistered type', () {
        final registry = TypedDataRegistry();

        expect(
          () => registry.dictionaryFactoryForType<TestDict>(),
          throwsA(
            isA<TypedDataException>().having(
              (e) => e.code,
              'code',
              TypedDataErrorCode.unknownType,
            ),
          ),
        );
      });
    });
  });
}
