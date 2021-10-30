// ignore_for_file: prefer_constructors_over_static_methods, avoid_print

import 'dart:async';

import 'package:stream_channel/stream_channel.dart';

import '../support/utils.dart';
import 'serialization/serialization.dart';
import 'serialization/serialization_codec.dart';

/// Interface that request objects for [Channel] endpoints have to implement.
///
/// [Response] is the type of the type of the result of a call or the events
/// of a stream initiated with such a request.
abstract class Request<Response> extends Serializable {}

/// Handler which responds to requests to a call endpoint of a [Channel].
typedef CallHandler<T extends Request<R>, R> = FutureOr<R> Function(T);

/// Handler which responds to requests to a stream endpoint of a [Channel].
typedef StreamHandler<T extends Request<R>, R> = Stream<R> Function(T);

/// The status of a [Channel].
enum ChannelStatus {
  initial,
  open,
  closing,
  closed,
}

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
/// argument of [Request] is the type of the result of a call or the events
/// of a stream initiated with such a request.
///
/// See also:
///
///  * [open] for controlling when a [Channel] starts to respond to requests.
class Channel {
  /// Creates a new [Channel] with the given [transport] and [packetCodec].
  Channel({
    required StreamChannel<Object?> transport,
    PacketCodec? packetCodec,
    SerializationRegistry? serializationRegistry,
    bool autoOpen = true,
    this.debug = false,
  }) {
    serializationRegistry =
        serializationRegistry?.merge(channelSerializationRegistry()) ??
            channelSerializationRegistry();

    final codec =
        SerializationCodec(serializationRegistry, packetCodec: packetCodec);

    _transport = transport
        .transform(StreamChannelTransformer.fromCodec(codec))
        .cast<_Message>();

    if (autoOpen) {
      open();
    }
  }

  final bool debug;

  late final StreamChannel<_Message> _transport;
  int _nextConversationId = 0;

  var _status = ChannelStatus.initial;
  ChannelStatus get status => _status;

  final _callHandlers = <Type, _UntypedCallHandler>{};
  final _callCompleter = <int, Completer>{};

  final _streamHandlers = <Type, _UntypedStreamHandler>{};
  final _streamControllers = <int, StreamController>{};
  final _streamSubscriptions = <int, StreamSubscription>{};

  /// Makes a call to an endpoint at other side of the channel.
  Future<R> call<R>(Request<R> request) {
    _checkIsOpen();
    final id = _generateConversationId();
    final completer = _callCompleter[id] = Completer<Object?>();
    _sendMessage(_CallRequest(id, request));
    return completer.future.then(_checkType);
  }

  /// Returns a stream for an endpoint at the other side of the channel.
  Stream<R> stream<R>(Request<R> request) {
    _checkIsOpen();
    final id = _generateConversationId();
    // ignore: close_sinks
    late StreamController<Object?> controller;
    controller = StreamController<Object?>(
      onListen: () {
        _streamControllers[id] = controller;
        _sendMessage(_ListenToStream(id, request));
      },
      onCancel: () {
        _streamControllers.remove(id);
        _sendMessage(_CancelStream(id));
      },
    );

    return controller.stream.map(_checkType);
  }

