import 'dart:async';

import 'package:cbl/src/support/utils.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../test_binding.dart';

typedef VariantIsCompatible<T> = bool Function(
  T value,
  TestVariant other,
  Object? otherValue,
);

class TestVariant<T extends Object?> {
  const TestVariant(
    this.name, {
    required this.values,
    VariantIsCompatible<T>? isCompatible,
    this.order = 0,
  }) : _isCompatible = isCompatible;

  final String name;

  final VariantIsCompatible<T>? _isCompatible;

  final int order;

  final List<T> values;

  T get value => _variantTestConfiguration.getVariantValue(this);

  bool isCompatibleWith(T value, TestVariant other, Object? otherValue) =>
      _isCompatible?.call(value, other, otherValue) ?? true;

  String describeValue(T value) => value.toString();

  String describe(T value) => '$name: ${describeValue(value)}';

  @override
  String toString() => 'TestVariant($name)';
}

class EnumVariant<T extends Enum> extends TestVariant<T> {
  EnumVariant(
    List<T> values, {
    String? name,
    VariantIsCompatible<T>? isCompatible,
    int order = 0,
  })  : assert(values.isNotEmpty),
        super(
          name ??
              enumName(values.first).replaceAllMapped(
                RegExp('^.'),
                (match) => match.group(0)!.toLowerCase(),
              ),
          values: values,
          isCompatible: isCompatible,
          order: order,
        );

  @override
  String describeValue(T value) => value.name;
}

@isTest
void variantTest(
  String description,
  FutureOr<void> Function() body, {
  required List<TestVariant> variants,
}) {
  for (final combination in _VariantEntry.combinations(variants)) {
    final config = _VariantConfiguration(combination);
    test(
      '$description (variant: ${config.describeVariants()})',
      () => _runWithVariants(body, config: config),
    );
  }
}

Future<void> runVariantCombinations(
  FutureOr<void> Function() body, {
  required List<TestVariant> variants,
}) async {
  for (final combination in _VariantEntry.combinations(variants)) {
    final config = _VariantConfiguration(combination);
    await _runWithVariants(body, config: config);
  }
}

class _VariantConfiguration {
  _VariantConfiguration(this.combination);

  final List<_VariantEntry> combination;

  T getVariantValue<T>(TestVariant<T> variant) {
    final entry =
        combination.firstWhereOrNull((element) => element.variant == variant);

    if (entry == null) {
      throw ArgumentError.value(variant, 'variant', 'has not value');
    }

    return entry.value as T;
  }

  String describeVariants() => combination
      .map((entry) => entry.variant.describe(entry.value))
      .join(', ');
}

_VariantConfiguration get _variantTestConfiguration =>
    Zone.current[#variantTestConfiguration]! as _VariantConfiguration;

class _VariantEntry {
  const _VariantEntry(this.variant, this.value);

  static List<_VariantEntry> variantEntries(TestVariant variant) =>
      variant.values.map((value) => _VariantEntry(variant, value)).toList();

  static List<List<_VariantEntry>> combinations(List<TestVariant> variants) {
    assert(variants.isNotEmpty);

    List<List<_VariantEntry>> generateCombinations(
      List<TestVariant> variants,
    ) {
      assert(variants.isNotEmpty);

      final entries = variantEntries(variants.first);

      if (variants.length == 1) {
        return [
          for (final entry in entries) [entry]
        ];
      }

      final combinations = generateCombinations(variants.sublist(1));

      return entries
          .expand((entry) => combinations
              .where((combination) => combination.every(entry.isCompatibleWith))
              .map((combination) => [entry, ...combination]))
          .toList();
    }

    return generateCombinations(variants..sort(_variantOrder));
  }

  bool isCompatibleWith(_VariantEntry other) =>
      variant.isCompatibleWith(value, other.variant, other.value) &&
      other.variant.isCompatibleWith(other.value, variant, value);

  final TestVariant variant;

  final Object? value;

  @override
  String toString() => variant.describe(value);
}

int _variantOrder(TestVariant a, TestVariant b) {
  final orderComparison = b.order - a.order;
  if (orderComparison != 0) {
    return orderComparison;
  }

  return a.name.compareTo(b.name);
}

T _runWithVariants<T>(
  T Function() fn, {
  required _VariantConfiguration config,
}) =>
    runZoned(fn, zoneValues: {#variantTestConfiguration: config});
