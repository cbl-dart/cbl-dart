import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'ffi.dart';

typedef DartFinalizer = void Function();

final dartFinalizerRegistry = DartFinalizerRegistry._();

class DartFinalizerRegistry {
  DartFinalizerRegistry._();

  int _nextToken = 0;
  final _finalizers = HashMap<int, DartFinalizer>();
  ReceivePort? _receivePort;
  int? _sendPort;

  Object registerFinalizer(Object object, DartFinalizer finalizer) {
    _openPortIfNecessary();
    final token = _nextToken++;
    _finalizers[token] = finalizer;
    cblBindings.dartFinalizer.registerDartFinalizer(object, _sendPort!, token);
    return token;
  }

  void unregisterFinalizer(Object token, {bool callFinalizer = false}) {
    if (token is! int) {
      throw ArgumentError('Did not provide a valid token.');
    }

    final finalizer = _finalizers.remove(token);
    if (finalizer != null) {
      if (callFinalizer) {
        finalizer();
      }
      _cleanUpPortIfNecessary();
    }
  }

  void _openPortIfNecessary() {
    if (_receivePort != null) {
      return;
    }

    _receivePort = ReceivePort()
      // ignore: avoid_types_on_closure_parameters
      ..listen((Object? token) {
        final finalizer = _finalizers.remove(token! as int);
        if (finalizer != null) {
          finalizer();
          _cleanUpPortIfNecessary();
        }
      });
    _sendPort = _receivePort!.sendPort.nativePort;
  }

  void _cleanUpPortIfNecessary() {
    if (_finalizers.isNotEmpty) {
      return;
    }

    // Close the port since all finalizer have been run. The port should not
    // be left dangling and keep the isolate alive infinitely.
    _receivePort!.close();
    _receivePort = null;
    _sendPort = null;
  }
}
