import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import '../../bindings.dart';
import '../../document/common.dart' show CblMDelegate;
import '../encoder.dart';
import 'array.dart';
import 'collection.dart';
import 'dict.dart';
import 'value.dart';

abstract base class MDelegate {
  static MDelegate instance = CblMDelegate();

  MCollection? collectionFromNative(Object? native);

  Object? toNative(MValue value, MCollection parent, void Function() cacheIt);

  bool isExternalData(Object? native);

  FutureOr<void> saveExternalData(Object? native, Object? context);

  void encodeNative(FleeceEncoder encoder, Object? native);
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
  Object? toNative(MValue value, MCollection parent, void Function() cacheIt) {
    FleeceDecoderBindings.getLoadedValue(value.value!);

    final flValue = globalLoadedFLValue.ref;
    switch (FLValueType.fromValue(flValue.type)) {
      case .undefined:
      case .null$:
        return null;
      case .boolean:
        return flValue.asBool;
      case .number:
        return flValue.isInteger ? flValue.asInt : flValue.asDouble;
      case .string:
        cacheIt();
        return parent.context.sharedStringsTable.decode(.value);
      case .data:
        cacheIt();
        return flValue.asData.toData()?.toTypedList();
      case .array:
        cacheIt();
        return MArray.asChild(value, parent, flValue.collectionSize);
      case .dict:
        cacheIt();
        return MDict.asChild(value, parent, flValue.collectionSize);
    }
  }

  @override
  bool isExternalData(Object? native) => false;

  @override
  FutureOr<void> saveExternalData(Object? native, Object? context) {}

  @override
  void encodeNative(FleeceEncoder encoder, Object? native) {
    if (native == null ||
        native is String ||
        native is num ||
        native is bool ||
        native is TypedData) {
      encoder.writeDartObject(native);
    } else if (native is MCollection) {
      native.encodeTo(encoder);
    } else {
      throw ArgumentError.value(
        native,
        'native',
        'is not a value of a recognized native type',
      );
    }
  }
}
