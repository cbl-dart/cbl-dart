import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';

import 'native_callbacks.dart';
import 'worker/worker.dart';

extension ValueExt<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}

Uint8List jointUint8Lists(List<Uint8List> lists) {
  final length = lists.fold<int>(0, (sum, it) => sum + it.lengthInBytes);
  final result = Uint8List(length);
  var offset = 0;

  for (final list in lists) {
    result.setAll(offset, list);
    offset += list.lengthInBytes;
  }

  return result;
}

String redact(String string) {
  final chars = string.characters;
  final unredactedChars = 3;
  final redactedChars =
      max(chars.length - 3, min(unredactedChars, chars.length));
  final unredactedCharsStr = chars.getRange(redactedChars);
  return ('*' * redactedChars) + unredactedCharsStr.string;
}

/// Utility to create a [Stream] from a native callback.
///
/// Callbacks are registered through a request (created by [requestFactory]),
/// which is executed on a [worker] to not block the calling Isolate.
///
/// [eventCreator] receives the result of the callback registration request and
/// the arguments from the native side an turns them into an event of type [T].
///
/// The returned stream is single subscription.
///
/// If [finishBlockingCall] is `true`, the native caller receives `null` as a
/// result when [eventCreator] returns/completes. The native caller is also
/// notified if [eventCreator] throws/rejects.
///
/// See:
/// - [NativeCallbacks]
Stream<T> callbackStream<T, S>({
  required Worker worker,
  required WorkerRequest<S> Function(int callbackId) requestFactory,
  required FutureOr<T> Function(S requestResult, List arguments) eventCreator,
  bool finishBlockingCall = false,
}) {
  final callbacks = NativeCallbacks.instance;
  late StreamController<T> controller;
  late Future<bool> callbackAdded;
  late S requestResult;

  void onListen() {
    final callbackId =
        callbacks.registerCallback<FutureOr<T> Function(S, List)>(
      eventCreator,
      (eventCreator, arguments, result) async {
        // Callbacks can come in before the registration request from the worker
        // comes back. In this case `requestResult` has not be initialized yet.
        // By waiting for `callbackAdded`, `requestResult` is guarantied to be
        // set after this line.
        await callbackAdded;

        // We use `add` instead of `addStream` because the callback can fire
        // before the Future from `addStream` returns.
        try {
          controller.add(await eventCreator(requestResult, arguments));
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        } finally {
          if (finishBlockingCall) result!(null);
        }
      },
    );

    callbackAdded = worker.execute(requestFactory(callbackId)).then((result) {
      requestResult = result;
      return true;
    }).catchError((Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
      controller.close();
      return false;
    });
  }

  Future onCancel() async {
    if (await callbackAdded) {
      callbacks.unregisterCallback(eventCreator, runFinalizer: true);
    }
  }

  controller = StreamController(onListen: onListen, onCancel: onCancel);

  return controller.stream;
}
