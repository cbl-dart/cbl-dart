import 'dart:ffi';

import 'bindings.dart';

typedef CBLDart_RegisterDartFinalizer_C = Void Function(
  Handle object,
  Int64 registrySendPort,
  Int64 token,
);
typedef CBLDart_RegisterDartFinalizer = void Function(
  Object object,
  int registrySendPort,
  int token,
);

class DartFinalizerBindings extends Bindings {
  DartFinalizerBindings(Bindings parent) : super(parent) {
    _registerDartFinalizer = libs.cblDart.lookupFunction<
        CBLDart_RegisterDartFinalizer_C,
        CBLDart_RegisterDartFinalizer>('CBLDart_RegisterDartFinalizer');
  }

  late final CBLDart_RegisterDartFinalizer _registerDartFinalizer;

  void registerDartFinalizer(Object object, int registrySendPort, int token) =>
      _registerDartFinalizer(object, registrySendPort, token);
}
