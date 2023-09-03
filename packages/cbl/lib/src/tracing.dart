import 'dart:async';
import 'dart:developer';

import 'package:meta/meta.dart';

import 'database.dart';
import 'document.dart';
import 'query.dart';
import 'support/isolate.dart';
import 'support/tracing.dart';

TraceDataHandler get _onTraceData => onTraceData;

/// A delegate which implements a tracing mechanism for CBL Dart.
///
/// The tracing API is **experimental** and subject to change.
///
/// # Trace points
///
/// CBL Dart has builtin trace points, at which flow control is given to the
/// [TracingDelegate]:
///
/// - [traceSyncOperation] for synchronous operations.
/// - [traceAsyncOperation] for asynchronous operations.
///
/// See [TracedOperation] and its subclasses for all operations can can be
/// traced.
///
/// # Lifecycle
///
/// The [initialize] method is called when a isolate is [install]ed, if CBL Dart
/// has already been initialized. If CBL Dart has not been initialized when
/// [install] is called, the delegate is initialized after CBL Dart has been
/// initialized.
///
/// The [close] method is called when a delegate is [uninstall]ed.
///
/// A delegate might be installed and uninstalled multiple times.
///
/// # User and worker isolates
///
/// User isolates are isolates in which CBL Dart is used but that are not
/// created by CBL Dart. For every user isolate, a [TracingDelegate] can be
/// installed through [install] and uninstalled again through [uninstall]. It is
/// usually a mistake to uninstall the current delegate while worker isolates
/// with delegates created by the current delegate are still running.
///
/// Each time CBL Dart creates a worker isolate, [createWorkerDelegate] is
/// called on the user isolate delegate and the returned delegate is installed
/// in the new isolate.
///
/// ## Tracing context
///
/// When a user isolate sends a message to a worker isolate, the user isolate's
/// [TracingDelegate] can provide a tracing context, which is sent to the worker
/// isolate along with the message. When a worker isolate receives a message,
/// it's delegate can restore the tracing context. Typically, the tracing
/// context is stored in a zone value and [captureTracingContext] and
/// [restoreTracingContext] are used to transfer this value. The value returned
/// by [captureTracingContext] must be JSON serializable.
///
/// ## Trace data
///
/// A delegate in a worker isolate can send arbitrary data through
/// [sendTraceData] to the delegate in the user isolate, which will receive the
/// data through a call to [onTraceData]. The data has to be JSON serializable.
///
/// {@category Tracing}
abstract class TracingDelegate {
  /// Const constructor for subclasses.
  const TracingDelegate();

  /// Whether a [TracingDelegate] has been installed for this isolate.
  ///
  /// See also:
  ///
  /// - [install] for installing a [TracingDelegate] for this isolate.
  /// - [uninstall] for uninstalling the current [TracingDelegate].
  static bool get hasBeenInstalled => _hasBeenInstalled;
  static bool _hasBeenInstalled = false;

  /// Installs a [TracingDelegate] for the current isolate.
  ///
  /// Only one [TracingDelegate] can be installed for a single isolate at any
  /// given moment.
  ///
  /// Whether a [TracingDelegate] has been installed for this isolate can be
  /// checked with [hasBeenInstalled].
  static Future<void> install(TracingDelegate delegate) async {
    if (_hasBeenInstalled) {
      throw StateError('A TracingDelegate has already been installed.');
    }

    _hasBeenInstalled = true;
    currentTracingDelegate = delegate;
    await addPostIsolateInitTask(delegate.initialize);
  }

  /// Uninstalls a [TracingDelegate] from the current isolate.
  ///
  /// The given [delegate] must be the current delegate for this isolate.
  ///
  /// It is usually a mistake to uninstall the current delegate while worker
  /// isolates with delegates created by the current delegate are still running.
  ///
  /// After the current delegate has been uninstalled, a new delegate can be
  /// installed through [install].
  static Future<void> uninstall(TracingDelegate delegate) async {
    if (currentTracingDelegate != delegate) {
      throw StateError('The given TracingDelegate is not installed: $delegate');
    }

    _hasBeenInstalled = false;
    currentTracingDelegate = const NoopTracingDelegate();
    await removePostIsolateInitTask(delegate.initialize);
    await delegate.close();
  }

