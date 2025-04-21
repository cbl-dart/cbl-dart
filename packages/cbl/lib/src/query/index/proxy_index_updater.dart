import '../../document/common.dart';
import '../../fleece/integration/integration.dart';
import '../../query.dart';
import '../../service/cbl_service.dart';
import '../../service/cbl_service_api.dart';
import '../../service/proxy_object.dart';
import '../../support/resource.dart';
import 'proxy_query_index.dart';

final class ProxyIndexUpdater extends ProxyObject
    with ClosableResourceMixin
    implements AsyncIndexUpdater {
  ProxyIndexUpdater({
    required CblServiceClient client,
    required this.index,
    required IndexUpdaterState state,
  })  : length = state.length,
        super(client.channel, state.id) {
    needsToBeClosedByParent = false;
    attachTo(index);
  }

  final ProxyQueryIndex index;

  @override
  final int length;

  @override
  Future<T?> value<T extends Object>(int index) => use(() async {
        final sendableValue = await channel
            .call(IndexUpdaterGetValue(updaterId: objectId, index: index));

        final value = MRoot.fromContext(
          MContext(data: sendableValue.value),
          isMutable: false,
        ).asNative;

        return coerceObject(value, coerceNull: false);
      });

  @override
  Future<void> setVector(int index, List<double>? vector) =>
      use(() => channel.call(IndexUpdaterSetVector(
            updaterId: objectId,
            index: index,
            vector: vector,
          )));

  @override
  Future<void> skipVector(int index) =>
      use(() => channel.call(IndexUpdaterSkipVector(
            updaterId: objectId,
            index: index,
          )));

  @override
  Future<void> finish() =>
      use(() => channel.call(IndexUpdaterFinish(updaterId: objectId)));
}
