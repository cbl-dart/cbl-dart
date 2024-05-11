import 'package:cbl_native_assets/cbl.dart';
import 'package:cbl_native_assets/src/replication/replicator.dart';
import 'package:cbl_native_assets/src/replication/replicator_change.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('ReplicatorChange', () {
    test('toString', () {
      final status = ReplicatorStatus(
          ReplicatorActivityLevel.idle, ReplicatorProgress(0, 0), 0);
      final change = ReplicatorChangeImpl(_Replicator(), status);
      expect(
        change.toString(),
        'ReplicatorChange('
        'replicator: _Replicator(), '
        // ignore: missing_whitespace_between_adjacent_strings
        'status: $status'
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
