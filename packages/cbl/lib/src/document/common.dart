import 'dart:async';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../fleece/decoder.dart';
import '../fleece/encoder.dart';
import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../support/ffi.dart';
import 'array.dart';
import 'blob.dart';
import 'dictionary.dart';

late final _blobBindings = cblBindings.blobs.blob;

abstract class CblConversions {
  Object? toPlainObject();
  Object? toCblObject();

  static Object? convertToPlainObject(Object? object) {
    if (object is CblConversions) {
      return object.toPlainObject();
    }
    return const _DefaultCblConversions().toPlainObject(object);
  }

  static Object? convertToCblObject(Object? object) {
    if (object is CblConversions) {
      return object.toCblObject();
    }
    return const _DefaultCblConversions().toCblObject(object);
  }
}

class _DefaultCblConversions implements CblConversions {
  const _DefaultCblConversions();

  @override
  Object? toCblObject([Object? object]) {
    // The order in which `object` is checked for the different types attempts
    // to anticipate which types of objects are used most often, to minimize
    // the number of executed checks.
    if (object is String || object is num || object is bool || object == null) {
      return object;
    }

    if (object is Map<String, Object?>) {
      if (Blob.isBlob(object)) {
        return BlobImpl.fromProperties(object);
      }
      return MutableDictionary(object);
    }

    if (object is Iterable<Object?>) {
      return MutableArray(object);
    }

    if (object is DateTime) {
      return object.toIso8601String();
    }

    if (object is Uint8List) {
      return Blob.fromData('application/octet-stream', object);
    }

    throw ArgumentError.value(
      object,
      'object',
      'cannot be stored in a Couchbase Lite Document',
    );
  }

  @override
  Object? toPlainObject([Object? object]) => object;
}

abstract class FleeceEncodable {
  FutureOr<void> encodeTo(FleeceEncoder encoder);
}

class FleeceEncoderContext {
  FleeceEncoderContext({
    this.database,
    this.encodeQueryParameter = false,
  });

  final Object? database;

  final bool encodeQueryParameter;
}

abstract class MCollectionWrapper {
  MCollection get mCollection;
}

class DatabaseMContext extends MContext {
  DatabaseMContext(this.database);

  final Object database;
}

class CblMDelegate extends MDelegate {
  @override
  MCollection? collectionFromNative(Object? native) {
    if (native is MCollectionWrapper) {
      return native.mCollection;
    }
  }

  @override
  FutureOr<void> encodeNative(FleeceEncoder encoder, Object? native) {
    if (native == null ||
        native is String ||
        native is num ||
        native is bool ||
        native is Uint8List) {
      encoder.writeDartObject(native);
    } else if (native is DateTime) {
      encoder.writeString(native.toIso8601String());
    } else if (native is FleeceEncodable) {
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
    final flValue = value.value;
    if (flValue is SimpleFLValue) {
      return flValue.value;
    } else if (flValue is SliceFLValue) {
      cacheIt();
      return flValue.isString
          ? flValue.slice.toDartString()
          : SliceResult.fromSlice(flValue.slice).asUint8List();
    } else if (flValue is CollectionFLValue) {
      cacheIt();
      if (flValue.isArray) {
        final array = MArray.asChild(value, parent);
        if (parent.hasMutableChildren) {
          return MutableArrayImpl(array);
        } else {
          return ArrayImpl(array);
        }
      } else {
        if (_blobBindings.isBlob(flValue.value.cast())) {
          final context = parent.context;
          Object? database;
          if (context is DatabaseMContext) {
            database = context.database;
          }

          final dict = fl.Dict.fromPointer(
            flValue.value.cast(),
            // This value is alive as long as the MRoot is alive and the
            // MRoot does not necessarily read form a Doc.
            isRefCounted: false,
          );
          return BlobImpl.fromProperties(dict.toObject(), database: database);
        }
        final dictionary = MDict.asChild(value, parent);
        if (parent.hasMutableChildren) {
          return MutableDictionaryImpl(dictionary);
        } else {
          return DictionaryImpl(dictionary);
        }
      }
    }

    throw ArgumentError.value(
      value,
      'value',
      'unable to create corresponding native value',
    );
  }
}

bool valueWouldChange(
  Object? newValue,
  MValue? oldValue,
  MCollection container,
) {
  // If `oldValue` is null it was undefined.
  if (oldValue == null) {
    return true;
  }

  // Collection values are assumed to result in a change to skip expensive
  // comparisons of large instances.
  if (oldValue.value is CollectionFLValue) {
    return false;
  }
  if (newValue is Array || newValue is Dictionary) {
    return true;
  }

  return newValue != oldValue.asNative(container);
}

@pragma('vm:prefer-inline')
T? coerceObject<T>(Object? object) {
  if (object is T) {
    return object;
  }
  if (T == bool) {
    if (object == null) {
      return false as T;
    }
    if (object is num) {
      return (object.toInt() != 0) as T;
    }
    return true as T;
  }
  if (T == int) {
    if (object is num) {
      return object.toInt() as T;
    }
  }
  if (T == double) {
    if (object is num) {
      return object.toDouble() as T;
    }
  }
  if (T == DateTime) {
    if (object is String) {
      return DateTime.parse(object) as T;
    }
  }
}
