import '../document.dart';
import 'typed_object.dart';

typedef Factory<I, D> = D Function(I internal);

/// The interface through which database, query and replicator implementations
/// interact with typed data.
abstract class TypedDataAdapter {
  /// Checks whether the given [document] is compatible with the typed document
  /// type [D], based on its properties.
  void checkDocumentIsOfType<D extends TypedDocumentObject>(Document document);

  /// Returns a factory for creating typed representations of [Dictionary]s with
  /// type [D].
  Factory<Dictionary, D>
      dictionaryFactoryForType<D extends TypedDictionaryObject>();

  /// Returns a factory for creating typed representations of [Document]s with
  /// type [D].
  Factory<Document, D> documentFactoryForType<D extends TypedDocumentObject>();

  /// Returns a factory for creating typed representations of [Document]s, which
  /// determines the typed document to instantiate based on its properties.
  ///
  /// The type argument [D] can be used whether a immutable or mutable variant
  /// of the document is created by specifying either [TypedDocumentObject] or
  /// [TypedMutableDocumentObject].
  ///
  /// If [allowUnmatchedDocument] is `true` and no typed document type can be
  /// matched for a [Document], the factory returns `null`. Otherwise the
  /// factory throws an exception.
  Factory<Document, D?>
      dynamicDocumentFactoryForType<D extends TypedDocumentObject>({
    bool allowUnmatchedDocument = true,
  });

  /// Callback that must be called each time before a typed document is saved to
  /// the database.
  void willSaveDocument(TypedMutableDocumentObject document);
}
