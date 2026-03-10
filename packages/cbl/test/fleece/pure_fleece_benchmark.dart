// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:cbl/src/bindings/data.dart';
import 'package:cbl/src/fleece/containers.dart';
import 'package:cbl/src/fleece/decoder.dart' as ffi_decoder;
import 'package:cbl/src/fleece/encoder.dart';
import 'package:cbl/src/fleece/pure_fleece.dart';

// ============================================================================
// Test data generators
// ============================================================================

/// A small document similar to what a typical app might store.
Map<String, Object?> smallDocument() => {
  'id': 'user-12345',
  'name': 'Alice Johnson',
  'email': 'alice@example.com',
  'age': 32,
  'active': true,
  'score': 98.6,
  'tags': ['admin', 'premium', 'beta'],
  'address': {
    'street': '123 Main St',
    'city': 'Springfield',
    'state': 'IL',
    'zip': '62704',
  },
};

/// A medium document with repeated structures (e.g., a list of records).
Map<String, Object?> mediumDocument() => {
  'type': 'order',
  'orderId': 'ORD-2024-98765',
  'customer': smallDocument(),
  'items': List.generate(
    20,
    (i) => {
      'sku': 'ITEM-${i.toString().padLeft(4, '0')}',
      'name': 'Product $i',
      'quantity': i + 1,
      'price': 9.99 + i * 1.5,
      'inStock': i % 3 != 0,
    },
  ),
  'totals': {
    'subtotal': 450.50,
    'tax': 36.04,
    'shipping': 12.99,
    'total': 499.53,
  },
  'notes': null,
};

/// A large document with deeply nested and wide structures.
Map<String, Object?> largeDocument() => {
  'type': 'catalog',
  'version': 3,
  'categories': List.generate(
    10,
    (c) => {
      'id': 'cat-$c',
      'name': 'Category $c',
      'products': List.generate(
        20,
        (p) => {
          'id': 'prod-$c-$p',
          'name': 'Product $p in Category $c',
          'description':
              'A longer description for product $p that contains '
              'more text to exercise string encoding paths.',
          'price': 19.99 + p * 2.5,
          'rating': (p % 5) + 1,
          'reviews': p * 3,
          'available': p % 4 != 0,
          'attributes': {
            'color': ['red', 'blue', 'green'][p % 3],
            'size': ['S', 'M', 'L', 'XL'][p % 4],
            'weight': 0.5 + p * 0.1,
          },
        },
      ),
    },
  ),
};

// ============================================================================
// Benchmark helpers
// ============================================================================

typedef BenchmarkFn = void Function();

class BenchmarkResult {
  BenchmarkResult(this.name, this.opsPerSecond, this.avgMicroseconds);

  final String name;
  final double opsPerSecond;
  final double avgMicroseconds;

  @override
  String toString() =>
      '  $name: ${opsPerSecond.toStringAsFixed(0)} ops/s '
      '(${avgMicroseconds.toStringAsFixed(1)} µs/op)';
}

BenchmarkResult benchmark(String name, BenchmarkFn fn, {int warmUp = 100}) {
  // Warm up.
  for (var i = 0; i < warmUp; i++) {
    fn();
  }

  // Run for at least 2 seconds.
  const minDuration = Duration(seconds: 2);
  var iterations = 0;
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < minDuration) {
    fn();
    iterations++;
  }
  stopwatch.stop();

  final totalMicroseconds = stopwatch.elapsedMicroseconds;
  final avgMicroseconds = totalMicroseconds / iterations;
  final opsPerSecond = iterations / (totalMicroseconds / 1000000);

  return BenchmarkResult(name, opsPerSecond, avgMicroseconds);
}

void printComparison(
  String label,
  BenchmarkResult pureDart,
  BenchmarkResult nativeC,
) {
  final ratio = pureDart.opsPerSecond / nativeC.opsPerSecond;
  print('--- $label ---');
  print(pureDart);
  print(nativeC);
  print(
    '  Ratio (pure/native): ${ratio.toStringAsFixed(2)}x '
    '(${ratio > 1 ? "pure Dart faster" : "native faster"})',
  );
  print('');
}

// ============================================================================
// Encoding benchmarks
// ============================================================================

