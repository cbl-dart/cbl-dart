import 'dart:async';

import 'package:meta/meta.dart';

import '../../bindings.dart';
import '../../support/utils.dart';
import '../encoder.dart';
import 'context.dart';
import 'value.dart';

abstract base class MCollection {
  MCollection({MContext? context, this.isMutable = true})
    : context = context ?? const MContext(),
      _isMutated = true,
      _needsToSaveExternalData = false;

  MCollection.asCopy(MCollection original, {required this.isMutable})
    : context = original.context,
      _isMutated = true,
      _needsToSaveExternalData = original._needsToSaveExternalData;

  MCollection.asChild(
    MValue slot,
    MCollection parent, {
    required this.isMutable,
  }) : context = parent.context,
       _slot = slot,
       _parent = parent,
       _isMutated = slot.isMutated,
       _needsToSaveExternalData = false;

  MValue? _slot;
  MCollection? _parent;
  final bool isMutable;
  bool _isMutated;
  bool _needsToSaveExternalData;

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

  FutureOr<void> saveExternalData(Object context) {
    if (!_needsToSaveExternalData) {
      return null;
    }

    FutureOr<void>? result;

    for (final value in values) {
      result = result.then((_) => value.saveExternalData(context));
    }

    return result;
  }

  void encodeTo(FleeceEncoder encoder) {
    performEncodeTo(encoder);
    // We keep the context alive until the end of encoding, so that
    // MCollections can safely use Fleece data during encoding.
    cblReachabilityFence(context);
  }

  void performEncodeTo(FleeceEncoder encoder);

  @protected
  void markMutated() {
    if (!_isMutated) {
      _isMutated = true;
      _slot?.markMutated();
      _parent?.markMutated();
    }
  }

  void markNeedsToSaveExternalData() {
    if (!_needsToSaveExternalData) {
      _needsToSaveExternalData = true;
      _parent?.markNeedsToSaveExternalData();
    }
  }

  void setSlot(MValue? newSlot, MValue? oldSlot, MCollection? newParent) {
    if (_slot == oldSlot) {
      _slot = newSlot;
      if (newSlot == null) {
        _parent = null;
      } else {
        _parent = newParent;

        // If this collection needs to save external data, and is added
        // to another collection, the new parent needs to be marked as needing
        // to save external data, too.
        if (_needsToSaveExternalData) {
          _parent!.markNeedsToSaveExternalData();
        }
      }
    } else if (newSlot != null) {
      // The collection is being added to another collection, in addition to
      // the current one. This is an edge case. Instead of keeping track of
      // multiple parents, we mark the additional parent as needing to
      // save external data, because this collection does not keep a reference
      // to the additional parent, so it cannot mark it as needing to save
      // external data dynamically, when external data is inserted.
      assert(_parent != newParent);
      newParent!.markNeedsToSaveExternalData();
    }
  }
}
