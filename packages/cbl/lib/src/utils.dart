import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';

import 'native_callback.dart';
import 'worker/worker.dart';

extension ValueExt<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}

/// Returns the name of a enum value.
///
/// This is different from what the `toString` method of an enum value returns,
/// in that it does not have the enum name as a prefix.
String describeEnum(Object value) => value.toString().split('.')[1];

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
/// Callbacks are registered through a request (created by
/// [createRegisterCallbackRequest]), which is executed on a [worker] to not
/// block the calling Isolate.
///
/// [createEvent] receives the result of the callback registration request and
/// the arguments from the native side and turns them into an event of type [T].
///
/// The returned stream is single subscription.
///
/// If [finishBlockingCall] is `true`, the native caller receives `null` as a
/// result when [createEvent] returns/completes. The native caller is also
/// notified if [createEvent] throws/rejects.
///
/// See:
/// - [NativeCallback]
Stream<T> callbackStream<T, S>({
  required Worker worker,
  required WorkerRequest<S> Function(NativeCallback callback)
      createRegisterCallbackRequest,
  required FutureOr<T> Function(S registrationResult, List arguments)
      createEvent,
  bool finishBlockingCall = false,
}) {
  late NativeCallback callback;
  late StreamController<T> controller;
  late Future<bool> callbackRegistered;
  late S registrationResult;
  var canceled = false;

  void onListen() {
    callback = NativeCallback((arguments, result) async {
      try {
        // Callbacks can come in before the registration request from the worker
        // comes back. In this case `registrationResult` has not be initialized
        // yet. By waiting for `callbackRegistered`, `registrationResult` is
        // guarantied to be set after this line.
        await callbackRegistered;

        if (canceled) return;
        final event = await createEvent(registrationResult, arguments);
        if (canceled) return;
        controller.add(event);
      } catch (error, stackTrace) {
        if (canceled) return;
        controller.addError(error, stackTrace);
      } finally {
        if (finishBlockingCall) result!(null);
      }
    });

    callbackRegistered =
        worker.execute(createRegisterCallbackRequest(callback)).then((result) {
      registrationResult = result;
      return true;
    }).catchError((Object error, StackTrace stackTrace) {
      controller.addError(error, stackTrace);
      controller.close();
      return false;
    });
  }

  Future onCancel() async {
    canceled = true;
    if (await callbackRegistered) {
      callback.close();
    }
  }

  controller = StreamController(onListen: onListen, onCancel: onCancel);

  return controller.stream;
}

StreamController<T> callbackBroadcastStreamController<T>({
  required void Function(NativeCallback callback) startStream,
  required T Function(List arguments) createEvent,
}) {
  late NativeCallback callback;
  late StreamController<T> controller;
  var canceled = false;

  void onListen() {
    canceled = false;

    callback = NativeCallback((arguments, _) {
      if (canceled) return;
      try {
        final event = createEvent(arguments);
        controller.add(event);
      } catch (error, stacktrace) {
        controller.addError(error, stacktrace);
      }
    });

    startStream(callback);
  }

  void onCancel() {
    canceled = true;
    callback.close();
  }

  return controller =
      StreamController.broadcast(onListen: onListen, onCancel: onCancel);
}