BenchmarkResult benchmarkPureEncode(String label, Map<String, Object?> doc) =>
    benchmark('Pure Dart encode ($label)', () {
      PureFleeceEncoder().encodeDartObject(doc);
    });

BenchmarkResult benchmarkNativeEncode(String label, Map<String, Object?> doc) =>
    benchmark('Native C encode  ($label)', () {
      FleeceEncoder().convertDartObject(doc);
    });

// ============================================================================
// Decoding benchmarks
// ============================================================================

BenchmarkResult benchmarkPureDecode(String label, Uint8List bytes) =>
    benchmark('Pure Dart decode ($label)', () {
      FleeceDecoder(bytes).root.toObject();
    });

BenchmarkResult benchmarkPureVisitInternal(String label, Uint8List bytes) =>
    benchmark('Pure visit (internal) ($label)', () {
      FleeceDecoder(bytes).root.visit();
    });

/// Visit using the public FleeceValue/FleeceArray/FleeceDict API, which
/// provides the same dynamic navigation capability as the C API.
int _visitValue(FleeceValue val) {
  switch (val.type) {
    case FleeceValueType.null_:
    case FleeceValueType.undefined:
      return 0;
    case FleeceValueType.bool_:
      return val.asBool ? 1 : 0;
    case FleeceValueType.int_:
      return val.asInt;
    case FleeceValueType.double_:
      return val.asDouble.toInt();
    case FleeceValueType.string:
      return val.asString.length;
    case FleeceValueType.data:
      return val.asData.length;
    case FleeceValueType.array:
      final arr = val.asArray;
      var sink = 0;
      for (var i = 0; i < arr.length; i++) {
        sink += _visitValue(arr[i]);
      }
      return sink;
    case FleeceValueType.dict:
      final dict = val.asDict;
      var sink = 0;
      final keys = dict.keys;
      for (final key in keys) {
        sink += key.length;
      }
      // Visit values by iterating again (mirrors C pattern of
      // FLDictIterator_GetValue).
      // We use keys to look up values, similar to the C API's FLDict_Get.
      for (final key in keys) {
        final v = dict[key];
        if (v != null) {
          sink += _visitValue(v);
        }
      }
      return sink;
  }
}

BenchmarkResult benchmarkPureVisitApi(String label, Uint8List bytes) =>
    benchmark('Pure visit (API)     ($label)', () {
      _visitValue(FleeceDecoder(bytes).root);
    });

/// Visit using the zero-allocation extension type API (FV/FA/FD). Uses forEach
/// for iteration (mirrors C's iterator pattern).
int _visitFV(FV val) {
  switch (val.type) {
    case FleeceValueType.null_:
    case FleeceValueType.undefined:
      return 0;
    case FleeceValueType.bool_:
      return val.asBool ? 1 : 0;
    case FleeceValueType.int_:
      return val.asInt;
    case FleeceValueType.double_:
      return val.asDouble.toInt();
    case FleeceValueType.string:
      return val.asString.length;
    case FleeceValueType.data:
      return val.asData.length;
    case FleeceValueType.array:
      var sink = 0;
      val.asArray.forEach((v) {
        sink += _visitFV(v);
      });
      return sink;
    case FleeceValueType.dict:
      var sink = 0;
      val.asDict.forEach((key, value) {
        sink += key.length;
        sink += _visitFV(value);
      });
      return sink;
  }
}

BenchmarkResult benchmarkPureVisitExtType(String label, Uint8List bytes) {
  final decoder = FleeceDecoder(bytes);
  return benchmark('Pure visit (ext type) ($label)', () {
    runWithFleeceDecoder(decoder, () {
      _visitFV(decoder.rootFV);
    });
  });
}

BenchmarkResult benchmarkNativeDecode(String label, Uint8List bytes) =>
    benchmark('Native naive     ($label)', () {
      Doc.fromResultData(
        Data.fromTypedList(bytes),
        FLTrust.trusted,
      ).root.toObject();
    });

BenchmarkResult benchmarkListenerDecode(String label, Uint8List bytes) =>
    benchmark('Native listener  ($label)', () {
      const ffi_decoder.FleeceDecoder(
        trust: FLTrust.trusted,
      ).convert(Data.fromTypedList(bytes));
    });

