import 'dart:async';

import '../support/dart_finalizer.dart';
import 'cbl_service.dart';
import 'cbl_service_api.dart';
import 'channel.dart';

abstract class ProxyObject with ProxyObjectMixin {
  ProxyObject(
    Channel channel,
    int objectId, {
    FutureOr<void> Function()? proxyFinalizer,
  }) {
    bindToTargetObject(channel, objectId, proxyFinalizer: proxyFinalizer);
  }

  @override
  Channel get channel => super.channel!;

  @override
  int get objectId => super.objectId!;
}

/// An object which delegates some or all of its implementation to another
/// target object.
///
/// The target object is accessed through a [CblService].
mixin ProxyObjectMixin {
  /// Whether this proxy object has been bound to a target object.
  bool get isBoundToTarget => _objectId != null;

  /// The channel to the [CblService] through which the target object
  /// is accessed.
  Channel? get channel => _channel;
  Channel? _channel;

  /// The id of the target object.
  int? get objectId => _objectId;
  int? _objectId;

  late Object _finalizerToken;

  void bindToTargetObject(
    Channel channel,
    int objectId, {
    FutureOr<void> Function()? proxyFinalizer,
  }) {
    if (_channel != null) {
      throw StateError('ProxyObject has already been already bound.');
    }

    _channel = channel;
    _objectId = objectId;

    _finalizerToken = dartFinalizerRegistry.registerFinalizer(
      this,
      _finalizer(_channel!, _objectId!, proxyFinalizer),
    );
  }

  Future<void> finalizeEarly() {
    assert(isBoundToTarget);
    dartFinalizerRegistry.unregisterFinalizer(_finalizerToken);
    return channel!.call(ReleaseObject(objectId!));
  }
}

DartFinalizer _finalizer(
  Channel channel,
  int id,
  FutureOr<void> Function()? proxyFinalizer,
) =>
    () async {
      // If the channel has already been closed the target object will be
      // cleaned as part of closing the service.
      if (channel.status == ChannelStatus.open) {
        await channel.call(ReleaseObject(id));
      }
      await proxyFinalizer?.call();
    };
