import 'dart:async';

import 'collection.dart';
import 'database.dart';

/// A namespace for [Collection]s.
///
/// A scope implicitly exists when there is at least one collection created
/// under it.
///
/// ## Lifecycle
///
/// A [Scope] remains valid until either the [Database] is closed or the [Scope]
/// itself is invalidated because all [Collection]s in the [Scope] have been
/// deleted.
///
/// {@category Database}
abstract class Scope {
  /// The name of the default scope.
  static const defaultName = '_default';

  /// The name of this scope.
  String get name;

  /// The [Collection]s in this scope.
  FutureOr<List<Collection>> get collections;

  /// Returns the [Collection] with the given [name] in this scope.
  ///
  /// Returns `null` if no collection with the given [name] exists.
  FutureOr<Collection?> collection(String name);
}

/// A [Scope] with a primarily synchronous API.
///
/// {@category Database}
abstract class SyncScope extends Scope {
  @override
  List<SyncCollection> get collections;

  @override
  SyncCollection? collection(String name);
}

/// A [Scope] with a primarily asynchronous API.
///
/// {@category Database}
abstract class AsyncScope extends Scope {
  @override
  Future<List<AsyncCollection>> get collections;

  @override
  Future<AsyncCollection?> collection(String name);
}
