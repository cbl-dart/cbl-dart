import 'dart:async';
import 'dart:isolate';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'native_object.dart';

/// Handler which is invoked to respond to a [NativeCallback].
///
/// The handler receives a list of [arguments] from native side.
typedef CallbackHandler = FutureOr<Object?> Function(List arguments);

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

    native = NativeObject(_bindings.create(
      this,
      _receivePort.sendPort,
    ));

    _receivePort.cast<List>().listen(_messageHandler);
  }

  /// The handler which responds to calls to this callback.
  final CallbackHandler handler;

  late final ReceivePort _receivePort;

  late final NativeObject<Callback> native;

  var _closed = false;

  /// Close this callback to free resources on the native side and the
  /// Dart side.
  ///
  /// After calling this method the callback must not be used any more.
  void close() {
    _closed = true;
    _bindings.close(native.pointerUnsafe);
    _receivePort.close();
  }

  void _messageHandler(List message) {
    assert(message is List, 'callback call message must be a list');

    final sendPort = message[0] as SendPort?;
    final callAddress = message[1] as int?;
    final args = message[2] as List;

    assert(
      (sendPort != null && callAddress != null) ||
          (sendPort == null && callAddress == null),
      'caller of callback must send a sendPort and callAddress to receive a '
      'result',
    );
    ;

    Future.value(handler(args)).then((result) {
      assert(result == null || sendPort != null);
      if (!_closed && sendPort != null) {
        sendPort.send([callAddress, result]);
      }
    });
  }
}
