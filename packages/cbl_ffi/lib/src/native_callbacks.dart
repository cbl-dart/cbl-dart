import 'dart:ffi';

import 'libraries.dart';

typedef CBLDart_NewCallbackIsolate_C = Pointer<Void> Function(
  Handle handle,
  Int64 sendPort,
);
typedef CBLDart_NewCallbackIsolate = Pointer<Void> Function(
  Object handle,
  int sendPort,
);

typedef CBLDart_CallbackIsolate_RegisterCallback_C = Uint64 Function(
  Pointer<Void> isolate,
);
typedef CBLDart_CallbackIsolate_RegisterCallback = int Function(
  Pointer<Void> isolate,
);

typedef CBLDart_CallbackIsolate_UnregisterCallback_C = Void Function(
  Uint64 callbackId,
  Uint8 bool,
);
typedef CBLDart_CallbackIsolate_UnregisterCallback = void Function(
  int callbackId,
  int runFinalizer,
);

typedef CBLDart_Callback_CallForTest_C = Void Function(
  Int64 callbackId,
  Int64 result,
);
typedef CBLDart_Callback_CallForTest = void Function(
  int callbackId,
  int result,
);

class NativeCallbacksBindings {
  NativeCallbacksBindings(Libraries libs)
      : newCallbackIsolate = libs.cblDart.lookupFunction<
            CBLDart_NewCallbackIsolate_C, CBLDart_NewCallbackIsolate>(
          'CBLDart_NewCallbackIsolate',
        ),
        registerCallback = libs.cblDart.lookupFunction<
            CBLDart_CallbackIsolate_RegisterCallback_C,
            CBLDart_CallbackIsolate_RegisterCallback>(
          'CBLDart_CallbackIsolate_RegisterCallback',
        ),
        unregisterCallback = libs.cblDart.lookupFunction<
            CBLDart_CallbackIsolate_UnregisterCallback_C,
            CBLDart_CallbackIsolate_UnregisterCallback>(
          'CBLDart_CallbackIsolate_UnregisterCallback',
        ),
        callForTest = libs.cblDart.lookupFunction<
            CBLDart_Callback_CallForTest_C, CBLDart_Callback_CallForTest>(
          'CBLDart_Callback_CallForTest',
        );

  final CBLDart_NewCallbackIsolate newCallbackIsolate;
  final CBLDart_CallbackIsolate_RegisterCallback registerCallback;
  final CBLDart_CallbackIsolate_UnregisterCallback unregisterCallback;
  final CBLDart_Callback_CallForTest callForTest;
}
