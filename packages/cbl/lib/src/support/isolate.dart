import 'dart:async';

import '../bindings.dart';
import '../bindings/tracing.dart';
import '../document/common.dart';
import '../fleece/integration/integration.dart';
import 'errors.dart';
import 'tracing.dart';

const _baseBindings = BaseBindings();

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
}

/// Initializes this isolate for use of Couchbase Lite, and initializes the
/// native libraries.
Future<void> initPrimaryIsolate(IsolateContext context) async {
  await _initIsolate(context);
  runWithErrorTranslation(() {
    _baseBindings.initializeNativeLibraries(context.initContext?.toCbl());
  });
  await _runPostIsolateInitTasks();
}

/// Initializes this isolate for use of Couchbase Lite, after another primary
/// isolate has been initialized.
Future<void> initSecondaryIsolate(IsolateContext context) async {
  await _initIsolate(context);
  await _runPostIsolateInitTasks();
}

Future<void> _initIsolate(IsolateContext context) async {
  IsolateContext.instance = context;
  onTracedCall = tracingDelegateTracedNativeCallHandler;
  MDelegate.instance = CblMDelegate();
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
