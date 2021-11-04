import 'dart:async';

import 'package:meta/meta.dart';

import '../service/cbl_service.dart';
import '../service/cbl_service_api.dart';
import '../service/proxy_object.dart';
import 'async_callback.dart';
import 'resource.dart';

/// A token which is handed out when adding a listener to an observable object.
///
/// To remove a listener from an observable object, call the objects
/// `removeChangeListener` method with the corresponding token.
abstract class ListenerToken {}

abstract class AbstractListenerToken extends ListenerToken {
  bool get isRemoved => _isRemoved;
  var _isRemoved = false;

  @mustCallSuper
  FutureOr<void> removeListener() {
    if (_isRemoved) {
      throw StateError('Listener has already been removed.');
    }
    _isRemoved = true;
  }
}

abstract class SyncListenerToken extends AbstractListenerToken {
  @override
  void removeListener();
}

abstract class AsyncListenerToken extends AbstractListenerToken {
  @override
  Future<void> removeListener();
}

class ListenerTokenRegistry with ClosableResourceMixin {
  ListenerTokenRegistry(this.owner) {
    attachTo(owner);
  }

  final ClosableResourceMixin owner;

  final _tokens = <AbstractListenerToken>[];

  void add(AbstractListenerToken token) => use(() {
        assert(!_tokens.contains(token));
        _tokens.add(token);
        _updateNeedsFinalization();
      });

  FutureOr<void> remove(ListenerToken token) {
    if (!_tokens.remove(token)) {
      throw ArgumentError(
        'You are trying to remove a listener from the wrong object.\n'
        'The provided ListenerToken was not created by $owner',
      );
    }

    _updateNeedsFinalization();

    if (token is SyncListenerToken) {
      return useSync(token.removeListener);
    } else if (token is AsyncListenerToken) {
      return use(token.removeListener);
    }
  }

  void _updateNeedsFinalization() {
    needsToBeClosedByParent = _tokens.isNotEmpty;
  }

  @override
  Future<void> performClose() async {
    await Future.wait<void>(
      _tokens.map((token) => Future.value(token.removeListener())),
    );
    _tokens.clear();
  }
}

class FfiListenerToken extends SyncListenerToken {
  FfiListenerToken(this._callback);

  final AsyncCallback _callback;

  @override
  void removeListener() {
    super.removeListener();
    _callback.close();
  }
}

class ProxyListenerToken<T> extends AsyncListenerToken {
  ProxyListenerToken(
    this.client,
    this.target,
    this.listenerId,
    this.listenerFn,
  );

  final CblServiceClient client;

  final ProxyObjectMixin target;

  final int listenerId;

  final void Function(T) listenerFn;

  void callListener(T event) {
    // Ignore all events once the listener has been removed, in case the proxied
    // listener is called again before it is removed.
    if (_isRemoved) {
      return;
    }
    listenerFn(event);
  }

  @override
  Future<void> removeListener() {
    super.removeListener();
    return client.channel
        .call(RemoveChangeListener(
          targetId: target.objectId!,
          listenerId: listenerId,
        ))
        .then((_) => client.unregisterObject(listenerId));
  }
}