  /// Adds a call endpoint to this side of the channel.
  void addCallEndpoint<T extends Request<R>, R>(CallHandler<T, R> handler) {
    _checkStatusIsNot(ChannelStatus.closed);
    assert(
      !_callHandlers.containsKey(T),
      'call endpoint already added: $T',
    );
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
  /// By default a [Channel] is opened when it is created. Setting `autoOpen`
  /// to `false` disables this behavior and the [Channel] must then be opened
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

      if (message is _CallRequest) {
        _handleCallRequest(message);
      } else if (message is _CallSuccess) {
        _handleCallSuccessResponse(message);
      } else if (message is _CallError) {
        _handleCallErrorResponse(message);
      } else if (message is _ListenToStream) {
        _handleListenToStream(message);
      } else if (message is _CancelStream) {
        _handleCancelStream(message);
      } else if (message is _StreamEvent) {
        _handleStreamEvent(message);
      } else if (message is _StreamError) {
        _handleStreamError(message);
      } else if (message is _StreamDone) {
        _handleStreamDone(message);
      }
    });
  }

  /// Closes this side of the channel.
  ///
  /// This stops this [Channel] from responding to requests from the other side.
  /// Call responses which are attempted to be sent after this point are dropped
  /// and open streams are closed.
  ///
  /// If there are pending calls or open streams, which originated from this
  /// side, [error] must not be `null` and is used to complete those.
  Future<void> close([Object? error, StackTrace? stackTrace]) async {
    _checkIsOpen();
    _checkHasNotPendingCallsOrStreams(error);

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
      completer.completeError(error!, stackTrace);
    }
    _callCompleter.clear();

    // Close streams listening from this side.
    for (final controllers in _streamControllers.values) {
      controllers.addError(error!, stackTrace);
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

  void _handleCallSuccessResponse(_CallSuccess message) =>
      _takeCallCompleter(message)?.complete(message.result);

  void _handleCallErrorResponse(_CallError message) {
    _takeCallCompleter(message)
        ?.completeError(message.error, message.stackTrace);
  }

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
        _sendStreamEvent(message.conversationId, event);
      },
      // ignore: avoid_types_on_closure_parameters
      onError: (Object error, StackTrace stackTrace) =>
          _sendStreamError(message.conversationId, error, stackTrace),
      onDone: () => _sendStreamDone(message.conversationId),
    );
  }

  void _handleCancelStream(_CancelStream message) {
    final subscription = _takeStreamSubscription(message);
    if (subscription == null) {
      return;
    }

    subscription.cancel();
  }

  void _handleStreamEvent(_StreamEvent message) =>
      _getStreamController(message)?.add(message.result);

  void _handleStreamError(_StreamError message) => _getStreamController(message)
      ?.addError(message.error, message.stackTrace);

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
        print('<- ${message.result?.runtimeType}');
      } else if (message is _CallError) {
        print('!- ${message.error}');
      } else if (message is _ListenToStream) {
        print('=> ${message.request.runtimeType}');
      } else if (message is _CancelStream) {
        print('=|');
      } else if (message is _StreamEvent) {
        print('=> ${message.result?.runtimeType}');
      } else if (message is _StreamDone) {
        print('|=');
      } else if (message is _StreamError) {
        print('=!  ${message.error}');
      }
    }

    _transport.sink.add(message);
  }

  void _sendCallSuccess(int conversationId, Object? result) =>
      _sendMessage(_CallSuccess(conversationId, result));

  void _sendCallError(
    int conversationId,
    Object error,
    StackTrace stackTrace,
  ) =>
      _sendMessage(_CallError(conversationId, error, stackTrace));

  void _sendStreamEvent(int conversationId, Object? result) =>
      _sendMessage(_StreamEvent(conversationId, result));

  void _sendStreamError(
    int conversationId,
    Object error,
    StackTrace stackTrace,
  ) =>
      _sendMessage(_StreamError(conversationId, error, stackTrace));

  void _sendStreamDone(int conversationId) =>
      _sendMessage(_StreamDone(conversationId));

  // === Misc ==================================================================

  int _generateConversationId() => _nextConversationId++;

  void _checkStatusIs(ChannelStatus status) {
    if (_status != status) {
      throw StateError(
        'Expected Channel to be ${describeEnum(status)} but it was '
        '${describeEnum(_status)}',
      );
    }
  }

  void _checkStatusIsNot(ChannelStatus status) {
    if (_status == status) {
      throw StateError(
        'Expected Channel not to be ${describeEnum(status)} but it was',
      );
    }
  }

  void _checkIsOpen() => _checkStatusIs(ChannelStatus.open);

  void _checkHasNotPendingCallsOrStreams(Object? error) {
    if (error == null && _callCompleter.isNotEmpty) {
      throw ArgumentError.value(
        error,
        'error',
        'must not be null if there are pending calls',
      );
    }

    if (error == null && _streamControllers.isNotEmpty) {
      throw ArgumentError.value(
        error,
        'error',
        'must not be null if there are pending streams',
      );
    }
  }

  T _checkType<T>(Object? value) {
    if (value is! T) {
      throw ArgumentError.value(value, 'value', 'expected type $T');
    }
    return value;
  }
}

// === Channel SerializationRegistry ===========================================

SerializationRegistry channelSerializationRegistry() => SerializationRegistry()
  // Errors
  ..addObjectCodec<UnimplementedError>(
    'UnimplementedError',
    serialize: (value, _) => {'message': value.message},
    deserialize: (json, _) => UnimplementedError(json['message'] as String?),
    isIsolatePortSafe: false,
  )
  ..addObjectCodec<ArgumentError>(
    'ArgumentError',
    serialize: (value, _) => {'message': value.toString()},
    deserialize: (map, _) => ArgumentError(map.getAs<String>('message')),
    isIsolatePortSafe: false,
  )

  // Protocol messages
  .._addProtocolMessage('CallRequest', _CallRequest.deserialize)
  .._addProtocolMessage('CallSuccess', _CallSuccess.deserialize)
  .._addProtocolMessage('CallError', _CallError.deserialize)
  .._addProtocolMessage('ListenToStream', _ListenToStream.deserialize)
  .._addProtocolMessage('CancelStream', _CancelStream.deserialize)
  .._addProtocolMessage('StreamEvent', _StreamEvent.deserialize)
  .._addProtocolMessage('StreamError', _StreamError.deserialize)
  .._addProtocolMessage('StreamDone', _StreamDone.deserialize);

extension on SerializationRegistry {
  void _addProtocolMessage<T extends _Message>(
    String typeName,
    SerializableDeserializer<T> deserialize,
  ) {
    addSerializableCodec(typeName, deserialize, isIsolatePortSafe: false);
  }
}

