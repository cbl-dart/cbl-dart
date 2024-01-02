import '../bindings.dart';
import '../database/proxy_database.dart';
import '../fleece/containers.dart';
import '../fleece/integration/root.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import '../support/encoding.dart';
import 'document.dart';

class ProxyDocumentDelegate extends DocumentDelegate with ProxyObjectMixin {
  ProxyDocumentDelegate.fromState(
    DocumentState state, {
    ProxyDatabase? database,
    bool bindToProxiedDocument = true,
  })  : assert(state.properties != null),
        id = state.docId,
        _revisionId = state.revisionId,
        _sequence = state.sequence,
        properties = state.properties?.encodedData,
        _propertiesDict = state.properties?.value?.asDict {
    if (bindToProxiedDocument) {
      _bindToProxiedDocument(database!, state.id!);
    }
  }

  ProxyDocumentDelegate.fromDelegate(DocumentDelegate delegate)
      : id = delegate.id,
        _revisionId = delegate.revisionId,
        _sequence = delegate.sequence,
        properties = delegate.properties,
        _propertiesDict =
            delegate is ProxyDocumentDelegate ? delegate._propertiesDict : null;

  ProxyDocumentDelegate? _source;

  @override
  final String id;

  @override
  String? get revisionId => _revisionId;
  String? _revisionId;

  @override
  int get sequence => _sequence;
  int _sequence;

  @override
  EncodedData? properties;

  final Dict? _propertiesDict;

  @override
  MRoot createMRoot(DelegateDocument document, {required bool isMutable}) {
    final propertiesDict = _propertiesDict;
    if (propertiesDict != null) {
      return MRoot.fromContext(
        DocumentMContext(
          document,
          data: Value.fromPointer(propertiesDict.pointer),
        ),
        isMutable: isMutable,
      );
    }

    return MRoot.fromContext(
      DocumentMContext(
        document,
        data: Doc.fromResultData(properties!.toFleece(), FLTrust.trusted),
      ),
      isMutable: isMutable,
    );
  }

  @override
  DocumentDelegate toMutable() {
    assert(
      revisionId == null ||
          objectId != null ||
          (_source != null && _source!.objectId != null),
    );
    return ProxyDocumentDelegate.fromDelegate(this).._source = _source ?? this;
  }

  void updateMetadata(DocumentState state, {required ProxyDatabase? database}) {
    assert(state.id != null);
    assert(state.docId == id);

    if (objectId == null) {
      _bindToProxiedDocument(database!, state.id!);
      _source = null;
    }

    _revisionId = state.revisionId;
    _sequence = state.sequence;
  }

  DocumentState getState({bool withProperties = true}) => DocumentState(
        id: objectId,
        sourceId: _source?.objectId,
        docId: id,
        revisionId: revisionId,
        sequence: sequence,
        properties: withProperties
            ? TransferableValue.fromEncodedData(properties!)
            : null,
      );

  void _bindToProxiedDocument(ProxyDatabase database, int docObjectId) {
    // documentFinalizer is called when the database to which the document
    // belongs is closed. This ensures that the our DartFinalizerRegistry
    // implementation does not keep the Dart process running in case not all
    // documents have been garbage collected.
    //
    // It is important that documentFinalizer and proxyFinalizer don't capture
    // any references to this object.

    late final Future<void> Function() documentFinalizer;

    void proxyFinalizer() =>
        // If the document gets garbage collected, we need don't need to
        // finalize it when the database closes and we can unregister the
        // finalizer.
        () => database.unregisterDocumentFinalizer(documentFinalizer);

    bindToTargetObject(
      database.channel,
      docObjectId,
      proxyFinalizer: proxyFinalizer,
    );

    documentFinalizer = finalizeEarly;
    database.registerDocumentFinalizer(documentFinalizer);
  }
}
