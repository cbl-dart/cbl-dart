import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/document/document.dart';
import 'package:cbl/src/fleece/integration/integration.dart';
import 'package:cbl/src/replication/conflict.dart';
import 'package:test/test.dart';

class _TestDocumentDelegate implements DocumentDelegate {
  _TestDocumentDelegate({required this.id, required this.timestamp});

  @override
  final String id;

  @override
  final int timestamp;

  @override
  String? get revisionId => null;

  @override
  int get sequence => 0;

  @override
  Data? encodedProperties;

  @override
  MRoot createMRoot(DelegateDocument document, {required bool isMutable}) =>
      MRoot.fromNative(
        MutableDictionary(),
        context: DocumentMContext(document),
        isMutable: isMutable,
      );

  @override
  DocumentDelegate toMutable() => this;
}

Document _testDocument({required String id, required int timestamp}) =>
    MutableDelegateDocument.fromDelegate(
      _TestDocumentDelegate(id: id, timestamp: timestamp),
    );

void main() {
  group('DefaultConflictResolver', () {
    const resolver = DefaultConflictResolver();

    test('local deleted returns null', () {
      final conflict = ConflictImpl(
        'doc',
        null,
        _testDocument(id: 'doc', timestamp: 100),
      );
      expect(resolver.resolve(conflict), isNull);
    });

    test('remote deleted returns null', () {
      final conflict = ConflictImpl(
        'doc',
        _testDocument(id: 'doc', timestamp: 100),
        null,
      );
      expect(resolver.resolve(conflict), isNull);
    });

    test('both deleted returns null', () {
      final conflict = ConflictImpl('doc', null, null);
      expect(resolver.resolve(conflict), isNull);
    });

    test('local has later timestamp returns local', () {
      final local = _testDocument(id: 'doc', timestamp: 200);
      final remote = _testDocument(id: 'doc', timestamp: 100);
      final conflict = ConflictImpl('doc', local, remote);
      expect(resolver.resolve(conflict), same(local));
    });

    test('remote has later timestamp returns remote', () {
      final local = _testDocument(id: 'doc', timestamp: 100);
      final remote = _testDocument(id: 'doc', timestamp: 200);
      final conflict = ConflictImpl('doc', local, remote);
      expect(resolver.resolve(conflict), same(remote));
    });

    test('equal timestamps returns remote', () {
      final local = _testDocument(id: 'doc', timestamp: 100);
      final remote = _testDocument(id: 'doc', timestamp: 100);
      final conflict = ConflictImpl('doc', local, remote);
      expect(resolver.resolve(conflict), same(remote));
    });
  });
}
