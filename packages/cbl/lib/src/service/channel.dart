// ignore_for_file: prefer_constructors_over_static_methods, avoid_print

import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'package:stream_channel/stream_channel.dart';

import '../support/tracing.dart';
import '../tracing.dart';

/// A type which is aware of being sent between isolates.
abstract interface class SendAware {
  /// Allow subclasses to have const constructors.
  const SendAware();

  /// Called before this object is sent through a [SendPort].
  ///
  /// This allows an object to make itself sendable by replacing references to
  /// objects that are not sendable, e.g. [Pointer], with sendable ones. The
  /// received copy will have [didReceive] called on it, where it should restore
  /// itself to the state of the original before [willSend] was called on it.
  ///
  /// If this object contains other [SendAware]s, it must call [willSend] on
  /// them from this method.
  void willSend() {}

  /// Called after this object has been received from a [ReceivePort].
  ///
  /// See [willSend] for more information.
  ///
  /// If this object contains other [SendAware]s, it must call [didReceive] on
  /// them from this method.
  void didReceive() {}
}

/// Interface that request objects for [Channel] endpoints have to implement.
///
/// [Response] is the type of the type of the result of a call or the events of
/// a stream initiated with such a request.
abstract base class Request<Response> {}

/// Handler which responds to requests to a call endpoint of a [Channel].
typedef CallHandler<T extends Request<R>, R> = FutureOr<R> Function(T);

/// Handler which responds to requests to a stream endpoint of a [Channel].
typedef StreamHandler<T extends Request<R>, R> = Stream<R> Function(T);

/// Captures the context for a channel message before it is sent.
///
/// The returned value is passed to a [MessageContextRestorer] after the message
/// has been received by the other end of the channel.
///
/// Typically, the context is stored in a zone value.
///
/// The returned value must be JSON serializable.
typedef MessageContextCapturer = Object? Function();

/// Restores the context for a channel message after it has been received.
///
/// The provided [context] is the value captured by a [MessageContextCapturer]
/// before the message was sent.
///
/// A context restorer must call [restore] before it returns and exactly once.
///
/// Typically, the context is restored by setting a zone value.
typedef MessageContextRestorer =
    void Function(Object? context, void Function() restore);

/// Returns the remote [StackTrace] for an exception that was emitted by a
/// [Channel].
///
/// When a channel emits an exception, it has the stack trace of the point where
/// the channel was used. This function returns the stack trace of the exception
/// when it was thrown on the other end of the channel.
StackTrace? remoteStackTrace(Object exception) {
  if (!_isValidExpandoKey(exception)) {
    return null;
  }
  return _remoteStackTraceExpando[exception];
}

final _remoteStackTraceExpando = Expando<StackTrace>();

/// The status of a [Channel].
enum ChannelStatus { initial, open, closing, closed }

/// Exception that pending calls or streams are complete with when a [Channel]
/// is closed.
final class ChannelClosedException implements Exception {}

typedef _UntypedCallHandler = FutureOr<Object?> Function(Object?);
typedef _UntypedStreamHandler = Stream<Object?> Function(Object?);

/// A bidirectional communication channel, supporting calls (one response) and
/// streams (zero or more responses).
///
/// Handlers for incoming requests are registered under named endpoints. Both
/// sides of the channel (each represented by one instance of [Channel]) can
/// setup endpoints at any point, while the channel has not been [close]ed.
///
/// The methods [call] and [stream] both take the name of an endpoint at the
/// other side of the channel and a request object for the endpoint handler. The
/// request object has to be of a type which extends [Request]. The type
/// argument of [Request] is the type of the result of a call or the events of a
/// stream initiated with such a request.
///
/// See also:
///
/// - [open] for controlling when a [Channel] starts to respond to requests.
final class Channel {
  /// Creates a new [Channel] with the given [transport].
  Channel({
    required StreamChannel<Object?> transport,
    bool autoOpen = true,
    MessageContextCapturer? captureMessageContext,
    MessageContextRestorer? restoreMessageContext,
    this.debug = false,
  }) : _transport = transport.cast<_Message>(),
       _captureMessageContext = captureMessageContext ?? (() => null),
       _restoreMessageContext = restoreMessageContext ?? ((_, f) => f()) {
    if (autoOpen) {
      open();
    }
  }

