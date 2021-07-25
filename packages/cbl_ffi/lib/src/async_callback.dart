import 'dart:ffi';
import 'dart:isolate';

import 'bindings.dart';
import 'utils.dart';

class CBLDartAsyncCallback extends Opaque {}

typedef CBLDart_AsyncCallback_New_C = Pointer<CBLDartAsyncCallback> Function(
  Uint32 id,
  Handle dartCallback,
  Int64 sendPort,
  Uint8 debug,
);
typedef CBLDart_AsyncCallback_New = Pointer<CBLDartAsyncCallback> Function(
  int id,
  Object dartCallback,
  int sendPort,
  int debug,
);

typedef CBLDart_AsyncCallback_Close_C = Void Function(
  Pointer<CBLDartAsyncCallback> callback,
);
typedef CBLDart_AsyncCallback_Close = void Function(
  Pointer<CBLDartAsyncCallback> callback,
);

typedef CBLDart_AsyncCallback_CallForTest_C = Void Function(
  Pointer<CBLDartAsyncCallback> callback,
  Int64 result,
);
typedef CBLDart_AsyncCallback_CallForTest = void Function(
  Pointer<CBLDartAsyncCallback> callback,
  int result,
);

class AsyncCallbackBindings extends Bindings {
  AsyncCallbackBindings(Bindings parent) : super(parent) {
    _new = libs.cblDart
        .lookupFunction<CBLDart_AsyncCallback_New_C, CBLDart_AsyncCallback_New>(
      'CBLDart_AsyncCallback_New',
    );
    _close = libs.cblDart.lookupFunction<CBLDart_AsyncCallback_Close_C,
        CBLDart_AsyncCallback_Close>(
      'CBLDart_AsyncCallback_Close',
    );
    _callForTest = libs.cblDart.lookupFunction<
        CBLDart_AsyncCallback_CallForTest_C, CBLDart_AsyncCallback_CallForTest>(
      'CBLDart_AsyncCallback_CallForTest',
    );
  }

  late final CBLDart_AsyncCallback_New _new;
  late final CBLDart_AsyncCallback_Close _close;
  late final CBLDart_AsyncCallback_CallForTest _callForTest;

  Pointer<CBLDartAsyncCallback> create(
    int id,
    Object dartCallback,
    SendPort sendPort,
    bool debug,
  ) {
    return _new(id, dartCallback, sendPort.nativePort, debug.toInt());
  }

  void close(Pointer<CBLDartAsyncCallback> callback) {
    _close(callback);
  }

  void callForTest(Pointer<CBLDartAsyncCallback> callback, int result) {
    _callForTest(callback, result);
  }
}
