import 'package:cbl_ffi/cbl_ffi.dart';

import '../fleece/containers.dart';
import '../fleece/integration/context.dart';
import '../fleece/integration/root.dart';
import '../service/cbl_service_api.dart';
import '../support/encoding.dart';
import 'document.dart';

class ProxyDocumentDelegate extends DocumentDelegate {
  ProxyDocumentDelegate.fromState(DocumentState state)
      : assert(state.properties != null),
        id = state.id,
        _revisionId = state.revisionId,
        _sequence = state.sequence,
        properties = state.properties?.encodedData,
        _propertiesDict = state.properties?.value?.asDict;

  ProxyDocumentDelegate.fromDelegate(DocumentDelegate delegate)
      : id = delegate.id,
        _revisionId = delegate.revisionId,
        _sequence = delegate.sequence,
        properties = delegate.properties,
        _propertiesDict =
            delegate is ProxyDocumentDelegate ? delegate._propertiesDict : null;

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
  MRoot createMRoot(MContext context, {required bool isMutable}) {
    final propertiesDict = _propertiesDict;
    if (propertiesDict != null) {
      final result = MRoot.fromValue(
        propertiesDict.pointer,
        context: context,
        isMutable: isMutable,
      );
      cblReachabilityFence(propertiesDict);
      return result;
    }

    return MRoot.fromData(
      properties!.toFleece(),
      context: context,
      isMutable: isMutable,
    );
  }

  @override
  DocumentDelegate toMutable() => ProxyDocumentDelegate.fromDelegate(this);

  void updateMetadata(DocumentState state) {
    assert(state.id == id);

    _revisionId = state.revisionId;
    _sequence = state.sequence;
  }

  DocumentState getState({bool withProperties = true}) => DocumentState(
        id: id,
        revisionId: revisionId,
        sequence: sequence,
        properties: withProperties
            ? TransferableValue.fromEncodedData(properties!)
            : null,
      );
}
