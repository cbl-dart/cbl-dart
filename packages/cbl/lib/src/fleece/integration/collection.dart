import 'dart:async';

import 'package:meta/meta.dart';

import '../../bindings.dart';
import '../../support/utils.dart';
import '../encoder.dart';
import 'context.dart';
import 'value.dart';

abstract class MCollection {
  MCollection({
    MContext? context,
    this.isMutable = true,
  })  : context = context ?? const MContext(),
        _isMutated = true;

  MCollection.asCopy(
    MCollection original, {
    required this.isMutable,
  })  : context = original.context,
        _isMutated = true;

  MCollection.asChild(
    MValue slot,
    MCollection parent, {
    required this.isMutable,
  })  : context = parent.context,
        _slot = slot,
        _parent = parent,
        _isMutated = slot.isMutated;

  MValue? _slot;
  MCollection? _parent;
  final bool isMutable;
  bool _isMutated;

  /// The context which this collection uses when reading Fleece data.
  ///
  /// The context owns the Fleece data that this collection is based on.
  ///
  /// Collections must ensure that this it's context stays reachable while
  /// accessing Fleece data by using a [cblReachabilityFence].
  final MContext context;

  bool get hasMutableChildren => isMutable;

  bool get isMutated => _isMutated;

  Iterable<MValue> get values;

  FutureOr<void> encodeTo(FleeceEncoder encoder) =>
      performEncodeTo(encoder).then((_) {
        // We keep the context alive until the end of encoding, so that
        // MCollections can safely use Fleece data during encoding.
        cblReachabilityFence(context);
      });

  FutureOr<void> performEncodeTo(FleeceEncoder encoder);

  @protected
  void mutate() {
    if (!_isMutated) {
      _isMutated = true;
      _slot?.mutate();
      _parent?.mutate();
    }
  }

  void setSlot(MValue? newSlot, MValue? oldSlot) {
    if (_slot == oldSlot) {
      _slot = newSlot;
      if (newSlot == null) {
        _parent = null;
      }
    }
  }
}
