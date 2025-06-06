import 'dart:ffi';

import '../../database/proxy_database.dart';
import '../../query.dart';
import '../../service/cbl_service.dart';
import '../../service/cbl_service_api.dart';
import '../../service/proxy_object.dart';
import '../../support/resource.dart';
import 'proxy_index_updater.dart';

final class ProxyQueryIndex extends ProxyObject
    with ClosableResourceMixin
    implements AsyncQueryIndex, Finalizable {
  ProxyQueryIndex({
    required this.client,
    required int objectId,
    required this.collection,
    required this.name,
  }) : super(client.channel, objectId) {
    needsToBeClosedByParent = false;
    attachTo(collection);
  }

  final CblServiceClient client;

  @override
  final ProxyCollection collection;

  @override
  final String name;

  @override
  Future<AsyncIndexUpdater?> beginUpdate({required int limit}) => use(() async {
    final state = await channel.call(
      BeginQueryIndexUpdate(indexId: objectId, limit: limit),
    );

    if (state == null) {
      return null;
    }

    return ProxyIndexUpdater(client: client, index: this, state: state);
  });
}
