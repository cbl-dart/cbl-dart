import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

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

mixin ClosableResourceMixin implements ClosableResource {
  ClosableResourceMixin? _parent;
  late final Set<ClosableResourceMixin> _childrenToClose = {};
  late final _pendingRequests = DoubleLinkedQueue<Future<void>>();
  Future<void>? _pendingClose;

  @override
  bool get isClosed => _isClosed || (_parent?.isClosed ?? false);
  var _isClosed = false;

  /// Attach this resources to its [parent] resource.
  void attachTo(ClosableResourceMixin parent) {
    _checkIsNotClosed();

    _parent = parent;
    _updateParentRegistration();
  }

  /// Whether this resource needs to be closed when its parent is closed to not
  /// leak resources.
  ///
  /// Even if this property is `false`, the parent might still closed it.
  @protected
  bool get needsToBeClosedByParent => _needsToBeClosedByParent;
  bool _needsToBeClosedByParent = true;

  set needsToBeClosedByParent(bool value) {
    _checkIsNotClosed();

    if (_needsToBeClosedByParent != value) {
      _needsToBeClosedByParent = value;
      _updateParentRegistration();
    }
  }

  /// Performs the actual work work necessary to close this resource.
  ///
  /// Should not be called directly. Instead call [close].
  @protected
  FutureOr<void> performClose() {}

  void _updateChild(
    ClosableResourceMixin child, {
    required bool needsToBeClosed,
  }) {
    if (needsToBeClosed) {
      _childrenToClose.add(child);
    } else {
      _childrenToClose.remove(child);
    }

    _updateParentRegistration();
  }

  bool? _needsToBeClosed;

  void _updateParentRegistration() {
    final needsToBeClosed = _needsToBeClosedByParent ||
        _childrenToClose.isNotEmpty ||
        _pendingRequests.isNotEmpty;

    if (_needsToBeClosed == needsToBeClosed) {
      return;
    }

    _needsToBeClosed = needsToBeClosed;
    _parent?._updateChild(
      this,
      needsToBeClosed: needsToBeClosed,
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
        _updateParentRegistration();
      }

      request = it
          .then(removePendingRequest, onError: removePendingRequest)
          .also(_pendingRequests.add);

      _updateParentRegistration();
    });
  }

  @override
  Future<void> close() => _pendingClose ??= Future.sync(() async {
        final parent = _parent;
        if (parent != null && !parent._isClosed) {
          _parent?._updateChild(this, needsToBeClosed: false);
        }

        _isClosed = true;

        await Future.wait([
          ..._pendingRequests,
          ..._childrenToClose.map((child) => child.close()),
        ]);

        _childrenToClose.clear();

        await performClose();
      });

  void _checkIsNotClosed() {
    if (isClosed) {
      throw StateError('Resource has already been closed: $this');
    }
  }
}
