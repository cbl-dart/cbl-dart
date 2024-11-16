import 'dart:ffi';
import 'dart:isolate';

import 'bindings.dart';
import 'cblitedart.dart';

export 'cblitedart.dart' show CBLDart_AsyncCallback;

final class AsyncCallbackBindings extends Bindings {
  AsyncCallbackBindings(super.parent);

  late final _finalizer =
      NativeFinalizer(cblDart.addresses.CBLDart_AsyncCallback_Delete.cast());

  CBLDart_AsyncCallback create(
    int id,
    Finalizable callbackObject,
    SendPort sendPort, {
    required bool debug,
  }) {
    final result =
        cblDart.CBLDart_AsyncCallback_New(id, sendPort.nativePort, debug);
    _finalizer.attach(callbackObject, result.cast());
    return result;
  }

  void close(CBLDart_AsyncCallback callback) {
    cblDart.CBLDart_AsyncCallback_Close(callback);
  }

  void callForTest(CBLDart_AsyncCallback callback, int result) {
    cblDart.CBLDart_AsyncCallback_CallForTest(callback, result);
  }
}
