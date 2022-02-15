import 'dart:async';
import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../support/ffi.dart';
import '../../support/native_object.dart';
import '../encoder.dart';
import 'collection.dart';
import 'context.dart';
import 'value.dart';

late final _valueBinds = cblBindings.fleece.value;

class MRoot extends MCollection {
  MRoot.fromData(
    Data data, {
    required MContext context,
    required bool isMutable,
  })  : data = data.toSliceResult(),
        value = null,
        super(context: context, isMutable: isMutable) {
    _slot =
        MValue.withValue(_valueBinds.fromData(this.data!, FLTrust.trusted)!);
    _slot.updateParent(this);
  }

  MRoot.fromValue(
    Pointer<FLValue> value, {
    required MContext context,
    required bool isMutable,
  })  : data = null,
        value = FleeceValueObject(value, isRefCounted: true, adopt: false),
        _slot = MValue.withValue(value),
        super(context: context, isMutable: isMutable) {
    _slot.updateParent(this);
  }

  MRoot.fromMValue(
    MValue value, {
    required MContext context,
    required bool isMutable,
  })  : data = null,
        value = null,
        _slot = value,
        super(context: context, isMutable: isMutable) {
    _slot.updateParent(this);
  }

  final SliceResult? data;

  final FleeceValueObject<FLValue>? value;

  late final MValue _slot;

  @override
  MContext get context => super.context!;

  @override
  bool get isMutated => _slot.isMutated;

  @override
  Iterable<MValue> get values => [_slot];

  @override
  FutureOr<void> performEncodeTo(FleeceEncoder encoder) =>
      _slot.encodeTo(encoder);

  Object? get asNative => _slot.asNative(this);

  Data encode() {
    final encoder = FleeceEncoder();
    final result = encodeTo(encoder);
    assert(result is! Future);
    return encoder.finish();
  }
}
