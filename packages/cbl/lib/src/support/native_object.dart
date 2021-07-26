import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../errors.dart';
import 'ffi.dart';
import 'resource.dart';

/// Keeps a [NativeObject] alive while the [Function] [fn] is running.
///
/// If [fn] returns a [Future] [object] is kept alive until the future
/// completes.
T keepAlive<P extends NativeType, T>(
  NativeObject<P> object,
  T Function(Pointer<P> pointer) fn,
) {
  assert(() {
    object._debugKeepAliveRefCount++;
    return true;
  }());

  final result = fn(object._pointer);

  if (result is Future) {
    return result.whenComplete(() {
      assert(() {
        object._debugKeepAliveRefCount--;
        return true;
      }());
      _keepAliveUntil(object);
    }) as T;
  }

  assert(() {
    object._debugKeepAliveRefCount--;
    return true;
  }());
  _keepAliveUntil(object);
  return result;
}

final _keepAlive = keepAlive;

@pragma('vm:never-inline')
void _keepAliveUntil(Object? object) {}

/// Runs [body] while keeping accessed [NativeObject]s alive.
///
/// A native object keep alive is a [Zone], in which [NativeObject] are
/// recorded when their [NativeObject.pointer] property has been accessed.
///
/// When accessing [NativeObject.pointer] and using it, the
/// native object needs to stay alive while its pointer is being used. While
/// the pointer to the native object is used, the [NativeObject] can be garbage
/// collected too early. In this case native finalizers are executed while work
/// is ongoing. To prevent this condition, a native object keep alive creates
/// references to [NativeObject]s, whose pointers have been accessed. This keeps
/// them from being garbage collected while their pointers are being used.
T runKeepAlive<T>(T Function() body) => runZoned(
      body,
      zoneValues: {#_aliveNativeObjects: Set<NativeObject>.identity()},
    );

Set<NativeObject>? get _aliveNativeObjects =>
    Zone.current[#_aliveNativeObjects] as Set<NativeObject>?;

T runNativeCalls<T>(T Function() body) =>
    runWithErrorTranslation(() => runKeepAlive(body));

extension NativeObjectCallExtension<P extends NativeType> on NativeObject<P> {
  /// Keeps this [NativeObject] alive while the [Function] [fn] is running.
  ///
  /// If [fn] returns a [Future] this object is kept alive until the future
  /// completes.
  R call<R>(R Function(Pointer<P> pointer) fn) =>
      runWithErrorTranslation(() => _keepAlive(this, fn));
}

/// Handle to an object on the native side.
class NativeObject<T extends NativeType> with NativeResourceMixin<T> {
  NativeObject(Pointer<T> pointer) : _pointer = pointer;

  final Pointer<T> _pointer;

  var _debugKeepAliveRefCount = 0;

  @override
  NativeObject<T> get native => this;

  /// The pointer to the native object.
  ///
  /// Code which access this property must be run in a [runKeepAlive] or use
  /// [keepAlive] or [NativeObjectCallExtension].
  Pointer<T> get pointer {
    final aliveNativeObjects = _aliveNativeObjects;

    assert(
      _debugKeepAliveRefCount > 0 || aliveNativeObjects != null,
      'NativeObject.pointer must to be accessed from within `keepAlive` or'
      ' `runKeepAlive`',
    );

    aliveNativeObjects?.add(this);

    return _pointer;
  }

  /// The pointer to the native object, without requiring a native object keep
  /// alive.
  ///
  /// Callers must guarantee that the returned pointer is only used while this
  /// object has not been garbage collected.
  Pointer<T> get pointerUnsafe => _pointer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeObject &&
          runtimeType == other.runtimeType &&
          _pointer.address == other._pointer.address;

  @override
  int get hashCode => _pointer.address.hashCode;
}

/// Handle to a CouchbaseLite C API object.
class CblObject<T extends NativeType> extends NativeObject<T> {
  /// Creates a handle to a CouchbaseLite C API object.
  ///
  /// [adopt] should be `true` when an existing reference to the native object
  /// is transferred to the created [CblObject] or the native object
  /// has just been created and the created [CblObject] is the initial
  /// reference holder.
  CblObject(
    Pointer<T> pointer, {
    bool adopt = true,
    required String? debugName,
  }) : super(pointer) {
    cblBindings.base.bindCBLRefCountedToDartObject(
      this,
      pointer.cast(),
      !adopt,
      debugName,
    );
  }
}

/// Handle to a CBLReplicator.
class CBLReplicatorObject extends NativeObject<CBLReplicator> {
  /// Creates a handle to a CBLReplicator.
  CBLReplicatorObject(
    Pointer<CBLReplicator> pointer, {
    required String? debugName,
  }) : super(pointer) {
    cblBindings.replicator.bindReplicatorToDartObject(this, pointer, debugName);
  }
}

/// Handle to a Fleece doc.
class FleeceDocObject extends NativeObject<FLDoc> {
  /// Creates a handle to a Fleece doc.
  FleeceDocObject(Pointer<FLDoc> pointer) : super(pointer) {
    cblBindings.fleece.doc.bindToDartObject(this, pointer);
  }
}

/// Handle to a Fleece value.
class FleeceValueObject<T extends NativeType> extends NativeObject<T> {
  /// Creates a handle to a Fleece value.
  ///
  /// [adopt] should be `true` when an existing reference to the native object
  /// is transferred to the created [FleeceValueObject] or the native object
  /// has just been created and the created [FleeceValueObject] is the initial
  /// reference holder.
  FleeceValueObject(
    Pointer<T> pointer, {
    this.isRefCounted = true,
    bool adopt = false,
  }) : super(pointer) {
    assert(
      !adopt || isRefCounted,
      'only an object which is ref counted can be adopted',
    );

    if (isRefCounted) {
      cblBindings.fleece.value.bindToDartObject(
        this,
        pointer.cast(),
        !adopt,
      );
    }
  }

  /// Whether this object updates the ref count of the native object when
  /// it is created and garbage collected.
  final bool isRefCounted;
}
