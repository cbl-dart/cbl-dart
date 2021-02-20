import 'dart:ffi';

import '../worker.dart';

abstract class ObjectRequest<T> extends WorkerRequest<T> {
  ObjectRequest(this._address);

  final int _address;

  Pointer<Void> get pointer => Pointer.fromAddress(_address);
}