  /// Creates a new [TracingDelegate] to be used for a worker isolate, which is
  /// about to be created by the current isolate.
  ///
  /// The returned object must be able to be passed from the current isolate to
  /// the worker isolate.
  ///
  /// The default implementation returns `this`.
  // ignore: avoid_returning_this
  TracingDelegate createWorkerDelegate() => this;

  /// Called before this delegate is used as the current delegate.
  ///
  /// This allows a delegate to initialize itself and its environment.
  FutureOr<void> initialize() {}

  /// Called after this delegate is no longer used as the current delegate.
  ///
  /// This allows a delegate to clean up and free resources.
  FutureOr<void> close() {}

  /// Allows this delegate to send arbitrary data to the delegate it was created
  /// by.
  ///
  /// The [data] must be JSON serializable and this delegate must be in a worker
  /// isolate.
  @protected
  @mustCallSuper
  void sendTraceData(Object? data) => _onTraceData(data);

  /// Callback for receiving trace data from delegates in worker isolates.
  ///
  /// When a delegate in a worker isolate calls [sendTraceData], the data is
  /// sent to the user isolate, which calls this callback.
  @visibleForOverriding
  void onTraceData(Object? data) {}

  /// Returns the current tracing context and is called just before a message is
  /// sent from an user to a worker isolate.
  ///
  /// The returned value must be JSON serializable.
  Object? captureTracingContext() => null;

  /// Restores the tracing context and is called just after a message from a
  /// user isolate is received by a worker isolate.
  ///
  /// The provided [context] is the value that was returned by
  /// [captureTracingContext], when the message was sent.
  ///
  /// When this method is called, it must call [restore] exactly once, and do so
  /// before returning.
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
/// The same type of operation may be traced both at a synchronous and
/// asynchronous trace point. The corresponding [TracingDelegate] method will be
/// invoked depending on whether the operation is synchronous
/// ([TracingDelegate.traceSyncOperation]), or asynchronous
/// ([TracingDelegate.traceAsyncOperation]).
///
/// {@category Tracing}
abstract class TracedOperation {
  /// Constructor for subclasses.
  TracedOperation(this.name);

  /// The name of this operation.
  final String name;

  @override
  String toString() => '$runtimeType($name)';
}

/// A call to a native function.
///
/// {@category Tracing}
class NativeCallOp extends TracedOperation {
  NativeCallOp(super.name);
}

/// A call over a communication channel.
///
/// {@category Tracing}
class ChannelCallOp extends TracedOperation {
  ChannelCallOp(super.name);
}

/// Operation that initializes CBL Dart.
///
/// {@category Tracing}
class InitializeOp extends TracedOperation {
  InitializeOp() : super('Initialize');
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

/// Operation that involves a [Collection].
///
/// {@category Tracing}
abstract class CollectionOperationOp extends TracedOperation {
  CollectionOperationOp(this.collection, String name) : super(name);

  /// The collection involved in this operation.
  final Collection collection;
}

/// Operation that involves a [Document].
///
/// {@category Tracing}
abstract class DocumentOperationOp implements TracedOperation {
  /// The document involved in this operation.
  Document get document;
}

/// Operation that loads a [Document] from a [Collection].
///
/// {@category Tracing}
class GetDocumentOp extends CollectionOperationOp {
  GetDocumentOp(Collection collection, this.id)
      : super(collection, 'GetDocument');

  /// The id of the document to load.
  final String id;
}

/// Operation that prepares a [Document] to be saved or deleted.
///
/// {@category Tracing}
class PrepareDocumentOp extends TracedOperation implements DocumentOperationOp {
  PrepareDocumentOp(this.document) : super('PrepareDocument');