  final bool debug;

  final StreamChannel<_Message> _transport;
  final MessageContextCapturer _captureMessageContext;
  final MessageContextRestorer _restoreMessageContext;

  int _nextConversationId = 0;

  var _status = ChannelStatus.initial;
  ChannelStatus get status => _status;

  final _callHandlers = HashMap<Type, _UntypedCallHandler>.identity();
  final _callCompleter = HashMap<int, Completer<_Message>>();
  final _callRequestNames = HashMap<int, String>();

  final _streamHandlers = HashMap<Type, _UntypedStreamHandler>.identity();
  final _streamControllers = HashMap<int, StreamController<_Message>>();
  final _streamSubscriptions = HashMap<int, StreamSubscription>();

  /// Makes a call to an endpoint at other side of the channel.
  Future<R> call<R>(Request<R> request) async {
    late final requestName = request.runtimeType.toString();

    return asyncOperationTracePoint(() => ChannelCallOp(requestName), () async {
      _checkIsOpen();
      final id = _generateConversationId();
      _callRequestNames[id] = requestName;
      final completer = _callCompleter[id] = Completer<_Message>();
      _sendMessage(_CallRequest(id, request, _captureMessageContext()));

      final message = await completer.future;
      if (message is _CallSuccess) {
        return message.data as R;
      }
      if (message is _CallError) {
        // ignore: only_throw_errors
        throw message.error;
      }

      throw StateError('Unexpected message: $message');
    });
  }

  /// Returns a stream for an endpoint at the other side of the channel.
  Stream<R> stream<R>(Request<R> request) {
    _checkIsOpen();
    final id = _generateConversationId();
    // ignore: close_sinks
    late StreamController<_Message> controller;
    controller = StreamController<_Message>(
      onListen: () {
        _streamControllers[id] = controller;
        _sendMessage(_ListenToStream(id, request, _captureMessageContext()));
      },
      onPause: () => _sendMessage(_PauseStream(id, _captureMessageContext())),
      onResume: () => _sendMessage(_ResumeStream(id, _captureMessageContext())),
      onCancel: () {
        _streamControllers.remove(id);
        _sendMessage(_CancelStream(id, _captureMessageContext()));
      },
    );

    return controller.stream.map((message) {
      if (message is _StreamData) {
        return message.data as R;
      }
      if (message is _StreamError) {
        // ignore: only_throw_errors
        throw message.error;
      }

      throw StateError('Unexpected message: $message');
    });
  }

  /// Adds a call endpoint to this side of the channel.
  void addCallEndpoint<T extends Request<R>, R>(CallHandler<T, R> handler) {
    _checkStatusIsNot(ChannelStatus.closed);
    assert(!_callHandlers.containsKey(T), 'call endpoint already added: $T');
    _callHandlers[T] = (request) => handler(_checkType(request));
  }

  /// Adds a stream endpoint to this side of the channel.
  void addStreamEndpoint<T extends Request<R>, R>(StreamHandler<T, R> handler) {
    _checkStatusIsNot(ChannelStatus.closed);
    assert(
      !_streamHandlers.containsKey(T),
      'stream endpoint already added: $T',
    );
    _streamHandlers[T] = (request) => handler(_checkType(request));
  }

  /// Removes a call endpoint from this side of the channel.
  void removeCallEndpoint(Type requestType) {
    assert(
      _callHandlers.containsKey(requestType),
      'call endpoint does not exist: $requestType',
    );
    _callHandlers.remove(requestType);
  }

  /// Removes a stream endpoint from this side of the channel.
  void removeStreamEndpoint(Type requestType) {
    assert(
      _streamHandlers.containsKey(requestType),
      'stream endpoint does not exist: $requestType',
    );
    _streamHandlers.remove(requestType);
  }

