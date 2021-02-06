import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'bindings/bindings.dart';
import 'ffi_utils.dart';
import 'utils.dart';

/// Function which is given to callbacks to respond to caller with a result.
typedef CallbackResultHandler = void Function(dynamic response);

/// Function which invokes a [callback].
///
/// This function adapts the arguments from the native side for the Dart side
/// and vice versa the result from the Dart side for the native side.
///
/// It is called with the [arguments] from the native side and if the native
/// side requested a response, with a [result] handler.
typedef CallbackInvoker<T extends Function> = void Function(
  T callback,
  List arguments,
  CallbackResultHandler? result,
);

typedef _CallbackHandler = void Function(
  List arguments,
  CallbackResultHandler? result,
);

/// Register Dart functions as callbacks which can be called from the native
/// side.
class NativeCallbacks {
  static late final _bindings = CBLBindings.instance.nativeCallbacks;

  static late final instance = NativeCallbacks._();

  NativeCallbacks._() {
    final receivePort = ReceivePort();
    _receivePortSub = receivePort.cast<List>().listen(_messageHandler);
    _ref = _bindings.newCallbackIsolate(this, receivePort.sendPort.nativePort);
  }

  late StreamSubscription _receivePortSub;
  late Pointer<Void> _ref;

  final _callbacks = <int, Function>{};
  final _callbackHandlers = <int, _CallbackHandler>{};

  /// Register [callback] so that it can be called from the native side.
  ///
  /// The [invoker] translates between the native side and the Dart side.
  ///
  /// The returned number is an id for the callback which can be given to the
  /// native side.
  ///
  /// See:
  /// - [CallbackInvoker]
  int registerCallback<T extends Function>(
    T callback,
    CallbackInvoker<T> invoker,
  ) {
    assert(
      !_callbacks.containsValue(callback),
      'callback has already been registered',
    );

    final callbackId = _bindings.registerCallback(_ref);

    _callbacks[callbackId] = callback;
    _callbackHandlers[callbackId] = Zone.current.bindBinaryCallbackGuarded(
      (args, result) => invoker(callback, args, result),
    );

    return callbackId;
  }

  /// Remove a previously registered [callback].
  ///
  /// When a callback is installed on the native side, a finalizer can be
  /// registered to clean up native resources. If the Isolate which contained the
  /// callback dies while the callback is registered the finalizer will be run.
  ///
  /// By passing `true` to [runFinalizer], this finalizer can be run when
  /// calling this method.
  void unregisterCallback(Function callback, {bool runFinalizer = false}) {
    assert(
      _callbacks.containsValue(callback),
      'callback has not been registered',
    );

    final callbackId = _callbacks.entries
        .where((e) => e.value == callback)
        .map((e) => e.key)
        .first;

    _bindings.unregisterCallback(callbackId, runFinalizer.toInt);

    _callbacks.remove(callbackId);
    _callbackHandlers.remove(callbackId);
  }

  /// Frees up resources allocated for callbacks and infrastructure required
  /// for native callbacks.
  ///
  /// If [NativeCallbacks.instance] has been accessed the Isolate will not exit
  /// until this method has been called.
  Future<void> dispose() async {
    _callbacks.values.toList().forEach((callback) {
      unregisterCallback(callback, runFinalizer: true);
    });

    await _receivePortSub.cancel();
  }

  void _messageHandler(List message) {
    assert(message is List, 'callback call message must be a list');

    final callbackId = message[0] as int;
    final sendPort = message[1] as SendPort?;
    final callAddress = message[2] as int?;
    final args = message[3] as List;

    final callbackHandler = _callbackHandlers[callbackId];

    assert(
      callbackHandler != null,
      'could not find a registered callback to handle call',
    );

    CallbackResultHandler createResultHandler(
      SendPort sendPort,
      int callAddress,
    ) =>
        (dynamic result) => sendPort.send(<dynamic>[callAddress, result]);

    assert(
      (sendPort != null && callAddress != null) ||
          (sendPort == null && callAddress == null),
      'caller of callback must send a sendPort and callAddress to receive a '
      'result',
    );

    final resultHandler =
        sendPort?.let((it) => createResultHandler(it, callAddress!));

    callbackHandler!.call(args, resultHandler);
  }
}
