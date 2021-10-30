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

/// A resource which is based on a [NativeObject].
abstract class NativeResource<T extends NativeType> {
  /// The native object underlying this resource.
  NativeObject<T> get native;
}

mixin ClosableResourceMixin implements ClosableResource {
  ClosableResourceMixin? _parent;
  late final Set<ClosableResourceMixin> _finalizableChildren = {};
  late final _pendingRequests = <Future<void>>[];
  Future<void>? _pendingClose;

  @override
  bool get isClosed => _isClosed || (_parent?.isClosed ?? false);
  var _isClosed = false;

  /// Attach this resources to its [parent] resource.
  void attachTo(ClosableResourceMixin parent) {
    _checkIsNotClosed();

    _parent = parent;
    _updateFinalizationRegistration();
  }

  /// Whether this resource needs to have its [finalize] method called when
  /// it or its parent is closed.
  bool get needsFinalization => _needsFinalization;
  bool _needsFinalization = true;

  set needsFinalization(bool needsFinalization) {
    _checkIsNotClosed();

    if (_needsFinalization != needsFinalization) {
      _needsFinalization = needsFinalization;
      _updateFinalizationRegistration();
    }
  }

  /// Performs any work necessary to close this resource.
  @protected
  FutureOr<void> finalize() {}

  void _setChildFinalizationEnabled(ClosableResourceMixin child, bool enabled) {
    if (enabled) {
      _finalizableChildren.add(child);
    } else {
      _finalizableChildren.remove(child);
    }

    _updateFinalizationRegistration();
  }

  bool? _needsFinalizationRegistration;

  void _updateFinalizationRegistration() {
    final needsFinalizationRegistration = _needsFinalization ||
        _finalizableChildren.isNotEmpty ||
        _pendingRequests.isNotEmpty;

    if (_needsFinalizationRegistration == needsFinalizationRegistration) {
      return;
    }

    _needsFinalizationRegistration = needsFinalizationRegistration;
    _parent?._setChildFinalizationEnabled(
      this,
      needsFinalizationRegistration,
    );
  }

  /// This method is used by this resource to wrap all synchronous access from
  /// its public API.
  @protected
  T useSync<T>(T Function() f) {
    _checkIsNotClosed();
    return f();
  }

  /// This method is used by this resource to wrap all asynchronous access from
  /// its public API.
  @protected
  Future<T> use<T>(FutureOr<T> Function() f) {
    _checkIsNotClosed();

    return Future.value(f()).also((it) {
      late Future<void> request;

      void removePendingRequest(Object? _) {
        _pendingRequests.remove(request);
        _updateFinalizationRegistration();
      }

      request = it
          .then(removePendingRequest, onError: removePendingRequest)
          .also(_pendingRequests.add);

      _updateFinalizationRegistration();
    });
  }

  @override
  Future<void> close() => _pendingClose ??= Future.sync(() async {
        final parent = _parent;
        if (parent != null && !parent._isClosed) {
          _parent?._setChildFinalizationEnabled(this, false);
        }

        _isClosed = true;

        await Future.wait([
          ..._pendingRequests,
          ..._finalizableChildren.map((child) => child.close()),
        ]);

        _finalizableChildren.clear();

        if (_needsFinalization) {
          await finalize();
        }
      });

  void _checkIsNotClosed() {
    if (isClosed) {
      throw StateError('Resource has already been closed: $this');
    }
  }
}
