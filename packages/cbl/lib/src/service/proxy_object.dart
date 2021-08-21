import '../support/dart_finalizer.dart';
import 'cbl_service.dart';
import 'cbl_service_api.dart';
import 'channel.dart';

abstract class ProxyObject with ProxyObjectMixin {
  ProxyObject(Channel channel, int objectId) {
    bindToTargetObject(channel, objectId);
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
  /// The channel to the [CblService] through which the target object
  /// is accessed.
  Channel? get channel => _channel;
  Channel? _channel;

  /// The id of the target object.
  int? get objectId => _objectId;
  int? _objectId;

  late void Function() finalizeEarly;

  void bindToTargetObject(Channel channel, int objectId) {
    if (_channel != null) {
      throw StateError('ProxyObject has already been already bound.');
    }

    _channel = channel;
    _objectId = objectId;

    final finalizerToken = dartFinalizerRegistry.registerFinalizer(
      this,
      _finalizer(_channel!, _objectId!),
    );

    finalizeEarly = () => dartFinalizerRegistry.unregisterFinalizer(
          finalizerToken,
          callFinalizer: true,
        );
  }
}

DartFinalizer _finalizer(Channel channel, int id) => () {
      // If the channel has already been closed the target object will be
      // cleaned as part of closing the service.
      if (channel.status == ChannelStatus.open) {
        channel.call(ReleaseObject(id));
      }
    };
