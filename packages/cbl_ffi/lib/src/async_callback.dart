import 'dart:ffi';
import 'dart:isolate';

import 'bindings.dart';
import 'utils.dart';

class CBLDartAsyncCallback extends Opaque {}

typedef _CBLDart_AsyncCallback_New_C = Pointer<CBLDartAsyncCallback> Function(
  Uint32 id,
  Handle dartCallback,
  Int64 sendPort,
  Uint8 debug,
);
typedef _CBLDart_AsyncCallback_New = Pointer<CBLDartAsyncCallback> Function(
  int id,
  Object dartCallback,
  int sendPort,
  int debug,
);

typedef _CBLDart_AsyncCallback_Close_C = Void Function(
  Pointer<CBLDartAsyncCallback> callback,
);
typedef _CBLDart_AsyncCallback_Close = void Function(
  Pointer<CBLDartAsyncCallback> callback,
);

typedef _CBLDart_AsyncCallback_CallForTest_C = Void Function(
  Pointer<CBLDartAsyncCallback> callback,
  Int64 result,
);
typedef _CBLDart_AsyncCallback_CallForTest = void Function(
  Pointer<CBLDartAsyncCallback> callback,
  int result,
);

class AsyncCallbackBindings extends Bindings {
  AsyncCallbackBindings(Bindings parent) : super(parent) {
    _new = libs.cblDart.lookupFunction<_CBLDart_AsyncCallback_New_C,
        _CBLDart_AsyncCallback_New>(
      'CBLDart_AsyncCallback_New',
    );
    _close = libs.cblDart.lookupFunction<_CBLDart_AsyncCallback_Close_C,
        _CBLDart_AsyncCallback_Close>(
      'CBLDart_AsyncCallback_Close',
    );
    _callForTest = libs.cblDart.lookupFunction<
        _CBLDart_AsyncCallback_CallForTest_C,
        _CBLDart_AsyncCallback_CallForTest>(
      'CBLDart_AsyncCallback_CallForTest',
    );
  }

  late final _CBLDart_AsyncCallback_New _new;
  late final _CBLDart_AsyncCallback_Close _close;
  late final _CBLDart_AsyncCallback_CallForTest _callForTest;

  Pointer<CBLDartAsyncCallback> create(
    int id,
    Object dartCallback,
    SendPort sendPort, {
    required bool debug,
  }) =>
      _new(id, dartCallback, sendPort.nativePort, debug.toInt());

  void close(Pointer<CBLDartAsyncCallback> callback) {
    _close(callback);
  }

  void callForTest(Pointer<CBLDartAsyncCallback> callback, int result) {
    _callForTest(callback, result);
  }
}
