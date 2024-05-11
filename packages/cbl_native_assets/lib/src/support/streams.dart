import 'dart:async';
import 'dart:typed_data';

import 'listener_token.dart';
import 'resource.dart';

Future<Uint8List> byteStreamToFuture(Stream<Uint8List> stream) async {
  final builder = BytesBuilder(copy: false);
  await stream.forEach(builder.add);
  return builder.toBytes();
}

/// Transforms streams into [ResourceStream]s.
class ResourceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  ResourceStreamTransformer({
    required this.parent,
    this.blocking = false,
  });

  /// See [ResourceStream.parent].
  final ClosableResourceMixin parent;

  /// See [ResourceStream.blocking].
  final bool blocking;

  @override
  Stream<T> bind(Stream<T> stream) => ResourceStream(
        parent: parent,
        stream: stream,
        blocking: blocking,
      );
}

/// A stream that exposes another [stream] as a [ClosableResource].
///
/// Listening to the stream requires the [parent] resource to be open.
///
/// When a stream is closed through [ClosableResource.close], the stream either
/// blocks by waiting for the subscription to be canceled or the wrapped
/// [stream] sending the done event, or it cancels itself early.
///
/// This behavior can be controlled through [blocking].
class ResourceStream<T> extends Stream<T> with ClosableResourceMixin {
  ResourceStream({
    required this.parent,
    required this.stream,
    this.blocking = false,
  });

  /// The parent resource of this stream.
  final ClosableResourceMixin parent;

  /// The stream wrapped by this stream.
  final Stream<T> stream;

  /// Whether to block [close] by waiting for the subscription to be canceled or
  /// the wrapped [stream] sending the done event, or to cancel the stream
  /// early.
  final bool blocking;

  Function? _onError;
  void Function()? _onDone;

  var _hasListener = false;
  var _isDone = false;
  late final _doneCompleter = Completer<void>();

  // ignore: cancel_subscriptions
  late StreamSubscription<T> _subscription;
  late Future<void> _cancellation;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (_hasListener) {
      throw StateError(
        'Cannot listen to this single subscription stream, because it has '
        'already been listened to.',
      );
    }

    _hasListener = true;

    attachTo(parent);

    return useSync(() {
      _onError = onError;
      _onDone = onDone;

      _subscription = stream.listen(
        onData,
        // ignore: avoid_types_on_closure_parameters
        onError: (Object error, StackTrace stackTrace) {
          if (cancelOnError ?? false) {
            _makeDone();
          }

          final onError = _onError;
          if (onError is void Function(Object)) {
            onError(error);
          } else if (onError is void Function(Object, StackTrace)) {
            onError(error, stackTrace);
          }
        },
        onDone: () {
          _makeDone();

          _onDone?.call();
        },
        cancelOnError: cancelOnError,
      );

      return _ResourceStreamSubscription(this);
    });
  }

  void _makeDone() {
    _isDone = true;

    if (blocking) {
      _doneCompleter.complete();
    }

    if (!isClosed) {
      needsToBeClosedByParent = false;
    }

    _cancellation = Future.wait([
      _subscription.cancel(),
      // Ensures that ResourceStreams that are done don't gather as children of
      // their parents and continue to consume resources.
      if (!isClosed) close(),
    ]);
  }

  Future<void> _cancelFromSubscription() {
    if (!_isDone) {
      _makeDone();
    }

    return _cancellation;
  }

  Future<void> _cancelFromResource() {
    if (!_isDone) {
      _makeDone();
    }

    // Instead of the wrapped stream ending the stream, the resource is ending
    // it.
    _onDone?.call();

    return _cancellation;
  }

  @override
  FutureOr<void> performClose() async {
    if (!needsToBeClosedByParent) {
      return;
    }

    // This method is only called for streams that have been used because,
    // streams are only registered with their parent when being listened to.

    if (blocking) {
      // Wait for the stream to end, either through the listener canceling
      // or exhausting the wrapped stream.
      await _doneCompleter.future;
    } else {
      await _cancelFromResource();
    }
  }
}

class _ResourceStreamSubscription<T> implements StreamSubscription<T> {
  _ResourceStreamSubscription(this.stream);

  final ResourceStream<T> stream;

