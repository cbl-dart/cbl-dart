import 'dart:async';
import 'dart:isolate';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'native_object.dart';

/// Handler which is invoked to respond to a [NativeCallback].
///
/// The handler receives a list of [arguments] from native side.
typedef CallbackHandler = FutureOr<Object?> Function(List arguments);

late final _bindings = CBLBindings.instance.nativeCallback;

var _nextId = 0;
int _generateId() {
  final id = _nextId;
  _nextId += 1;
  return id;
}

/// A callback which can be called from the native side.
///
/// [NativeCallback]s have to be [close]d to free allocated resources on the
/// native side and close its [ReceivePort]. The isolate will not exist, as
/// long as there is an open [ReceivePort].
class NativeCallback {
  /// Creates a callback which can be called from the native side.
  ///
  /// [handler] is the function which responds to calls from the native side.
  NativeCallback(
    this.handler, {
    this.errorResult = failureResult,
    required this.debugName,
    this.debug = false,
  }) {
    _receivePort = ReceivePort();

    native = NativeObject(_bindings.create(
      _id,
      this,
      _receivePort.sendPort,
      debug,
    ));

    _receivePort.cast<List<Object?>>().listen(_messageHandler);

    _debugLog('created ($debugName)');
  }

  /// A special result which signals the native side to throw a C++
  /// `std::runtime_exception`.
  static const failureResult = '__NATIVE_CALLBACK_FAILED__';

  final _id = _generateId();

  /// The handler which responds to calls to this callback.
  final CallbackHandler handler;

  /// The result to send to the native side when [handler] throws an exception.
  ///
  /// The default is to send [failureResult], which is a special value which
  /// signals the native side to throw a C++ `std::runtime_exception`.
  final Object? errorResult;

  /// A debug description of this callback.
  final String debugName;

  /// Whether to print debug information for this callback.
  ///
  /// This feature is only functional in debug mode.
  final bool debug;

  /// A [Stream] of the errors thrown by [handler].
  ///
  /// The stream supports a single subscriber.
  Stream<void> get errors => _errorStreamController.stream;

  late final ReceivePort _receivePort;

  late final NativeObject<Callback> native;

  late final _errorStreamController = StreamController<Object?>();

  var _closed = false;

  /// Close this callback to free resources on the native side and the
  /// Dart side.
  ///
  /// After calling this method the callback must not be used any more.
  void close() {
    _debugLog('closing');
    _closed = true;
    native.keepAlive(_bindings.close);
    _receivePort.close();
    _errorStreamController.close();
  }

  void _messageHandler(List<Object?> message) {
    assert(message is List, 'callback call message must be a list');

    final sendPort = message[0] as SendPort?;
    final callAddress = message[1] as int?;
    final args = message[2] as List<Object?>;

    String debugFormatArgs() => args.map((arg) {
          if (arg is! Iterable<Object?>) {
            return arg;
          }

          final list = arg.toList();
          if (list.length > 3) {
            return [...list.take(3), '...'];
          }
          return list;
        }).join(', ');

    _debugLog('received call: ${debugFormatArgs()}');

    final isBlocking = sendPort != null;

    assert(
      (sendPort != null && callAddress != null) ||
          (sendPort == null && callAddress == null),
      'CBLDart::CallbackCall must send both a sendPort and '
      'a callAddress or none',
    );

    void sendResult(Object? result) {
      if (!isBlocking) {
        _debugLog('not sending result because call is not blocking');
        return;
      }

      if (_closed) {
        _debugLog('not sending result because call is not closed');
        return;
      }

      if (debug) {
        _debugLog('sending result: $result');
      }

      sendPort!.send([callAddress, result]);
    }

    Future(() => handler(args)).then(
      (result) {
        assert(result == null || sendPort != null);
        sendResult(result);
      },
      onError: (Object error, StackTrace stackTrace) {
        sendResult(errorResult);
        _errorStreamController.addError(error, stackTrace);
      },
    );
  }

  @pragma('vm:prefer-inline')
  // When inlined in release mode, it is as if this function did not exist at
  // the call site.
  void _debugLog(String message) {
    assert(() {
      if (debug) {
        print('NativeCallback #$_id -> $message');
      }
      return true;
    }());
  }
}
