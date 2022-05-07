import '../document.dart';
import 'typed_object.dart';

typedef Factory<I, D> = D Function(I internal);

abstract class TypedDataAdapter {
  void checkDocumentIsOfType<D extends TypedDocumentObject>(Document doc);

  Factory<Dictionary, D>
      dictionaryFactoryForType<D extends TypedDictionaryObject>();

  Factory<Document, D> documentFactoryForType<D extends TypedDocumentObject>();

  Factory<Document, D?>
      dynamicDocumentFactoryForType<D extends TypedDocumentObject>({
    bool allowUnmatchedDocument = true,
  });

  void willSaveDocument(TypedMutableDocumentObject document);
}
