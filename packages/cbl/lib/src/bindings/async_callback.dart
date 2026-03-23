import 'dart:ffi';
import 'dart:isolate';

import '../support/isolate.dart';
import 'cblitedart.dart' as cblitedart;

export 'cblitedart.dart' show CBLDart_AsyncCallback;

final class AsyncCallbackBindings {
  static final _finalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_AsyncCallback_Delete.cast(),
  );

  static cblitedart.CBLDart_AsyncCallback create(
    int id,
    Finalizable callbackObject,
    SendPort sendPort, {
    required bool debug,
  }) {
    ensureInitializedForCurrentIsolate();
    final result = cblitedart.CBLDart_AsyncCallback_New(
      id,
      sendPort.nativePort,
      debug,
    );
    _finalizer.attach(callbackObject, result.cast());
    return result;
  }

  static void close(cblitedart.CBLDart_AsyncCallback callback) {
    cblitedart.CBLDart_AsyncCallback_Close(callback);
  }

  static void callForTest(
    cblitedart.CBLDart_AsyncCallback callback,
    int result,
  ) {
    cblitedart.CBLDart_AsyncCallback_CallForTest(callback, result);
  }
}
