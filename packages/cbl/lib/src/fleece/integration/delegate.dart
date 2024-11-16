import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import '../../bindings.dart';
import '../../support/ffi.dart';
import '../decoder.dart';
import '../encoder.dart';
import 'array.dart';
import 'collection.dart';
import 'dict.dart';
import 'value.dart';

final _decoderBinds = cblBindings.fleece.decoder;

abstract base class MDelegate {
  static MDelegate? instance;

  MCollection? collectionFromNative(Object? native);

  Object? toNative(MValue value, MCollection parent, void Function() cacheIt);

  FutureOr<void> encodeNative(FleeceEncoder encoder, Object? native);
}

final class SimpleMDelegate extends MDelegate {
  @override
  MCollection? collectionFromNative(Object? native) {
    if (native is MCollection) {
      return native;
    }
    return null;
  }

  @override
  FutureOr<void> encodeNative(FleeceEncoder encoder, Object? native) {
    if (native == null ||
        native is String ||
        native is num ||
        native is bool ||
        native is TypedData) {
      encoder.writeDartObject(native);
    } else if (native is MCollection) {
      return native.encodeTo(encoder);
    } else {
      throw ArgumentError.value(
        native,
        'native',
        'is not a value of a recognized native type',
      );
    }
  }

  @override
  Object? toNative(MValue value, MCollection parent, void Function() cacheIt) {
    _decoderBinds.getLoadedValue(value.value!);

    final flValue = globalLoadedFLValue.ref;
    switch (FLValueType.fromValue(flValue.type)) {
      case FLValueType.kFLUndefined:
      case FLValueType.kFLNull:
        return null;
      case FLValueType.kFLBoolean:
        return flValue.asBool;
      case FLValueType.kFLNumber:
        return flValue.isInteger ? flValue.asInt : flValue.asDouble;
      case FLValueType.kFLString:
        cacheIt();
        return parent.context.sharedStringsTable.decode(StringSource.value);
      case FLValueType.kFLData:
        cacheIt();
        return flValue.asData.toData()?.toTypedList();
      case FLValueType.kFLArray:
        cacheIt();
        return MArray.asChild(value, parent, flValue.collectionSize);
      case FLValueType.kFLDict:
        cacheIt();
        return MDict.asChild(value, parent, flValue.collectionSize);
    }
  }
}
