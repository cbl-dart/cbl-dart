import '../bindings.dart';
import '../database/proxy_database.dart';
import '../fleece/containers.dart';
import '../fleece/integration/root.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import 'document.dart';

final class ProxyDocumentDelegate
    with ProxyObjectMixin
    implements DocumentDelegate {
  ProxyDocumentDelegate.fromState(
    DocumentState state, {
    ProxyDatabase? database,
    bool bindToProxiedDocument = true,
  })  : assert(state.properties != null),
        id = state.docId,
        _revisionId = state.revisionId,
        _sequence = state.sequence,
        encodedProperties = state.properties?.encodedValue,
        _propertiesDict = state.properties?.value.asDict {
    if (bindToProxiedDocument) {
      _bindToProxiedDocument(database!, state);
    }
  }

  ProxyDocumentDelegate.fromDelegate(DocumentDelegate delegate)
      : id = delegate.id,
        _revisionId = delegate.revisionId,
        _sequence = delegate.sequence,
        encodedProperties = delegate.encodedProperties,
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
  Data? encodedProperties;

  final Dict? _propertiesDict;

  @override
  MRoot createMRoot(DelegateDocument document, {required bool isMutable}) {
    if (_propertiesDict case final dict?) {
      return MRoot.fromContext(
        DocumentMContext(
          document,
          data: Value.fromPointer(dict.pointer),
        ),
        isMutable: isMutable,
      );
    }

    return MRoot.fromContext(
      DocumentMContext(
        document,
        data: Doc.fromResultData(encodedProperties!, FLTrust.trusted),
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
      _bindToProxiedDocument(database!, state);
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
            ? SendableValue.fromEncodedValue(encodedProperties!)
            : null,
      );

  void _bindToProxiedDocument(ProxyDatabase database, DocumentState state) =>
      bindToTargetObject(database.channel, state.id!);
}
