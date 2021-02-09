import 'dart:ffi';

abstract class ObjectRequest {
  ObjectRequest(this._address);

  final int _address;

  Pointer<Void> get pointer => Pointer.fromAddress(_address);
}