  /// The document to prepare.
  @override
  final Document document;
}

/// Operation that saves a [Document] to a [Collection].
///
/// {@category Tracing}
class SaveDocumentOp extends CollectionOperationOp
    implements DocumentOperationOp {
  SaveDocumentOp(
    Collection collection,
    this.document, [
    this.concurrencyControl,
  ]) : super(collection, 'SaveDocument');

  /// The document to save.
  @override
  final Document document;

  /// The concurrency control to use.
  final ConcurrencyControl? concurrencyControl;

  /// Whether a conflict handler is used to resolve conflicts.
  ///
  /// When this is `false`, [concurrencyControl] is used to resolve conflicts
  /// instead.
  bool get withConflictHandler => concurrencyControl == null;
}

/// Operation that deletes a [Document] from a [Collection].
///
/// {@category Tracing}
class DeleteDocumentOp extends CollectionOperationOp
    implements DocumentOperationOp {
  DeleteDocumentOp(
    Collection collection,
    this.document,
    this.concurrencyControl,
  ) : super(collection, 'DeleteDocument');

  /// The document to delete.
  @override
  final Document document;

  /// The concurrency control to use.
  final ConcurrencyControl concurrencyControl;
}

/// Operation that involves a [Query].
///
/// {@category Tracing}
abstract class QueryOperationOp extends TracedOperation {
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

/// A function to filter [TracedOperation]s.
///
/// {@category Tracing}
typedef OperationFilter = bool Function(TracedOperation operation);

/// Returns a new [OperationFilter] that combines the provided filters through
/// an AND operation.
///
/// {@category Tracing}
OperationFilter combineOperationFilters(List<OperationFilter> filters) =>
    (operation) {
      for (final filter in filters) {
        if (!filter(operation)) {
          return false;
        }
      }
      return true;
    };

/// A function that returns a string representation for [TracedOperation]s.
///
/// {@category Tracing}
typedef OperationToStringResolver = String Function(TracedOperation operation);

/// A function that resolves detailed tracing information for
/// [TracedOperation]s.
///
/// {@category Tracing}
typedef OperationDetailsResolver = Map<String, Object?>? Function(
  TracedOperation operation,
);

/// A tracing delegate that integrates CBL Dart with the Dart DevTools.
///
/// This tracing delegate records [Timeline] events, which can be viewed in Dart
/// DevTools Performance Page.
///
/// {@category Tracing}
class DevToolsTracing extends TracingDelegate {
  /// A tracing delegate that integrates CBL Dart with the dart developer tools.
  ///
  /// [operationFilter] is a filter that is used to determine whether an
  /// operation should be traced. Per default, [defaultOperationFilter] is used.
  ///
  /// [operationNameResolver] is the function that is used to resolve the name
  /// of an operation. Per default, [defaultOperationNameResolver] is used.
  ///
  /// [operationDetailsResolver] is the function that is used to resolve
  /// detailed tracing information for an operation. Per default,
  /// [defaultOperationDetailsResolver] is used.
  DevToolsTracing({
    OperationFilter operationFilter = defaultOperationFilter,
    OperationToStringResolver operationNameResolver =
        defaultOperationNameResolver,
    OperationDetailsResolver operationDetailsResolver =
        defaultOperationDetailsResolver,
  })  : _operationFilter = combineOperationFilters([
          operationFilter,
          _nestedChannelCallsFilter,
        ]),
        _operationNameResolver = operationNameResolver,
        _operationDetailsResolver = operationDetailsResolver,
        _isWorkerDelegate = false;

  DevToolsTracing._workerDelegate(DevToolsTracing userDelegate)
      : _operationFilter = userDelegate._operationFilter,
        _operationNameResolver = userDelegate._operationNameResolver,
        _operationDetailsResolver = userDelegate._operationDetailsResolver,
        _isWorkerDelegate = true;

