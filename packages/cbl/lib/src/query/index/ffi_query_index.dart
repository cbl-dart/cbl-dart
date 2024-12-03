import 'dart:ffi';

import '../../bindings.dart';
import '../../database/ffi_database.dart';
import '../../query.dart';
import '../../support/resource.dart';
import '../../support/utils.dart';
import 'ffi_index_updater.dart';

final _bindings = CBLBindings.instance.queryIndex;

final class FfiQueryIndex
    with ClosableResourceMixin
    implements SyncQueryIndex, Finalizable {
  FfiQueryIndex.fromPointer(
    this.pointer, {
    required this.collection,
    required this.name,
  }) {
    CBLBindings.instance.base
        .bindCBLRefCountedToDartObject(this, pointer.cast());
    needsToBeClosedByParent = false;
    attachTo(collection);
  }

  final Pointer<CBLQueryIndex> pointer;

  @override
  final FfiCollection collection;

  @override
  final String name;

  @override
  SyncIndexUpdater? beginUpdate({required int limit}) => useSync(() => _bindings
      .beginUpdate(pointer, limit)
      ?.let((updater) => FfiIndexUpdater.fromPointer(updater, index: this)));
}
