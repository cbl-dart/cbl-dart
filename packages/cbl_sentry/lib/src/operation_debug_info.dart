import 'package:cbl/cbl.dart';

import 'utils.dart';

extension OperationDebugInfoExt on TracedOperation {
  String debugName({required bool isInWorker}) {
    final self = this;
    if (self is ChannelCallOp) {
      return 'cbl.channel.${self.name.uncapitalized}';
    }
    if (self is NativeCallOp) {
      return 'cbl.native.$name';
    }
    return 'cbl.${name.uncapitalized}${isInWorker ? '.worker' : ''}';
  }

  String? get debugDescription {
    final self = this;

    // === Concrete operations =================================================
    // These operations need to be handled before the operation interfaces.

    if (self is OpenDatabaseOp) {
      return self.databaseName;
    }
    if (self is GetDocumentOp) {
      return self.id;
    }

    // === Operation interfaces ================================================
    // Document operations need to be handled before database operations because
    // they implement `DatabaseOperationOp`, as well.

    if (self is DocumentOperationOp) {
      return self.document.id;
    }
    if (self is DatabaseOperationOp) {
      return self.database.name;
    }
    if (self is QueryOperationOp) {
      return self.query.jsonRepresentation ?? self.query.n1ql;
    }

    return null;
  }

  Map<String, Object?>? get debugDetails {
    final self = this;

    if (self is SaveDocumentOp) {
      final concurrencyControl = self.concurrencyControl;
      return {
        if (concurrencyControl != null)
          'concurrencyControl': concurrencyControl.name,
        if (self.withConflictHandler) 'withConflictHandler': true,
      };
    }

    if (self is DeleteDocumentOp) {
      return {'concurrencyControl': self.concurrencyControl.name};
    }

    return null;
  }
}
