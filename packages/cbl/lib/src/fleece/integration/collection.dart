import 'dart:async';

import 'package:meta/meta.dart';

import '../encoder.dart';
import 'context.dart';
import 'value.dart';

abstract class MCollection {
  MCollection({
    MContext? context,
    bool isMutable = true,
  })  : _context = context,
        _isMutable = isMutable,
        hasMutableChildren = isMutable,
        _isMutated = true;

  MCollection.asCopy(
    MCollection original, {
    required bool isMutable,
  })  : _context = original.context,
        _isMutable = isMutable,
        hasMutableChildren = isMutable,
        _isMutated = true;

  MCollection.asChild(
    MValue slot,
    MCollection parent, {
    required bool isMutable,
  })  : _isMutable = isMutable,
        hasMutableChildren = isMutable,
        _isMutated = slot.isMutated {
    updateParent(slot, parent);
  }

  MContext? get context => _context;
  MContext? _context;

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
    if (isEncoding) {
      // Some ancestor is the encoding root so we don't need to do the
      // bookkeeping again.
      return performEncodeTo(encoder);
    }

    // This object is the encoding root and needs to keep track of whether
    // encoding is ongoing.

    _isEncoding = true;

    try {
      final result = performEncodeTo(encoder);

      if (result is Future) {
        return result.whenComplete(() => _isEncoding = false);
      } else {
        _isEncoding = false;
      }
    } catch (e) {
      _isEncoding = false;
      rethrow;
    }
  }

  FutureOr<void> performEncodeTo(FleeceEncoder encoder);

  @protected
  void mutate() {
    // TODO: should this always throw, not just in debug mode?
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

    final parentContext = parent?.context;

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
    if (context == null || _context == context) return;

    assert(
      _context == null || _context == context,
      'once set the context of a MCollection cannot change',
    );

    _context = context;

    // Propagate context to children.
    values.forEach((value) => value.updateParent(this));
  }
}