// ignore: deprecated_member_use
BenchmarkResult benchmarkRecursiveDecode(String label, Uint8List bytes) =>
    // ignore: deprecated_member_use
    benchmark('Native recursive ($label)', () {
      // ignore: deprecated_member_use
      ffi_decoder.RecursiveFleeceDecoder(
        trust: FLTrust.trusted,
      ).convert(Data.fromTypedList(bytes));
    });

// ============================================================================
// Field access benchmarks
// ============================================================================

BenchmarkResult benchmarkPureFieldAccess(
  String label,
  Uint8List bytes,
  List<String> keys,
) => benchmark('Pure Dart field access ($label)', () {
  final dict = FleeceDecoder(bytes).root.asDict;
  for (final key in keys) {
    // ignore: unnecessary_statements
    dict[key];
  }
});

BenchmarkResult benchmarkNativeFieldAccess(
  String label,
  Uint8List bytes,
  List<String> keys,
) => benchmark('Native C field access  ($label)', () {
  final doc = Doc.fromResultData(Data.fromTypedList(bytes), FLTrust.trusted);
  final dict = doc.root.asDict!;
  for (final key in keys) {
    // ignore: unnecessary_statements
    dict[key];
  }
});

// ============================================================================
// Main
// ============================================================================

void main() {
  final docs = {
    'small': smallDocument(),
    'medium': mediumDocument(),
    'large': largeDocument(),
  };

  print('=== Fleece Benchmark: Pure Dart vs Native C ===');
  print('');

  // --- Encoding ---
  print('========== ENCODING ==========');
  print('');
  for (final entry in docs.entries) {
    final pureResult = benchmarkPureEncode(entry.key, entry.value);
    final nativeResult = benchmarkNativeEncode(entry.key, entry.value);
    printComparison('Encode ${entry.key}', pureResult, nativeResult);
  }

  // --- Decoding ---
  print('========== DECODING ==========');
  print('');
  // Pre-encode documents using native encoder for fair comparison.
  final encodedDocs = docs.map(
    (key, value) =>
        MapEntry(key, FleeceEncoder().convertDartObject(value).toTypedList()),
  );

  for (final entry in encodedDocs.entries) {
    final pureVisitInternal = benchmarkPureVisitInternal(
      entry.key,
      entry.value,
    );
    final pureVisitApi = benchmarkPureVisitApi(entry.key, entry.value);
    final pureVisitExtType = benchmarkPureVisitExtType(entry.key, entry.value);
    final pureResult = benchmarkPureDecode(entry.key, entry.value);
    final naiveResult = benchmarkNativeDecode(entry.key, entry.value);
    final listenerResult = benchmarkListenerDecode(entry.key, entry.value);
    final recursiveResult = benchmarkRecursiveDecode(entry.key, entry.value);
    print('--- Decode ${entry.key} ---');
    print(pureVisitInternal);
    print(pureVisitApi);
    print(pureVisitExtType);
    print(pureResult);
    print(naiveResult);
    print(listenerResult);
    print(recursiveResult);
    final best = [
      naiveResult,
      listenerResult,
      recursiveResult,
    ].reduce((a, b) => a.opsPerSecond > b.opsPerSecond ? a : b);
    final ratio = pureResult.opsPerSecond / best.opsPerSecond;
    print(
      '  Pure vs best native: ${ratio.toStringAsFixed(2)}x '
      '(${ratio > 1 ? "pure Dart faster" : "native faster"})',
    );
    print('');
  }

  // --- Field Access ---
  print('========== FIELD ACCESS ==========');
  print('');

  // Small document: access all top-level keys.
  final smallKeys = smallDocument().keys.toList();
  final smallBytes = encodedDocs['small']!;
  printComparison(
    'Field access small (${smallKeys.length} keys)',
    benchmarkPureFieldAccess('small', smallBytes, smallKeys),
    benchmarkNativeFieldAccess('small', smallBytes, smallKeys),
  );

  // Medium document: access a few keys including nested.
  final mediumKeys = ['type', 'orderId', 'customer', 'items', 'totals'];
  final mediumBytes = encodedDocs['medium']!;
  printComparison(
    'Field access medium (${mediumKeys.length} keys)',
    benchmarkPureFieldAccess('medium', mediumBytes, mediumKeys),
    benchmarkNativeFieldAccess('medium', mediumBytes, mediumKeys),
  );
}
