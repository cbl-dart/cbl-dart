import '../service/cbl_service_api.dart';
import '../support/encoding.dart';
import 'document.dart';

class ProxyDocumentDelegate extends DocumentDelegate {
  ProxyDocumentDelegate.fromState(DocumentState state)
      : id = state.id,
        _revisionId = state.revisionId,
        _sequence = state.sequence,
        properties = state.properties!;

  ProxyDocumentDelegate.fromDelegate(DocumentDelegate delegate)
      : id = delegate.id,
        _revisionId = delegate.revisionId,
        _sequence = delegate.sequence,
        properties = delegate.properties;

  @override
  final String id;

  @override
  String? get revisionId => _revisionId;
  String? _revisionId;

  @override
  int get sequence => _sequence;
  int _sequence;

  @override
  late EncodedData properties;

  @override
  DocumentDelegate toMutable() => ProxyDocumentDelegate.fromDelegate(this);

  void setState(DocumentState state) {
    assert(id == state.id);

    _revisionId = state.revisionId;
    _sequence = state.sequence;

    final properties = state.properties;
    if (properties != null) {
      this.properties = properties;
    }
  }

  DocumentState getState({bool withProperties = true}) => DocumentState(
        id: id,
        revisionId: revisionId,
        sequence: sequence,
        properties: withProperties ? properties : null,
      );
}