  /// Opens this side of the channel.
  ///
  /// By default a [Channel] is opened when it is created. Setting `autoOpen` to
  /// `false` disables this behavior and the [Channel] must then be opened
  /// manually. This is useful if the other side of the channel is already
  /// making requests and the endpoints for those requests need to be added
  /// before opening the [Channel]. This is only necessary if the endpoints are
  /// added asynchronously after the channel has been created.
  void open() {
    _checkStatusIs(ChannelStatus.initial);
    _status = ChannelStatus.open;

    _transport.stream.listen((message) {
      if (_status != ChannelStatus.open) {
        // The channel is closing and does not accept new requests.
        return;
      }

      message.didReceive();

      _restoreMessageContext(message.context, () {
        // Associate the remote stack trace with the returned error.
        // This can only be done for error that are not of a primitive type,
        // which should be the case usually.
        if (message is _ErrorMessage) {
          final error = message.error;
          if (_isValidExpandoKey(error)) {
            final stackTrace = message.stackTrace;
            if (stackTrace != null) {
              _remoteStackTraceExpando[error] = stackTrace;
            }
          }
        }

        // Handle the message.
        if (message is _CallRequest) {
          _handleCallRequest(message);
        } else if (message is _CallSuccess || message is _CallError) {
          _handleCallResponse(message);
        } else if (message is _ListenToStream) {
          _handleListenToStream(message);
        } else if (message is _PauseStream) {
          _handlePauseStream(message);
        } else if (message is _ResumeStream) {
          _handleResumeStream(message);
        } else if (message is _CancelStream) {
          _handleCancelStream(message);
        } else if (message is _StreamData || message is _StreamError) {
          _handleStreamEvent(message);
        } else if (message is _StreamDone) {
          _handleStreamDone(message);
        }
      });
    });
  }

  /// Closes this side of the channel.
  ///
  /// This stops this [Channel] from responding to requests from the other side.
  /// Call responses which are attempted to be sent after this point are dropped
  /// and open streams are closed.
  ///
  /// If there are pending calls or open streams, which originated from this
  /// side, and [error] is not provided, the calls and streams are completed
  /// with a [ChannelClosedException]
  Future<void> close([Object? error, StackTrace? stackTrace]) async {
    _checkIsOpen();

    if (error == null && stackTrace != null) {
      throw ArgumentError.value(
        stackTrace,
        'stackTrace',
        'must not be provided without an error',
      );
    }

    if (error == null) {
      error = ChannelClosedException();
      stackTrace = StackTrace.current;
    }

    // No new requests are accepted after this point.
    _status = ChannelStatus.closing;

    // End open streams listening from the other side.
    for (final entry in _streamSubscriptions.entries) {
      final id = entry.key;
      final sub = entry.value;
      await sub.cancel();
      _sendStreamDone(id);
    }
    _streamSubscriptions.clear();

    // No responses will be sent after this point.
    _status = ChannelStatus.closed;

    // Close the transport.
    await _transport.sink.close();

    _callHandlers.clear();
    _streamHandlers.clear();

    // Complete pending calls from this side.
    for (final completer in _callCompleter.values) {
      completer.completeError(error, stackTrace);
    }
    _callCompleter.clear();

    // Close streams listening from this side.
    for (final controllers in _streamControllers.values) {
      controllers.addError(error, stackTrace);
      await controllers.close();
    }
    _streamControllers.clear();
  }

  // === Message handling ======================================================

  void _handleCallRequest(_CallRequest message) {
    final handler = _getCallHandler(message);
    if (handler == null) {
      return;
    }

    Future.sync(() => handler(message.request)).then(
      (result) => _sendCallSuccess(message.conversationId, result),
      // ignore: avoid_types_on_closure_parameters
      onError: (Object error, StackTrace stackTrace) =>
          _sendCallError(message.conversationId, error, stackTrace),
    );
  }

  void _handleCallResponse(_Message message) =>
      _takeCallCompleter(message)?.complete(message);

