// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_positional_boolean_parameters, avoid_private_typedef_functions, camel_case_types

import 'dart:ffi';
import 'dart:isolate';

import 'bindings.dart';

final class CBLDartAsyncCallback extends Opaque {}

typedef _CBLDart_AsyncCallback_New_C = Pointer<CBLDartAsyncCallback> Function(
  Uint32 id,
  Int64 sendPort,
  Bool debug,
);
typedef _CBLDart_AsyncCallback_New = Pointer<CBLDartAsyncCallback> Function(
  int id,
  int sendPort,
  bool debug,
);

typedef _CBLDart_AsyncCallback_Close_C = Void Function(
  Pointer<CBLDartAsyncCallback> callback,
);
typedef _CBLDart_AsyncCallback_Close = void Function(
  Pointer<CBLDartAsyncCallback> callback,
);

typedef _CBLDart_AsyncCallback_Delete_C = Void Function(
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
  AsyncCallbackBindings(super.parent) {
    _new = libs.cblDart.lookupFunction<_CBLDart_AsyncCallback_New_C,
        _CBLDart_AsyncCallback_New>(
      'CBLDart_AsyncCallback_New',
    );
    _deletePtr =
        libs.cblDart.lookup<NativeFunction<_CBLDart_AsyncCallback_Delete_C>>(
      'CBLDart_AsyncCallback_Delete',
    );
    _close = libs.cblDart.lookupFunction<_CBLDart_AsyncCallback_Close_C,
        _CBLDart_AsyncCallback_Close>(
      'CBLDart_AsyncCallback_Close',
    );
    _callForTest = libs.cblDart.lookupFunction<
        _CBLDart_AsyncCallback_CallForTest_C,
        _CBLDart_AsyncCallback_CallForTest>(
      'CBLDart_AsyncCallback_CallForTest',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDart_AsyncCallback_New _new;
  late final Pointer<NativeFunction<_CBLDart_AsyncCallback_Delete_C>>
      _deletePtr;
  late final _CBLDart_AsyncCallback_Close _close;
  late final _CBLDart_AsyncCallback_CallForTest _callForTest;

  late final _finalizer = NativeFinalizer(_deletePtr.cast());

  Pointer<CBLDartAsyncCallback> create(
    int id,
    Finalizable callbackObject,
    SendPort sendPort, {
    required bool debug,
  }) {
    final result = _new(id, sendPort.nativePort, debug);
    _finalizer.attach(callbackObject, result.cast());
    return result;
  }

  void close(Pointer<CBLDartAsyncCallback> callback) {
    _close(callback);
  }

  void callForTest(Pointer<CBLDartAsyncCallback> callback, int result) {
    _callForTest(callback, result);
  }
}