  @override
  Future<E> asFuture<E>([E? futureValue]) => throw UnimplementedError();

  @override
  void onData(void Function(T data)? handleData) =>
      stream._subscription.onData(handleData);

  @override
  void onError(Function? handleError) => stream._onError = handleError;

  @override
  void onDone(void Function()? handleDone) => stream._onDone = handleDone;

  @override
  bool get isPaused => stream._subscription.isPaused;

  @override
  void pause([Future<void>? resumeSignal]) =>
      stream._subscription.pause(resumeSignal);

  @override
  void resume() => stream._subscription.resume();

  @override
  Future<void> cancel() => stream._cancelFromSubscription();
}

/// A single subscription [Stream] which does asynchronous work before being
/// fully subscribed to.
///
/// The [Future] in [listening] completes once the stream is fully subscribe and
/// rejects with an error if subscribing to the stream failed.
abstract class AsyncListenStream<T> extends Stream<T> {
  /// Future that completes once the stream is fully subscribe and rejects with
  /// an error if subscribing to the stream failed.
  Future<void> get listening;
}

class ListenerStream<T> extends AsyncListenStream<T> {
  ListenerStream({
    required this.parent,
    required this.addListener,
  });

  final ClosableResourceMixin parent;
  final FutureOr<AbstractListenerToken> Function(void Function(T)) addListener;

  @override
  late final Future<void> listening = _listeningCompleter.future;
  final _listeningCompleter = Completer<void>();

  late final _controller = StreamController<T>(
    onListen: _onListen,
    onCancel: _onCancel,
  );
  var _isCanceled = false;
  late AbstractListenerToken _token;

  void _onListen() => Future.sync(() => addListener(_listener)).then(
        (token) {
          _token = token;
          _listeningCompleter.complete();
        },
        onError: _onAddListenerError,
      );

  Future<void> _onCancel() async {
    _isCanceled = true;

    await listening.then(
      (_) => _token.removeListener(),
      // ignore: avoid_types_on_closure_parameters
      onError: (Object _) {
        // If listening threw an error there is no token and no listener to
        // remove.
      },
    );
  }

  void _listener(T event) {
    if (!_isCanceled) {
      _controller.add(event);
    }
  }

  void _onAddListenerError(Object error, StackTrace stackTrace) {
    if (!_isCanceled) {
      _controller
        ..addError(error, stackTrace)
        ..close();
    }
    _listeningCompleter.completeError(error, stackTrace);
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _controller.stream
          .transform(ResourceStreamTransformer(parent: parent))
          .listen(
            onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
          );
}

class RepeatableStream<T> extends Stream<T> {
  RepeatableStream(this._source);

  final Stream<T> _source;
  // ignore: cancel_subscriptions
  StreamSubscription<T>? _sourceSub;
  var _sourceDone = false;
  final List<T> _sourceChunks = <T>[];
  Object? _sourceError;
  StackTrace? _sourceStackTrace;
  final List<MultiStreamController<T>> _destinations = [];

  late final Stream<T> _stream = Stream.multi((destination) {
    _sourceChunks.forEach(destination.add);

    if (!_sourceDone) {
      _destinations.add(destination);

      destination.onCancel = () {
        _destinations.remove(destination);

        if (!_sourceDone && _destinations.isEmpty) {
          _sourceSub!.pause();
        }
      };

      _sourceSub ??= _source.listen((chunk) {
        _sourceChunks.add(chunk);

        for (final controller in _destinations) {
          controller.add(chunk);
        }
      }, onDone: () {
        _sourceDone = true;
        _sourceSub = null;

        for (final controller in _destinations) {
          controller.close();
        }

        _destinations.clear();
        // ignore: avoid_types_on_closure_parameters
      }, onError: (Object error, StackTrace stackTrace) {
        _sourceDone = true;
        _sourceSub = null;
        _sourceError = error;
        _sourceStackTrace = stackTrace;

        for (final controller in _destinations) {
          controller.addError(error, stackTrace);
        }
      });

      _sourceSub!.resume();
    } else {
      if (_sourceError != null) {
        destination.addError(_sourceError!, _sourceStackTrace);
      }
      destination.close();
    }
  });

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}
