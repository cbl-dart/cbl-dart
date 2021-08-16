import 'dart:async';
import 'dart:ffi';

import 'package:meta/meta.dart';

import 'native_object.dart';
import 'utils.dart';

/// An object with a limited lifespan.
///
/// A resource must only be used while [isClosed] is not `true`. Failure to do
/// so will result in a [StateError] being thrown.
///
/// While [ClosableResource]s can be explicitly closed, resources which only
/// implement [Resource] typically depend on another resource and are
/// automatically closed when the that resource is closed.
abstract class Resource {
  /// Whether this resource has been closed.
  bool get isClosed;
}

/// A [Resource] which can be explicitly closed.
abstract class ClosableResource implements Resource {
  /// Closes this resource and frees the resources it uses.
  ///
  /// After this method has been called this resource may not be used any more,
  /// even if returned [Future] has not completed yet.
  Future<void> close();
}

/// A base class for implementations of [Resource].
///
/// See:
/// - [DelegatingResourceMixin] for a mixin which implements this class for
///   resources which delegate to its parent resource.
/// - [ClosableResourceMixin] for a mixin wich implements this class for
///   resources which need to perform some work when being closed as well as
///   close its child resources.
abstract class AbstractResource implements Resource {
  /// Registers a [child] resource to limit the lifetime of it by the lifetime
  /// of this parent.
  ///
  /// This resource parent will close [child] as part of closing itself.
  void registerChildResource(AbstractResource child);

  /// Called to notify this resource that it was registered with [parent] as a
  /// child resource in [registerChildResource].
  void _setParent(AbstractResource parent);

  /// This method is used by this resource to wrap all synchronous access from
  /// its public API.
  @protected
  T useSync<T>(T Function() f);

  /// This method is used by this resource to wrap all asynchronous access from
  /// its public API.
  @protected
  Future<T> use<T>(FutureOr<T> Function() f);
}

/// A mixin wich implements [AbstractResource] for resources which need to
/// perform some work when being closed as well as close its child resources.
mixin ClosableResourceMixin implements ClosableResource, AbstractResource {
  /// Performs any work necessary to close this resource.
  @protected
  Future<void> performClose();

  @override
  bool get isClosed => _isClosed;
  var _isClosed = false;

  final _pendingRequests = <Future<void>>[];

  Future<void>? _pendingClose;

  ClosableResourceMixin? _parent;

  final List<ClosableResourceMixin> _children = [];

  @override
  void registerChildResource(AbstractResource child) {
    child._setParent(this);

    if (child is ClosableResourceMixin) {
      assert(!_children.contains(child));
      _children.add(child);
    }
  }

  @override
  void _setParent(AbstractResource parent) {
    if (parent is ClosableResourceMixin) {
      _parent = parent;
    }
  }

  @override
  T useSync<T>(T Function() f) {
    _checkIsNotClosed();
    return f();
  }

  @override
  Future<T> use<T>(FutureOr<T> Function() f) {
    _checkIsNotClosed();

    return Future.value(f()).also((it) {
      late Future<void> request;
      void removePendingRequest(Object? _) => _pendingRequests.remove(request);
      request = it
          .then(removePendingRequest, onError: removePendingRequest)
          .also(_pendingRequests.add);
    });
  }

  /// Closes this resource, but before removing it from its parent, executes
  /// [f] and returns the result.
  ///
  /// This is useful to close a resource and produce a value based on the
  /// closed resource. In this context the work in [performClose] can be
  /// unnecessary and [doPerformClose] can be set to `false` to skip its
  /// execution.
  @protected
  Future<T> closeAndUse<T>(
    FutureOr<T> Function() f, {
    bool doPerformClose = true,
  }) async {
    _checkIsNotClosed();
    _isClosed = true;

    final result = (() async {
      await Future.wait([
        ..._pendingRequests,
        ..._children.map((child) => child.close()),
      ]);

      if (doPerformClose) {
        await performClose();
      }

      try {
        return await f();
      } finally {
        _parent?._children.remove(this);
      }
    })();

    _pendingClose = result;

    return result;
  }

  @override
  Future<void> close() => _pendingClose ??= (() async {
        _isClosed = true;

        await Future.wait([
          ..._pendingRequests,
          ..._children.map((child) => child.close()),
        ]);

        await performClose();

        _parent?._children.remove(this);
      })();

  void _checkIsNotClosed() {
    if (isClosed) {
      throw StateError('Resource has already been closed: $this');
    }
  }
}

/// A mixin which implements [AbstractResource] for a resource which delegate to
/// its parent resource.
mixin DelegatingResourceMixin implements AbstractResource {
  late AbstractResource _delegate;

  @override
  bool get isClosed => _delegate.isClosed;

  @override
  T useSync<T>(T Function() f) => _delegate.useSync(f);

  @override
  Future<T> use<T>(FutureOr<T> Function() f) => _delegate.use(f);

  @override
  void registerChildResource(AbstractResource child) =>
      _delegate.registerChildResource(child);

  @override
  void _setParent(AbstractResource parent) {
    _delegate = parent;
  }
}

/// A resource which is based on a [NativeObject].
abstract class NativeResource<T extends NativeType> {
  NativeResource(this.native);

  /// The native object underlying this resource.
  final NativeObject<T> native;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeResource &&
          other.runtimeType == other.runtimeType &&
          native == other.native;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => native.hashCode;
}

mixin NativeResourceMixin<T extends NativeType> implements NativeResource<T> {
  @override
  NativeObject<T> get native;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NativeResource &&
          other.runtimeType == other.runtimeType &&
          native == other.native;

  @override
  int get hashCode => native.hashCode;
}
