import 'dart:ffi';

import 'libraries.dart';

class Callback extends Opaque {}

typedef CBLDart_NewCallback_C = Pointer<Callback> Function(
  Handle dartCallback,
  Int64 sendPort,
);
typedef CBLDart_NewCallback = Pointer<Callback> Function(
  Object dartCallback,
  int sendPort,
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

class NativeCallbackBindings {
  NativeCallbackBindings(Libraries libs)
      : makeNew = libs.cblDart
            .lookupFunction<CBLDart_NewCallback_C, CBLDart_NewCallback>(
          'CBLDart_NewCallback',
        ),
        close = libs.cblDart
            .lookupFunction<CBLDart_Callback_Close_C, CBLDart_Callback_Close>(
          'CBLDart_Callback_Close',
        ),
        callForTest = libs.cblDart.lookupFunction<
            CBLDart_Callback_CallForTest_C, CBLDart_Callback_CallForTest>(
          'CBLDart_Callback_CallForTest',
        );

  final CBLDart_NewCallback makeNew;
  final CBLDart_Callback_Close close;
  final CBLDart_Callback_CallForTest callForTest;
}
