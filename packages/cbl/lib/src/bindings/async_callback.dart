// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_positional_boolean_parameters, avoid_private_typedef_functions, camel_case_types

import 'dart:ffi';
import 'dart:isolate';

import 'cblitedart.dart' as cblitedart;

final class AsyncCallbackBindings {
  const AsyncCallbackBindings();

  static final _finalizer = NativeFinalizer(Native.addressOf<
              NativeFunction<cblitedart.NativeCBLDart_AsyncCallback_Delete>>(
          cblitedart.CBLDart_AsyncCallback_Delete)
      .cast());

  cblitedart.CBLDart_AsyncCallback create(
    int id,
    Finalizable callbackObject,
    SendPort sendPort, {
    required bool debug,
  }) {
    final result =
        cblitedart.CBLDart_AsyncCallback_New(id, sendPort.nativePort, debug);
    _finalizer.attach(callbackObject, result.cast());
    return result;
  }

  void close(cblitedart.CBLDart_AsyncCallback callback) {
    cblitedart.CBLDart_AsyncCallback_Close(callback);
  }

  void callForTest(cblitedart.CBLDart_AsyncCallback callback, int result) {
    cblitedart.CBLDart_AsyncCallback_CallForTest(callback, result);
  }
}
