import 'dart:ffi';

abstract class ObjectRequest {
  ObjectRequest(this.address);

  final int address;

  Pointer<Void> get pointer => Pointer.fromAddress(address);
}