abstract class _Message implements Serializable {
  _Message(this.conversationId);

  _Message.deserialize(StringMap map)
      : conversationId = map.getAs('conversationId');

  final int conversationId;

  @override
  StringMap serialize(SerializationContext context) =>
      {'conversationId': conversationId};
}

abstract class _RequestMessage extends _Message {
  _RequestMessage(int conversationId, this.request) : super(conversationId);

  _RequestMessage.deserialize(StringMap map, SerializationContext context)
      : request = context.deserializePolymorphic(map['request']),
        super.deserialize(map);

  final Object? request;

  @override
  StringMap serialize(SerializationContext context) => {
        ...super.serialize(context),
        'request': context.serializePolymorphic(request),
      };
}

abstract class _SuccessMessage extends _Message {
  _SuccessMessage(int conversationId, this.result) : super(conversationId);

  _SuccessMessage.deserialize(StringMap map, SerializationContext context)
      : result = context.deserializePolymorphic(map['result']),
        super.deserialize(map);

  final Object? result;

  @override
  StringMap serialize(SerializationContext context) => {
        ...super.serialize(context),
        'result': context.serializePolymorphic(result),
      };
}

abstract class _ErrorMessage extends _Message {
  _ErrorMessage(int conversationId, this.error, this.stackTrace)
      : super(conversationId);

  _ErrorMessage.deserialize(StringMap map, SerializationContext context)
      : error = context.deserializePolymorphic(map['error'])!,
        stackTrace = context.deserializeAs(map['stackTrace']),
        super.deserialize(map);

  final Object error;
  final StackTrace? stackTrace;

  @override
  StringMap serialize(SerializationContext context) {
    Object? error = this.error;
    if (!context.canSerialize(error)) {
      error = SerializationError('No serializer registered for error: $error');
    }

    return {
      ...super.serialize(context),
      'error': context.serializePolymorphic(error),
      'stackTrace': context.serialize(stackTrace),
    };
  }
}

class _CallRequest extends _RequestMessage {
  _CallRequest(int conversationId, Object? request)
      : super(conversationId, request);

  _CallRequest._fromJson(StringMap map, SerializationContext context)
      : super.deserialize(map, context);

  static _CallRequest deserialize(
          StringMap map, SerializationContext context) =>
      _CallRequest._fromJson(map, context);
}

class _CallSuccess extends _SuccessMessage {
  _CallSuccess(int conversationId, Object? result)
      : super(conversationId, result);

  _CallSuccess._fromJson(StringMap map, SerializationContext context)
      : super.deserialize(map, context);

  static _CallSuccess deserialize(
          StringMap map, SerializationContext context) =>
      _CallSuccess._fromJson(map, context);
}

class _CallError extends _ErrorMessage {
  _CallError(int conversationId, Object error, StackTrace? stackTrace)
      : super(conversationId, error, stackTrace);

  _CallError._fromJson(StringMap map, SerializationContext context)
      : super.deserialize(map, context);

  static _CallError deserialize(StringMap map, SerializationContext context) =>
      _CallError._fromJson(map, context);
}

class _ListenToStream extends _RequestMessage {
  _ListenToStream(int conversationId, Object? request)
      : super(conversationId, request);

  _ListenToStream._fromJson(StringMap map, SerializationContext context)
      : super.deserialize(map, context);

  static _ListenToStream deserialize(
          StringMap map, SerializationContext context) =>
      _ListenToStream._fromJson(map, context);
}

class _CancelStream extends _Message {
  _CancelStream(int conversationId) : super(conversationId);

  _CancelStream._fromJson(StringMap map) : super.deserialize(map);

  static _CancelStream deserialize(
          StringMap map, SerializationContext context) =>
      _CancelStream._fromJson(map);
}

class _StreamEvent extends _SuccessMessage {
  _StreamEvent(int conversationId, Object? response)
      : super(conversationId, response);

  _StreamEvent._fromJson(StringMap map, SerializationContext context)
      : super.deserialize(map, context);

  static _StreamEvent deserialize(
          StringMap map, SerializationContext context) =>
      _StreamEvent._fromJson(map, context);
}

class _StreamError extends _ErrorMessage {
  _StreamError(int conversationId, Object error, StackTrace? stackTrace)
      : super(conversationId, error, stackTrace);

  _StreamError._fromJson(StringMap map, SerializationContext context)
      : super.deserialize(map, context);

  static _StreamError deserialize(
          StringMap map, SerializationContext context) =>
      _StreamError._fromJson(map, context);
}

class _StreamDone extends _Message {
  _StreamDone(int conversationId) : super(conversationId);

  _StreamDone._fromJson(StringMap map) : super.deserialize(map);

  static _StreamDone deserialize(StringMap map, SerializationContext context) =>
      _StreamDone._fromJson(map);
}