  /// The default filter that is used to determine whether an operation should
  /// be recorded to the timeline.
  ///
  /// It returns `true` for all operations.
  static bool defaultOperationFilter(TracedOperation operation) => true;

  static bool _nestedChannelCallsFilter(TracedOperation operation) {
    if (operation is ChannelCallOp && _currentCblTimelineTask == null) {
      // Only trace channel calls within an operation that is already being
      // traced.
      return false;
    }

    return true;
  }

  /// The default function to resolve the name of a [TracedOperation] for its
  /// timeline events.
  static String defaultOperationNameResolver(TracedOperation operation) {
    if (operation is ChannelCallOp) {
      return 'ChannelCall';
    }
    return operation.name;
  }

  /// The default function to resolve details of a [TracedOperation] for its
  /// timeline events.
  static Map<String, Object?>? defaultOperationDetailsResolver(
    TracedOperation operation,
  ) {
    final details = <String, Object?>{};

    if (operation is ChannelCallOp) {
      details['callType'] = operation.name;
      return details;
    }

    if (operation is OpenDatabaseOp) {
      final directory = operation.config?.directory;
      final withEncryptionKey = operation.config?.encryptionKey != null;

      details['databaseName'] = operation.databaseName;
      if (directory != null) {
        details['directory'] = directory;
      }
      details['withEncryptionKey'] = withEncryptionKey;

      return details;
    }

    if (operation is DatabaseOperationOp) {
      details['databaseName'] = operation.database.name;
    }

    if (operation is DocumentOperationOp) {
      details['documentId'] = operation.document.id;
    }

    if (operation is GetDocumentOp) {
      details['documentId'] = operation.id;
    }

    if (operation is SaveDocumentOp) {
      final concurrencyControl = operation.concurrencyControl;
      if (concurrencyControl != null) {
        details['concurrencyControl'] = concurrencyControl.name;
      } else {
        details['conflictHandler'] = true;
      }
    }

    if (operation is DeleteDocumentOp) {
      details['concurrencyControl'] = operation.concurrencyControl.name;
    }

    if (operation is QueryOperationOp) {
      details['query'] =
          operation.query.jsonRepresentation ?? operation.query.n1ql;
    }

    return details.isEmpty ? null : details;
  }

  final bool _isWorkerDelegate;
  final OperationFilter _operationFilter;
  final OperationToStringResolver _operationNameResolver;
  final OperationDetailsResolver _operationDetailsResolver;

  @override
  TracingDelegate createWorkerDelegate() =>
      DevToolsTracing._workerDelegate(this);

  @override
  T traceSyncOperation<T>(
    TracedOperation operation,
    T Function() execute,
  ) {
    if (!_operationFilter(operation)) {
      return execute();
    }

    final name = _operationNameResolver(operation);
    final details = _operationDetailsResolver(operation);
    final task = _provideTimelineTask();
    try {
      task?.start(name, arguments: details);
      return _withCblTimelineTask(
        task,
        () => Timeline.timeSync(name, execute, arguments: details),
      );
    } finally {
      task?.finish();
    }
  }

  @override
  Future<T> traceAsyncOperation<T>(
    TracedOperation operation,
    Future<T> Function() execute,
  ) async {
    if (!_operationFilter(operation)) {
      return execute();
    }

    final name = _operationNameResolver(operation);
    final details = _operationDetailsResolver(operation);
    final task = _provideTimelineTask();
    try {
      task?.start(name, arguments: details);
      return await _withCblTimelineTask(task, execute);
    } finally {
      task?.finish();
    }
  }

  TimelineTask? _provideTimelineTask() => _isWorkerDelegate
      ? null
      : TimelineTask(
          parent: _currentCblTimelineTask,
          filterKey: 'CouchbaseLite',
        );
}

T _withCblTimelineTask<T>(TimelineTask? task, T Function() fn) =>
    runZoned(fn, zoneValues: {#_cblTimelineTask: task});

TimelineTask? get _currentCblTimelineTask =>
    Zone.current[#_cblTimelineTask] as TimelineTask?;
