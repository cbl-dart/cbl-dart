import 'dart:ffi';
import 'dart:isolate';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'native_object.dart';
import 'utils.dart';

/// Function which is given to callbacks to respond to caller with a result.
typedef CallbackResultHandler = void Function(dynamic response);

/// Handler which is invoked to respond to a [NativeCallback].
///
/// The handler receives a list of [arguments] from native side.
///
/// If the natives side expects a response [result] is not `null`, and must
/// be called to unblock the native side.
typedef CallbackHandler = void Function(
  List arguments,
  CallbackResultHandler? result,
);

late final _bindings = CBLBindings.instance.nativeCallback;

/// A callback which can be called from the native side.
///
/// [NativeCallback]s have to be [close]d to free allocated resources on the
/// native side and close its [ReceivePort]. The isolate will not exist, as
/// long as there is an open [ReceivePort].
class NativeCallback {
  /// Creates a callback which can be called from the native side.
  ///
  /// [handler] is the function which responds to calls from the native side.
  NativeCallback(this.handler) {
    _receivePort = ReceivePort();

    native = NativeObject(_bindings.makeNew(
      this,
      _receivePort.sendPort.nativePort,
    ));

    _receivePort.cast<List>().listen(_messageHandler);
  }

  /// The handler which responds to calls to this callback.
  final CallbackHandler handler;

  late final ReceivePort _receivePort;

  late final NativeObject<Callback> native;

  /// Close this callback to free resources on the native side and the
  /// Dart side.
  ///
  /// After calling this method the callback must not be used any more.
  void close() {
    _bindings.close(native.pointerUnsafe);
    _receivePort.close();
  }

  void _messageHandler(List message) {
    assert(message is List, 'callback call message must be a list');

    final sendPort = message[0] as SendPort?;
    final callAddress = message[1] as int?;
    final args = message[2] as List;

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

    handler.call(args, resultHandler);
  }
}