  void _handleListenToStream(_ListenToStream message) {
    final handler = _getStreamHandler(message);
    if (handler == null) {
      return;
    }

    _streamSubscriptions[message.conversationId] =
        Future.sync(() => handler(message.request))
            .asStream()
            .asyncExpand((stream) => stream)
            .listen(
              (event) {
                _sendStreamData(message.conversationId, event);
              },
              // ignore: avoid_types_on_closure_parameters
              onError: (Object error, StackTrace stackTrace) =>
                  _sendStreamError(message.conversationId, error, stackTrace),
              onDone: () => _sendStreamDone(message.conversationId),
            );
  }

  void _handlePauseStream(_PauseStream message) =>
      _getStreamSubscription(message)?.pause();

  void _handleResumeStream(_ResumeStream message) =>
      _getStreamSubscription(message)?.resume();

  void _handleCancelStream(_CancelStream message) =>
      _takeStreamSubscription(message)?.cancel();

  void _handleStreamEvent(_Message message) =>
      _getStreamController(message)?.add(message);

  void _handleStreamDone(_StreamDone message) {
    _getStreamController(message)?.close();
    _streamControllers.remove(message.conversationId);
  }

  // === Message handling utils ================================================

  _UntypedCallHandler? _getCallHandler(_RequestMessage message) {
    final handler = _callHandlers[message.request.runtimeType];
    if (handler == null) {
      _sendCallError(
        message.conversationId,
        UnimplementedError(
          'No call handler registered for endpoint: '
          '${message.request.runtimeType}',
        ),
        StackTrace.current,
      );
      return null;
    }
    return handler;
  }

  _UntypedStreamHandler? _getStreamHandler(_RequestMessage message) {
    final handler = _streamHandlers[message.request.runtimeType];
    if (handler == null) {
      _sendStreamError(
        message.conversationId,
        UnimplementedError(
          'No stream handler registered for endpoint: '
          '${message.request.runtimeType}',
        ),
        StackTrace.current,
      );
      _sendStreamDone(message.conversationId);
      return null;
    }
    return handler;
  }

  Completer<Object?>? _takeCallCompleter(_Message message) {
    _callRequestNames.remove(message.conversationId);
    final completer = _callCompleter.remove(message.conversationId);
    assert(
      completer != null,
      'no completer for call #${message.conversationId}',
    );
    return completer;
  }

  StreamController<Object?>? _getStreamController(_Message message) =>
      // It's possible that an event is received after the stream has been
      // canceled and the `_CancelStream` message has been sent. In this case
      // the event is ignored.
      _streamControllers[message.conversationId];

  StreamSubscription? _getStreamSubscription(_Message message) =>
      // It's possible that a stream never created a subscription, for example
      // when the request could not be deserialized. In those cases the
      // event is ignored.
      _streamSubscriptions[message.conversationId];

  StreamSubscription? _takeStreamSubscription(_Message message) =>
      // It's possible that a stream never created a subscription, for example
      // when the request could not be deserialized. In those cases the
      // `_CancelStream` is ignored.
      _streamSubscriptions.remove(message.conversationId);

  // === Message sending =======================================================

  void _sendMessage(_Message message) {
    if (_status == ChannelStatus.closed) {
      // If the channel has been closed, messages to the other side are dropped.
      return;
    }

    if (debug) {
      if (message is _CallRequest) {
        print('-> ${message.request.runtimeType}');
      } else if (message is _CallSuccess) {
        print('<- ${message.data?.runtimeType}');
      } else if (message is _CallError) {
        print('!- ${message.error}');
      } else if (message is _ListenToStream) {
        print('=> ${message.request.runtimeType}');
      } else if (message is _CancelStream) {
        print('=|');
      } else if (message is _StreamData) {
        print('=> ${message.data?.runtimeType}');
      } else if (message is _StreamDone) {
        print('|=');
      } else if (message is _StreamError) {
        print('=!  ${message.error}');
      }
    }

    message.willSend();

    _transport.sink.add(message);
  }

  void _sendCallSuccess(int conversationId, Object? data) => _sendMessage(
    _CallSuccess(conversationId, data, _captureMessageContext()),
  );

  void _sendCallError(
    int conversationId,
    Object error,
    StackTrace stackTrace,
  ) => _sendMessage(
    _CallError(conversationId, error, stackTrace, _captureMessageContext()),
  );

