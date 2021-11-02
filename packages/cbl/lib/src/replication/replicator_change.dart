import 'replicator.dart';

/// Event which is emitted when the status of a [Replicator] changes.
///
/// {@category Replication}
abstract class ReplicatorChange {
  /// The source [Replicator].
  Replicator get replicator;

  /// The status of the [replicator] when this event was emitted.
  ReplicatorStatus get status;
}

class ReplicatorChangeImpl implements ReplicatorChange {
  ReplicatorChangeImpl(this.replicator, this.status);

  @override
  final Replicator replicator;

  @override
  final ReplicatorStatus status;

  @override
  String toString() =>
      'ReplicatorChange(replicator: $replicator, status: $status)';
}
