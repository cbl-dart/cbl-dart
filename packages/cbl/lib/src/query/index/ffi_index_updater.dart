import 'dart:ffi';

import '../../bindings.dart';
import '../../document/array.dart';
import '../../fleece/containers.dart';
import '../../fleece/integration/integration.dart';
import '../../query.dart';
import '../../support/resource.dart';
import 'ffi_query_index.dart';

final class FfiIndexUpdater
    with ClosableResourceMixin, ArrayInterfaceMixin
    implements SyncIndexUpdater, Finalizable {
  FfiIndexUpdater.fromPointer(this.pointer, {required FfiQueryIndex index}) {
    BaseBindings.bindCBLRefCountedToDartObject(this, pointer.cast());
    needsToBeClosedByParent = false;
    attachTo(index);
  }

  final Pointer<CBLIndexUpdater> pointer;

  Value flValue(int index) =>
      Value.fromPointer(IndexUpdaterBindings.value(pointer, index));

  @override
  Object? cblValue(int index) => useSync(
    () => MRoot.fromContext(
      MContext(data: flValue(index)),
      isMutable: false,
    ).asNative,
  );

  @override
  int get length => useSync(() => IndexUpdaterBindings.count(pointer));

  @override
  void setVector(int index, List<double>? vector) =>
      useSync(() => IndexUpdaterBindings.setVector(pointer, index, vector));

  @override
  void skipVector(int index) =>
      useSync(() => IndexUpdaterBindings.skipVector(pointer, index));

  @override
  void finish() => useSync(() => IndexUpdaterBindings.finish(pointer));
}
