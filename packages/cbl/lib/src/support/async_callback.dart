import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import '../bindings.dart';
import 'ffi.dart';

/// Handler which is invoked to respond to a [AsyncCallback].
///
/// The handler receives a list of [arguments] from native side.
typedef AsyncCallbackHandler = FutureOr<Object?> Function(
  List<Object?> arguments,
);

final _bindings = cblBindings.asyncCallback;

var _nextId = 0;
int _generateId() => _nextId++;

/// A callback which can be asynchronously called from the native side.
///
/// [AsyncCallback]s have to be [close]d to free allocated resources on the
/// native side and close its [ReceivePort]. The isolate will not exist, as long
/// as there is an open [ReceivePort].
class AsyncCallback implements Finalizable {
  /// Creates a callback which can be asynchronously called from the native
  /// side.
  ///
  /// [handler] is the function which responds to calls from the native side.
  AsyncCallback(
    this.handler, {
    this.errorResult = failureResult,
    this.ignoreErrorsInDart = false,
    required this.debugName,
    this.debug = false,
  }) {
    _receivePort = ReceivePort();

    pointer = _bindings.create(
      _id,
      this,
      _receivePort.sendPort,
      debug: debug,
    );

    _receivePort.cast<List<Object?>>().listen(_messageHandler);

    _debugLog('created ($debugName)');
  }

  /// A special result which signals the native side to throw a C++
  /// `std::runtime_exception`.
  static const failureResult = '__ASYNC_CALLBACK_FAILED__';

  final _id = _generateId();

  late final Pointer<CBLDartAsyncCallback> pointer;

  /// The handler which responds to calls to this callback.
  final AsyncCallbackHandler handler;

  /// The result to send to the native side when [handler] throws an exception.
  ///
  /// The default is to send [failureResult], which is a special value which
  /// signals the native side to throw a C++ `std::runtime_exception`.
  final Object? errorResult;

  /// If `true` errors thrown by [handler] are ignored. Otherwise they are
  /// treated as unhandled errors in the [Zone] in which the [AsyncCallback] was
  /// created.
  final bool ignoreErrorsInDart;

  /// A debug description of this callback.
  final String debugName;

  /// Whether to print debug information for this callback.
  ///
  /// This feature is only functional in debug mode.
  final bool debug;

  late final ReceivePort _receivePort;

  var _closed = false;

  /// Close this callback to free resources on the native side and the Dart
  /// side.
  ///
  /// After calling this method the callback must not be used any more.
  void close() {
    if (_closed) {
      return;
    }
    _debugLog('closing');
    _closed = true;
    _bindings.close(pointer);
    _receivePort.close();
  }

  void _messageHandler(List<Object?> message) {
    final sendPort = message[0] as SendPort?;
    final callAddress = message[1] as int?;
    // ignore: cast_nullable_to_non_nullable
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
      'CBLDart::AsyncCallbackCall must send both a sendPort and '
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

      sendPort.send([callAddress, result]);
    }

    Future.sync(() async {
      try {
        final result = await handler(args);
        assert(result == null || sendPort != null);
        sendResult(result);
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        sendResult(errorResult);
        if (!ignoreErrorsInDart) {
          rethrow;
        }
      }
    });
  }

  @pragma('vm:prefer-inline')
  // When inlined in release mode, it is as if this function did not exist at
  // the call site.
  void _debugLog(String message) {
    assert(() {
      if (debug) {
        // ignore: avoid_print
        print('AsyncCallback #$_id (dart)   -> $message');
      }
      return true;
    }());
  }
}
