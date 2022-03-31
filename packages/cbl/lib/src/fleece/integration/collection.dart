import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:meta/meta.dart';

import '../../support/utils.dart';
import '../encoder.dart';
import 'context.dart';
import 'value.dart';

abstract class MCollection {
  MCollection({
    MContext? context,
    bool isMutable = true,
    this.dataOwner,
  })  : _context = context,
        _isMutable = isMutable,
        hasMutableChildren = isMutable,
        _isMutated = true;

  MCollection.asCopy(
    MCollection original, {
    required bool isMutable,
  })  : _context = original._context,
        dataOwner = original.dataOwner,
        _isMutable = isMutable,
        hasMutableChildren = isMutable,
        _isMutated = true;

  MCollection.asChild(
    MValue slot,
    MCollection parent, {
    required bool isMutable,
  })  : dataOwner = parent.dataOwner,
        _isMutable = isMutable,
        hasMutableChildren = isMutable,
        _isMutated = slot.isMutated {
    updateParent(slot, parent);
  }

  MContext get context => _context ?? const NoopMContext();
  MContext? _context;

  /// An object that owns the Fleece data that this collection is contained in.
  ///
  /// This field is only populated if Fleece data is being used.
  ///
  /// Collections must ensure that this object stays reachable while accessing
  /// Fleece data by using a [cblReachabilityFence].
  final Object? dataOwner;

  MValue? _slot;

  MCollection? get parent => _parent;
  MCollection? _parent;

  Iterable<MValue> get values;

  bool get isMutable => _isMutable;
  final bool _isMutable;

  final bool hasMutableChildren;

  bool get isMutated => _isMutated;
  bool _isMutated;

  bool get isEncoding => _isEncoding || (_parent?.isEncoding ?? false);
  bool _isEncoding = false;

  FutureOr<void> encodeTo(FleeceEncoder encoder) {
    FutureOr<void> encode() => performEncodeTo(encoder).then((_) {
          // We keep the data owner alive until the end of encoding, so that
          // MCollections can safely use Fleece data during encoding.
          cblReachabilityFence(dataOwner);
        });

    if (isEncoding) {
      // Some ancestor is the encoding root so we don't need to do the
      // bookkeeping again.
      return encode();
    } else {
      // This object is the encoding root and needs to keep track of whether
      // encoding is ongoing.
      _isEncoding = true;
      return finallySyncOrAsync((_) => _isEncoding = false, encode);
    }
  }

  FutureOr<void> performEncodeTo(FleeceEncoder encoder);

  @protected
  void mutate() {
    assert(isMutable && !isEncoding);

    if (!_isMutated) {
      _isMutated = true;
      _slot?.mutate();
      _parent?.mutate();
    }
  }

  /// Called when this collection is assigned to a new slot in a parent
  /// collection or removed from its current parent collection.
  void updateParent(MValue? slot, MCollection? parent) {
    assert(slot == null && parent == null || slot != null && parent != null);

    final parentContext = parent?._context;

    // Nothing changed.
    if (_slot == slot && _parent == parent && _context == parentContext) {
      return;
    }

    _slot = slot;
    _parent = parent;

    if (_isMutated) {
      _slot?.mutate();
      _parent?.mutate();
    }

    _updateContext(parentContext);
  }

  void _updateContext(MContext? context) {
    if (context == null || _context == context) {
      return;
    }

    assert(
      _context == null || _context == context,
      'once set the context of a MCollection cannot change',
    );

    _context = context;

    // Propagate context to children.
    for (final value in values) {
      value.updateParent(this);
    }
  }
}
