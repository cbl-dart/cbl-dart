import 'package:cbl/cbl.dart';
import 'package:cbl/src/replication/replicator.dart';
import 'package:cbl/src/replication/replicator_change.dart';
import 'package:test/test.dart';

import '../../test_binding_impl.dart';

void main() {
  setupTestBinding();

  group('ReplicatorChange', () {
    test('toString', () {
      final change = ReplicatorChangeImpl(_Replicator(), _ReplicatorStatus());
      expect(
        change.toString(),
        'ReplicatorChange('
        'replicator: _Replicator(), '
        'status: _ReplicatorStatus()'
        ')',
      );
    });
  });
}

class _Replicator implements Replicator {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_Replicator()';
}

class _ReplicatorStatus implements ReplicatorStatus {
  @override
  void noSuchMethod(Invocation invocation) {}

  @override
  String toString() => '_ReplicatorStatus()';
}
