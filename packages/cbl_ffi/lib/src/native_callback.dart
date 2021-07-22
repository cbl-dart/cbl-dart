import 'dart:ffi';
import 'dart:isolate';

import 'bindings.dart';
import 'utils.dart';

class Callback extends Opaque {}

typedef CBLDart_Callback_New_C = Pointer<Callback> Function(
  Uint32 id,
  Handle dartCallback,
  Int64 sendPort,
  Uint8 debug,
);
typedef CBLDart_Callback_New = Pointer<Callback> Function(
  int id,
  Object dartCallback,
  int sendPort,
  int debug,
);

typedef CBLDart_Callback_Close_C = Void Function(Pointer<Callback> callback);
typedef CBLDart_Callback_Close = void Function(Pointer<Callback> callback);

typedef CBLDart_Callback_CallForTest_C = Void Function(
  Pointer<Callback> callback,
  Int64 result,
);
typedef CBLDart_Callback_CallForTest = void Function(
  Pointer<Callback> callback,
  int result,
);

class NativeCallbackBindings extends Bindings {
  NativeCallbackBindings(Bindings parent) : super(parent) {
    _new = libs.cblDart
        .lookupFunction<CBLDart_Callback_New_C, CBLDart_Callback_New>(
      'CBLDart_Callback_New',
    );
    _close = libs.cblDart
        .lookupFunction<CBLDart_Callback_Close_C, CBLDart_Callback_Close>(
      'CBLDart_Callback_Close',
    );
    _callForTest = libs.cblDart.lookupFunction<CBLDart_Callback_CallForTest_C,
        CBLDart_Callback_CallForTest>(
      'CBLDart_Callback_CallForTest',
    );
  }

  late final CBLDart_Callback_New _new;
  late final CBLDart_Callback_Close _close;
  late final CBLDart_Callback_CallForTest _callForTest;

  Pointer<Callback> create(
    int id,
    Object dartCallback,
    SendPort sendPort,
    bool debug,
  ) {
    return _new(id, dartCallback, sendPort.nativePort, debug.toInt());
  }

  void close(Pointer<Callback> callback) {
    _close(callback);
  }

  void callForTest(Pointer<Callback> callback, int result) {
    _callForTest(callback, result);
  }
}
