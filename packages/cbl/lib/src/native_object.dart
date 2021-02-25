import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import 'worker/worker.dart';

/// Runs [body] in a native object scope.
///
/// A native object scope is a [Zone], in which [NativeObject] are recorded,
/// whose [NativeObject.pointer] property has been accessed.
///
/// When accessing [NativeObject.pointer] and using it asynchronously, the
/// native object needs to stay alive until the asynchronous work is done. When
/// the pointer to the native object is used in an asynchronous context, the
/// [NativeObject] can be garbage collected too early. In this case
/// native finalizers are executed while work is ongoing. To prevent
/// this condition, a native object scope creates references to [NativeObject]s,
/// whose pointers have been accessed. This keeps them from being garbage
/// collected while asynchronous work is pending.
T runNativeObjectScoped<T>(T Function() body) => runZoned(
      body,
      zoneValues: {#_nativeObjectScope: <NativeObject>{}},
    );

Set<NativeObject>? get _nativeObjectScope =>
    Zone.current[#_nativeObjectScope] as Set<NativeObject>?;

/// Represents an object on the native side.
///
/// The lifetime of the native object is determined by the lifetime of this
/// object.
class NativeObject<T extends NativeType> {
  NativeObject(Pointer<T> pointer) : _pointer = pointer;

  final Pointer<T> _pointer;

  /// The pointer to the native object.
  ///
  /// Code which access this property must be run in a [runNativeObjectScoped].
  Pointer<T> get pointer {
    final nativeObjectScope = _nativeObjectScope;

    assert(
      nativeObjectScope != null,
      'NativeObject.pointer requires a `nativeObjectScope`',
    );

    nativeObjectScope!.add(this);

    return _pointer;
  }

  /// The pointer to the native object, without requiring a native object scope.
  ///
  /// Callers must guarantee that the returned pointer is only used while this
  /// object has not been garbage collected.
  ///
  /// See:
  /// - [runNativeObjectScoped] for what a native object scope is.
  Pointer<T> get pointerUnsafe => _pointer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeObject &&
          runtimeType == other.runtimeType &&
          _pointer.address == other._pointer.address;

  @override
  int get hashCode => super.hashCode ^ _pointer.address.hashCode;
}

/// A resource which is based on a [NativeObject].
abstract class NativeResource<T extends NativeObject> {
  NativeResource(this.native);

  /// The native object underlying this resource.
  @internal
  final T native;
}

/// A native object, whose operations are executed in a [Worker].
mixin WorkerObject<T extends NativeType> on NativeObject<T> {
  /// The worker on which operations of this object are executed.
  Worker get worker;

  /// Executes an operation of this object on [worker] and returns the result.
  ///
  /// The call to [createRequest] is wrapped in [runNativeObjectScoped].
  ///
  /// [createRequest] is passed the address of this object as an `int` and
  /// has to return the [WorkerRequest] to be executed.
  Future<R> execute<R>(
    FutureOr<WorkerRequest<R>> Function(int address) createRequest,
  ) =>
      runNativeObjectScoped(() async {
        return worker.execute(await createRequest(pointer.address));
      });
}

class SimpleWorkerObject<T extends NativeType> extends NativeObject<T>
    with WorkerObject {
  SimpleWorkerObject(Pointer<T> pointer, this.worker) : super(pointer);

  @override
  final Worker worker;
}

/// Represents a reference to a CouchbaseLite C API object that is reference
/// counted.
class CblRefCountedObject<T extends NativeType> extends NativeObject<T> {
  /// Creates a reference to a reference counted native CouchbaseLite C API
  /// object.
  ///
  /// When [release] is `true`, the reference count of the native object
  /// will be decremented when the Dart object is garbage collected.
  ///
  /// When [retain] is `true`, the reference count of the native object
  /// will be increment as part of creating the Dart object.
  CblRefCountedObject(
    Pointer<T> pointer, {
    required bool release,
    required bool retain,
  }) : super(pointer) {
    assert(!retain || release, 'only a retained object can be released');

    if (release) {
      CBLBindings.instance.base.bindCBLRefCountedToDartObject(
        this,
        pointer.cast(),
        retain.toInt(),
      );
    }
  }
}

/// A [CblRefCountedObject] which is also a [WorkerObject].
class CblRefCountedWorkerObject<T extends NativeType>
    extends CblRefCountedObject<T> with WorkerObject {
  CblRefCountedWorkerObject(
    Pointer<T> pointer,
    this.worker, {
    required bool release,
    required bool retain,
  }) : super(pointer, release: release, retain: retain);

  @override
  final Worker worker;
}

/// Represents a reference to a CBLReplicator.
class CBLReplicatorObject extends NativeObject<Void> with WorkerObject {
  /// Creates a reference to a CBLReplicator.
  CBLReplicatorObject(Pointer<Void> pointer, this.worker) : super(pointer) {
    CBLBindings.instance.replicator.bindToDartObject(
      this,
      pointer.cast(),
    );
  }

  @override
  final Worker worker;
}

/// Represents a reference to a Fleece document.
class FleeceDocObject extends NativeObject<Void> {
  /// Creates a reference to a Fleece document.
  FleeceDocObject(Pointer<Void> pointer) : super(pointer) {
    CBLBindings.instance.fleece.doc.bindToDartObject(
      this,
      pointer.cast(),
    );
  }
}

/// Represents a reference to a Fleece value that is reference counted.
class FleeceRefCountedObject<T extends NativeType> extends NativeObject<T> {
  /// Creates a reference to a Fleece value that is reference counted.
  ///
  /// When [release] is `true`, the reference count of the native object
  /// will be decremented when the Dart object is garbage collected.
  ///
  /// When [retain] is `true`, the reference count of the native object
  /// will be increment as part of creating the Dart object.
  FleeceRefCountedObject(
    Pointer<T> pointer, {
    required bool release,
    required bool retain,
  }) : super(pointer) {
    assert(!retain || release, 'only a retained object can be released');

    if (release) {
      CBLBindings.instance.fleece.value.bindToDartObject(
        this,
        pointer.cast(),
        retain.toInt(),
      );
    }
  }
}
