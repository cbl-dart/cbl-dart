import 'package:cbl/cbl.dart';
import 'package:cbl/src/replication/replicator.dart';
import 'package:cbl/src/replication/replicator_change.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('ReplicatorChange', () {
    test('toString', () {
      final change = ReplicatorChangeImpl(_Replicator(), _ReplicatorStatus());
      expect(
        change.toString(),
        'ReplicatorChange('
        'replicator: _Replicator(), '
        // ignore: missing_whitespace_between_adjacent_strings
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
