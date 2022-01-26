import 'package:meta/meta.dart';

import 'database.dart';
import 'document.dart';
import 'query.dart';
import 'support/tracing.dart';

late final TraceDataHandler? _onTraceData = onTraceData;

/// A delegate which implements a tracing mechanism for CBL Dart.
///
/// # Trace points
///
/// CBL Dart has builtin trace points, at which the flow control is given to
/// the current [TracingDelegate]:
///
///   * [traceSyncOperation] for synchronous operations.
///   * [traceAsyncOperation] for asynchronous operations.
///
/// # Primary and secondary isolates
///
/// Every isolate in which CBL Dart is used has one [TracingDelegate], which
/// cannot be changed. When initializing CBL Dart, a [TracingDelegate] can
/// be provided, which will become the delegate for the current (or primary)
/// isolate. Each time CBL Dart creates background (or secondary) isolates,
/// [createSecondaryIsolateDelegate] is called on the primary isolate delegate
/// and the returned delegate is used as the delegate for the new isolate.
///
/// ## Tracing context
///
/// When a primary isolate sends a message to a secondary isolate, the
/// primary isolate's [TracingDelegate] can provide a tracing context, which
/// is send to the secondary isolate, along with the message. When a secondary
/// isolate receives a message, it's delegate can restore the tracing context.
/// Typically, the tracing context is stored in a zone value and
/// [captureTracingContext] and [restoreTracingContext] are used to transfer
/// this value. The value returned by [captureTracingContext] must be JSON
/// serializable.
///
/// ## Trace data
///
/// A secondary isolate can send arbitrary data through [sendTraceData] to its
/// primary isolate, which will receive the data through a call to
/// [onTraceData]. The data has to be JSON serializable.
///
/// {@category Tracing}
abstract class TracingDelegate {
  /// Const constructor for subclasses.
  const TracingDelegate();

  /// Creates a new [TracingDelegate], to be used for a secondary isolate,
  /// which is about to be created by the current isolate.
  ///
  /// The returned object must be able to be passed from the current isolate to
  /// to the secondary isolate.
  ///
  /// The default implementation returns `this`.
  // ignore: avoid_returning_this
  TracingDelegate createSecondaryIsolateDelegate() => this;

  /// Allows this delegate to send arbitrary data to the delegate in its
  /// primary isolate.
  ///
  /// The [data] must be JSON serializable and this delegate must be in a
  /// secondary isolate.
  @protected
  @mustCallSuper
  void sendTraceData(Object? data) {
    if (_onTraceData == null) {
      throw StateError('The current isolate cannot send trace data.');
    }
    _onTraceData!(data);
  }

  /// Callback for receiving trace data from delegates in secondary isolates.
  ///
  /// When a delegate in a secondary isolate calls [sendTraceData], the data
  /// is sent to the primary isolate, which calls this callback.
  @visibleForOverriding
  void onTraceData(Object? data) {}

  /// Returns the current tracing context and is called just before a message
  /// is sent from a primary to a secondary isolate.
  ///
  /// The returned value must be JSON serializable.
  Object? captureTracingContext() => null;

  /// Restores the tracing context and is called just after a message from a
  /// secondary is received a a secondary isolate.
  ///
  /// The provided [context] is the value that was returned by
  /// [captureTracingContext], when the message was sent.
  ///
  /// When this method is called, it must call [restore] exactly once,
  /// and do so before returning.
  void restoreTracingContext(Object? context, void Function() restore) {
    restore();
  }

  /// Called when a synchronous [operation] trace point is reached.
  ///
  /// [T] is the type of the result of the operation.
  ///
  /// The method must call [execute] exactly once. [execute] might throw an
  /// exception. This method must return the same value as [execute] or throw
  /// the same exception as [execute].
  T traceSyncOperation<T>(
    TracedOperation operation,
    T Function() execute,
  ) =>
      execute();

