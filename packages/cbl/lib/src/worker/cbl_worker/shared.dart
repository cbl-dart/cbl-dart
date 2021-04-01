import 'dart:ffi';

import '../worker.dart';

abstract class ObjectRequest<O extends NativeType, T> extends WorkerRequest<T> {
  ObjectRequest(Pointer<O> object) : _objectAddress = object.address;

  final int _objectAddress;

  Pointer<O> get object => Pointer.fromAddress(_objectAddress).cast();
}

abstract class ObjectWithArgRequest<O extends NativeType, A extends NativeType,
    T> extends ObjectRequest<O, T> {
  ObjectWithArgRequest(Pointer<O> object, Pointer<A> argument)
      : _argAddress = argument.address,
        super(object);

  final int _argAddress;

  Pointer<A> get argument => Pointer.fromAddress(_argAddress).cast();
}
