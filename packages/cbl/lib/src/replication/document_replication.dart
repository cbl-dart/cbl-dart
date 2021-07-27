import '../document.dart';
import 'configuration.dart';
import 'replicator.dart';

/// Event which is emitted when [Document]s have been replicated.
abstract class DocumentReplication {
  /// The source [Replicator].
  Replicator get replicator;

  /// Whether the [replicator] is pushing or pulling the [documents].
  bool get isPush;

  /// A list of replicated [Document]s.
  List<ReplicatedDocument> get documents;
}

/// Information about a [Document] that has been replicated.
abstract class ReplicatedDocument {
  /// The id of the replicated [Document].
  String get id;

  /// Flags describing the replicated [Document].
  Set<DocumentFlag> get flags;

  /// An error which occurred during replication of the [Document].
  ///
  /// Is `null`, if the replication was successful.
  Object? get error;
}

class DocumentReplicationImpl implements DocumentReplication {
  DocumentReplicationImpl(this.replicator, this.isPush, this.documents);

  @override
  final Replicator replicator;

  @override
  final bool isPush;

  @override
  final List<ReplicatedDocument> documents;

  @override
  String toString() => [
        'DocumentReplication(',
        [
          'replicator: $replicator',
          if (isPush) 'PUSH' else 'PULL',
          documents,
        ].join(', '),
        ')'
      ].join();
}

class ReplicatedDocumentImpl implements ReplicatedDocument {
  ReplicatedDocumentImpl(this.id, [this.flags = const {}, this.error]);

  @override
  final String id;

  @override
  final Set<DocumentFlag> flags;

  @override
  final Object? error;

  @override
  String toString() => [
        'ReplicatedDocument(',
        [
          id,
          for (var flag in flags)
            if (flag == DocumentFlag.accessRemoved)
              'ACCESS-REMOVED'
            else if (flag == DocumentFlag.deleted)
              'DELETED',
          if (error != null) 'error: $error',
        ].join(', '),
        ')'
      ].join();
}