  void _sendStreamData(int conversationId, Object? data) =>
      _sendMessage(_StreamData(conversationId, data, _captureMessageContext()));

  void _sendStreamError(
    int conversationId,
    Object error,
    StackTrace stackTrace,
  ) => _sendMessage(
    _StreamError(conversationId, error, stackTrace, _captureMessageContext()),
  );

  void _sendStreamDone(int conversationId) =>
      _sendMessage(_StreamDone(conversationId, _captureMessageContext()));

  // === Misc ==================================================================

  int _generateConversationId() => _nextConversationId++;

  void _checkStatusIs(ChannelStatus status) {
    if (_status != status) {
      throw StateError(
        'Expected Channel to be ${status.name} but it was ${_status.name}.',
      );
    }
  }

  void _checkStatusIsNot(ChannelStatus status) {
    if (_status == status) {
      throw StateError('Expected Channel not to be ${status.name} but it was.');
    }
  }

  void _checkIsOpen() => _checkStatusIs(ChannelStatus.open);

  T _checkType<T>(Object? value) {
    if (value is! T) {
      throw ArgumentError.value(value, 'value', 'expected type $T');
    }
    return value;
  }
}

// === Messages ===========================================

abstract final class _Message extends SendAware {
  _Message(this.conversationId, this.context);

  final int conversationId;
  final Object? context;
}

abstract final class _RequestMessage extends _Message {
  _RequestMessage(int conversationId, this.request, Object? context)
    : super(conversationId, context);

  final Request request;

  @override
  void willSend() {
    if (request case final SendAware sendAware) {
      sendAware.willSend();
    }
  }

  @override
  void didReceive() {
    if (request case final SendAware sendAware) {
      sendAware.didReceive();
    }
  }
}

abstract final class _SuccessMessage extends _Message {
  _SuccessMessage(int conversationId, this.data, Object? context)
    : super(conversationId, context);

  final Object? data;

  @override
  void willSend() {
    if (data case final SendAware sendAware) {
      sendAware.willSend();
    }
  }

  @override
  void didReceive() {
    if (data case final SendAware sendAware) {
      sendAware.didReceive();
    }
  }
}

abstract final class _ErrorMessage extends _Message {
  _ErrorMessage(
    int conversationId,
    this.error,
    this.stackTrace,
    Object? context,
  ) : super(conversationId, context);

  final Object error;
  final StackTrace? stackTrace;

  @override
  void willSend() {
    if (error case final SendAware sendAware) {
      sendAware.willSend();
    }
  }

  @override
  void didReceive() {
    if (error case final SendAware sendAware) {
      sendAware.didReceive();
    }
  }
}

final class _CallRequest extends _RequestMessage {
  _CallRequest(super.conversationId, super.request, super.context);
}

final class _CallSuccess extends _SuccessMessage {
  _CallSuccess(super.conversationId, super.data, super.context);
}

final class _CallError extends _ErrorMessage {
  _CallError(
    super.conversationId,
    super.error,
    super.stackTrace,
    super.context,
  );
}

final class _ListenToStream extends _RequestMessage {
  _ListenToStream(super.conversationId, super.request, super.context);
}

final class _PauseStream extends _Message {
  _PauseStream(super.conversationId, super.context);
}

final class _ResumeStream extends _Message {
  _ResumeStream(super.conversationId, super.context);
}

final class _CancelStream extends _Message {
  _CancelStream(super.conversationId, super.context);
}

final class _StreamData extends _SuccessMessage {
  _StreamData(super.conversationId, super.data, super.context);
}

final class _StreamError extends _ErrorMessage {
  _StreamError(
    super.conversationId,
    super.error,
    super.stackTrace,
    super.context,
  );
}

final class _StreamDone extends _Message {
  _StreamDone(super.conversationId, super.context);
}

bool _isValidExpandoKey(Object? value) {
  // `dart:ffi` values are not allowed as expando keys, too, but they cannot
  // be sent over a channel anyway.
  if (value == null || value is String || value is num || value is bool) {
    return false;
  }

  return true;
}
