import 'dart:ffi';
import 'dart:isolate';

import 'bindings.dart';
import 'cblitedart.dart' as cblitedart_lib;

export 'cblitedart.dart' show CBLDart_AsyncCallback;

final class AsyncCallbackBindings extends Bindings {
  AsyncCallbackBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblitedart.addresses.CBLDart_AsyncCallback_Delete.cast(),
  );

  cblitedart_lib.CBLDart_AsyncCallback create(
    int id,
    Finalizable callbackObject,
    SendPort sendPort, {
    required bool debug,
  }) {
    final result = cblitedart.CBLDart_AsyncCallback_New(
      id,
      sendPort.nativePort,
      debug,
    );
    _finalizer.attach(callbackObject, result.cast());
    return result;
  }

  void close(cblitedart_lib.CBLDart_AsyncCallback callback) {
    cblitedart.CBLDart_AsyncCallback_Close(callback);
  }

  void callForTest(cblitedart_lib.CBLDart_AsyncCallback callback, int result) {
    cblitedart.CBLDart_AsyncCallback_CallForTest(callback, result);
  }
}