  /// Called when an asynchronous [operation] trace point is reached.
  ///
  /// [T] is the type of the result of the operation.
  ///
  /// The method must call [execute] exactly once. [execute] might throw a
  /// synchronous exception or return a [Future] that completes with an
  /// exception. This method must return a [Future] that completes with the same
  /// value as [execute] or completes with the same exception as [execute].
  Future<T> traceAsyncOperation<T>(
    TracedOperation operation,
    Future<T> Function() execute,
  ) =>
      execute();
}

/// A traced operation.
///
/// The same type operation may be traced both at a synchronous and asynchronous
/// trace point. The corresponding [TracingDelegate] method will be invoked
/// depending on whether the operation is synchronous
/// ([TracingDelegate.traceSyncOperation]), or asynchronous
/// ([TracingDelegate.traceAsyncOperation]).
///
/// {@category Tracing}
abstract class TracedOperation {
  /// Constructor for subclasses.
  TracedOperation(this.name);

  /// The name of this operation.
  final String name;
}

/// A call to a native function.
///
/// {@category Tracing}
class NativeCallOp extends TracedOperation {
  NativeCallOp(String name) : super(name);
}

/// Operation that opens a [Database].
///
/// {@category Tracing}
class OpenDatabaseOp extends TracedOperation {
  OpenDatabaseOp(this.databaseName, this.config) : super('OpenDatabase');

  /// The name of the database to open.
  final String databaseName;

  /// The configuration which is used to open the database.
  final DatabaseConfiguration? config;
}

/// Operation that involves a [Database].
///
/// {@category Tracing}
abstract class DatabaseOperationOp extends TracedOperation {
  DatabaseOperationOp(this.database, String name) : super(name);

  /// The database involved in this operation.
  final Database database;
}

/// Operation that closes a [Database].
///
/// {@category Tracing}
class CloseDatabaseOp extends DatabaseOperationOp {
  CloseDatabaseOp(Database database) : super(database, 'CloseDatabase');
}

/// Operation that loads a [Document] from a [Database].
///
/// {@category Tracing}
class GetDocumentOp extends DatabaseOperationOp {
  GetDocumentOp(Database database, this.id) : super(database, 'GetDocument');

  /// The id of the document to load.
  final String id;
}

/// Operation that prepares a [Document] to be saved or deleted.
///
/// {@category Tracing}
class PrepareDocumentOp extends TracedOperation {
  PrepareDocumentOp(this.document) : super('PrepareDocument');

  /// The document to prepare.
  final Document document;
}

/// Operation that saves a [Document] to a [Database].
///
/// {@category Tracing}
class SaveDocumentOp extends DatabaseOperationOp {
  SaveDocumentOp(Database database, this.document, [this.concurrencyControl])
      : super(database, 'SaveDocument');

  /// The document to save.
  final Document document;

  /// The concurrency control to use.
  final ConcurrencyControl? concurrencyControl;

  /// Whether a conflict handler is used to resolve conflicts.
  ///
  /// When this is `false`, [concurrencyControl] is used to resolve conflicts
  /// instead.
  bool get withConflictHandler => concurrencyControl == null;
}

/// Operation that deletes a [Document] from a [Database].
///
/// {@category Tracing}
class DeleteDocumentOp extends DatabaseOperationOp {
  DeleteDocumentOp(Database database, this.document, this.concurrencyControl)
      : super(database, 'DeleteDocument');

  /// The document to delete.
  final Document document;

  /// The concurrency control to use.
  final ConcurrencyControl concurrencyControl;
}

/// Operation that involves a [Query].
///
/// {@category Tracing}
class QueryOperationOp extends TracedOperation {
  QueryOperationOp(this.query, String name) : super(name);

  /// The query involved in this operation.
  final Query query;
}

/// Operation that prepares a [Query] to be used.
///
/// {@category Tracing}
class PrepareQueryOp extends QueryOperationOp {
  PrepareQueryOp(Query query) : super(query, 'PrepareQuery');
}

/// Operation that executes a [Query].
///
/// {@category Tracing}
class ExecuteQueryOp extends QueryOperationOp {
  ExecuteQueryOp(Query query) : super(query, 'ExecuteQuery');
}
