// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
import 'dart:async';

import '../../bindings.dart';
import '../encoder.dart';
import 'collection.dart';
import 'delegate.dart';

MDelegate get _delegate => MDelegate.instance!;

final _emptyNative = Object();

base class MValue {
  MValue.empty() : _value = null, _native = _emptyNative;

  MValue.withValue(FLValue value) : _value = value, _native = _emptyNative;

  MValue.withNative(Object? native) : _value = null, _native = native;

  MValue._(FLValue? value, Object? native) : _value = value, _native = native;

  FLValue? _value;
  Object? _native;

  bool get isEmpty => !hasValue && !hasNative;

  bool get isNotEmpty => !isEmpty;

  bool get isMutated => !hasValue;

  bool get hasValue => _value != null;

  FLValue? get value => _value;

  bool get hasNative => !identical(_native, _emptyNative);

  Object? asNative(MCollection parent) {
    assert(!isEmpty);

    if (hasNative) {
      return _native;
    } else {
      var cacheIt = false;
      final native = _delegate.toNative(this, parent, () => cacheIt = true);

      // We keep the context alive while toNative is running, so that
      // implementations can safely use _value.
      cblReachabilityFence(parent.context);

      if (cacheIt) {
        _native = native;
      }
      return native;
    }
  }

  void setNative(Object? native, MCollection parent) {
    _setNative(native, parent, hasNative: true);
    _value = null;

    if (_delegate.isExternalData(native)) {
      parent.markNeedsToSaveExternalData();
    }
  }

  void setEmpty() {
    if (isEmpty) {
      return;
    }
    _setNative(null, null, hasNative: false);
    _value = null;
  }

  void markMutated() {
    _value = null;
  }

  void updateParent(MCollection parent) => _nativeChangeSlot(this, parent);

  void removeFromParent() => _nativeChangeSlot(null, null);

  FutureOr<void> saveExternalData(Object context) {
    if (hasNative && isMutated) {
      final native = _native;

      if (_delegate.collectionFromNative(native) case final collection?) {
        return collection.saveExternalData(context);
      }

      if (_delegate.isExternalData(native)) {
        return _delegate.saveExternalData(native, context);
      }
    }
  }

  void encodeTo(FleeceEncoder encoder) {
    assert(!isEmpty);

    final value = _value;
    if (value != null) {
      encoder.writeValue(value);
    } else {
      _delegate.encodeNative(encoder, _native);
    }
  }

  MValue clone() => MValue._(_value, _native);

  void _setNative(
    Object? native,
    MCollection? parent, {
    required bool hasNative,
  }) {
    assert(
      hasNative || native == null,
      'native must be null when hasNative is false',
    );

    if (hasNative) {
      if (_native != native) {
        _nativeChangeSlot(null, null);
        _native = native;
        _nativeChangeSlot(this, parent);
      }
    } else if (this.hasNative) {
      _nativeChangeSlot(null, null);
      _native = _emptyNative;
    }
  }

  void _nativeChangeSlot(MValue? slot, MCollection? parent) {
    if (!hasNative) {
      return;
    }
    _delegate.collectionFromNative(_native)?.setSlot(slot, this, parent);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MValue &&
          runtimeType == other.runtimeType &&
          _value == other._value &&
          _native == other._native;

  @override
  int get hashCode => _value.hashCode ^ _native.hashCode;

  @override
  String toString() =>
      'MValue('
      'hasValue: $hasValue, '
      'hasNative: $hasNative, '
      'value: $_value, '
      // ignore: missing_whitespace_between_adjacent_strings
      'native: $_native'
      ')';
}
