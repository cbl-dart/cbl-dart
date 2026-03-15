import 'dart:async';
import 'dart:isolate';

import '../bindings.dart';
import '../bindings/tracing.dart' show onTracedCall;
import 'errors.dart';
import 'tracing.dart';

class InitContext {
  InitContext({required this.filesDir, required this.tempDir});

  final String filesDir;
  final String tempDir;

  CBLInitContext toCbl() =>
      CBLInitContext(filesDir: filesDir, tempDir: tempDir);
}

class IsolateContext {
  IsolateContext({this.initContext});

  static IsolateContext? _instance;

  static bool get isInitialized => _instance != null;

  static set instance(IsolateContext value) {
    if (_instance != null) {
      throwAlreadyInitializedError();
    }
    _instance = value;
  }

  static IsolateContext get instance {
    final config = _instance;
    if (config == null) {
      throwNotInitializedError();
    }
    return config;
  }

  final InitContext? initContext;

  /// Returns a copy of this context that is safe to send to another isolate.
  IsolateContext forSecondaryIsolate() =>
      IsolateContext(initContext: initContext);
}

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native libraries.
Future<void> initPrimaryIsolate(IsolateContext context) async {
  _initIsolate(context);
  BaseBindings.initializeNativeLibraries(context.initContext?.toCbl());
  await _runPostIsolateInitTasks();
}

/// Initializes this isolate for use of Couchbase Lite, after another primary
/// isolate has been initialized.
Future<void> initSecondaryIsolate(IsolateContext context) async {
  _initIsolate(context);
  await _runPostIsolateInitTasks();
}

void _initIsolate(IsolateContext context) {
  IsolateContext.instance = context;
  onTracedCall = tracingDelegateTracedNativeCallHandler;
}

typedef PostIsolateInitTask = FutureOr<void> Function();

final _postIsolateInitTasks = <PostIsolateInitTask>[];
Future? _currentPostIsolateInitTask;

Future<void> addPostIsolateInitTask(PostIsolateInitTask task) async {
  if (IsolateContext.isInitialized) {
    await task();
  } else {
    _postIsolateInitTasks.add(task);
  }
}

Future<void> removePostIsolateInitTask(PostIsolateInitTask task) async {
  if (_postIsolateInitTasks.isNotEmpty) {
    if (_currentPostIsolateInitTask != null &&
        _postIsolateInitTasks[0] == task) {
      await _currentPostIsolateInitTask;
    } else {
      _postIsolateInitTasks.remove(task);
    }
  }
}

Future<void> _runPostIsolateInitTasks() async {
  while (_postIsolateInitTasks.isNotEmpty) {
    final task = _postIsolateInitTasks[0];
    await (_currentPostIsolateInitTask = Future<void>.sync(task));
    _currentPostIsolateInitTask = null;
    _postIsolateInitTasks.removeAt(0);
  }
}

Future<T> runInSecondaryIsolate<T>(FutureOr<T> Function() fn) {
  final context = IsolateContext.instance.forSecondaryIsolate();
  return Isolate.run(() async {
    await initSecondaryIsolate(context);
    return fn();
  });
}
