// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../encoder.dart';
import 'collection.dart';
import 'delegate.dart';

MDelegate get _delegate => MDelegate.instance!;

class MValue {
  MValue(Pointer<FLValue>? value, Object? native, {required bool hasNative})
      : assert(hasNative || native == null),
        _value = value,
        _hasNative = hasNative,
        _native = native;

  MValue.empty() : this(null, null, hasNative: false);

  MValue.withValue(Pointer<FLValue> value)
      : this(value, null, hasNative: false);

  MValue.withNative(Object? native) : this(null, native, hasNative: true);

  bool get isEmpty => !hasValue && !hasNative;

  bool get isNotEmpty => !isEmpty;

  bool get isMutated => !hasValue;

  bool get hasValue => _value != null;

  Pointer<FLValue>? get value => _value;
  Pointer<FLValue>? _value;

  bool get hasNative => _hasNative;
  bool _hasNative;
  Object? _native;

  Object? asNative(MCollection parent) {
    assert(!isEmpty);

    if (hasNative) {
      return _native;
    } else {
      var cacheIt = false;
      final native = _delegate.toNative(this, parent, () => cacheIt = true);

      // We keep the data owner alive while toNative is running, so that
      // implementations can safely use _value.
      cblReachabilityFence(parent.dataOwner);

      if (cacheIt) {
        _native = native;
        _hasNative = true;
      }
      return native;
    }
  }

  void setNative(Object? native, MCollection parent) =>
      _setNative(native, parent: parent, hasNative: true);

  void setEmpty(MCollection parent) {
    if (isEmpty) {
      return;
    }
    _value = null;
    _setNative(null, parent: parent, hasNative: false);
  }

  void mutate() {
    _value = null;
  }

  void updateParent(MCollection parent) => _updateNativeParent(this, parent);

  void removeFromParent() => _updateNativeParent(null, null);

  FutureOr<void> encodeTo(FleeceEncoder encoder) {
    assert(!isEmpty);

    final value = _value;
    if (value != null) {
      encoder.writeValue(value);
    } else {
      return _delegate.encodeNative(encoder, _native);
    }
  }

  MValue clone() => MValue(_value, _native, hasNative: _hasNative);

  void _setNative(
    Object? native, {
    required MCollection parent,
    required bool hasNative,
  }) {
    assert(
      hasNative || native == null,
      'native must be null when hasNative is false',
    );

    if (_native == native && _hasNative == hasNative) {
      return;
    }

    // Update parent of old native value
    _updateNativeParent(null, null);

    _hasNative = hasNative;
    _native = native;
    mutate();

    // Update parent of new native value
    _updateNativeParent(this, parent);
  }

  void _updateNativeParent(MValue? slot, MCollection? parent) {
    if (!_hasNative) {
      return;
    }
    _delegate.collectionFromNative(_native)?.updateParent(slot, parent);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MValue &&
          runtimeType == other.runtimeType &&
          _value == other._value &&
          _hasNative == other._hasNative &&
          _native == other._native;

  @override
  int get hashCode => _value.hashCode ^ _hasNative.hashCode ^ _native.hashCode;

  @override
  String toString() => 'MValue('
      'hasValue: $hasValue, '
      'hasNative: $hasNative, '
      'value: $_value, '
      // ignore: missing_whitespace_between_adjacent_strings
      'native: $_native'
      ')';
}
