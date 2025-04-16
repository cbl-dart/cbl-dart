import 'dart:math';

import 'package:collection/collection.dart';

typedef StatisticFunction = double Function(List<double> values);

double median(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'values', 'must not be empty');
  }
  final sorted = List.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted[middle];
}

double average(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'values', 'must not be empty');
  }
  return values.reduce((a, b) => a + b) / values.length;
}

double throughput(int operations, Duration duration) =>
    operations / (duration.inMicroseconds / Duration.microsecondsPerSecond);

class Measure {
  Measure({
    required this.name,
    required this.value,
    this.upperValue,
    this.lowerValue,
  });

  Measure.fromJson(Map<String, Object?> json)
      : name = json['name']! as String,
        value = (json['value']! as num).toDouble(),
        upperValue = (json['upper_value'] as num?)?.toDouble(),
        lowerValue = (json['lower_value'] as num?)?.toDouble();

  factory Measure.combined(
    List<Measure> measures, {
    required StatisticFunction statistic,
  }) {
    final names = measures.map((measure) => measure.name).toSet();
    if (names.length != 1) {
      throw ArgumentError('Cannot combine different named measures');
    }

    final values = measures.map((measure) => measure.value).toList();

    final upperValues = measures
        .map((measure) => measure.upperValue)
        .whereType<double>()
        .toList();

    if (upperValues.isNotEmpty && upperValues.length != measures.length) {
      throw ArgumentError(
        'Cannot combine measures because not all have upperValue',
      );
    }

    final lowerValues = measures
        .map((measure) => measure.lowerValue)
        .whereType<double>()
        .toList();

    if (lowerValues.isNotEmpty && lowerValues.length != measures.length) {
      throw ArgumentError(
        'Cannot combine measures because not all have lowerValue',
      );
    }

    return Measure(
      name: measures.first.name,
      value: statistic(values),
      upperValue: upperValues.isNotEmpty ? statistic(upperValues) : null,
      lowerValue: lowerValues.isNotEmpty ? statistic(lowerValues) : null,
    );
  }

  factory Measure.combinedLatency(
    List<Duration> latencies, {
    required StatisticFunction statistic,
  }) {
    final latenciesInNanoseconds =
        latencies.map((duration) => duration.inMicroseconds * 1000.0).toList();
    return Measure(
      name: 'latency',
      value: statistic(latenciesInNanoseconds),
      upperValue: latenciesInNanoseconds.reduce(max),
      lowerValue: latenciesInNanoseconds.reduce(min),
    );
  }

  factory Measure.throughput({
    required int operations,
    required Duration totalDuration,
  }) =>
      Measure(
        name: 'throughput',
        value: throughput(operations, totalDuration),
      );

  final String name;
  final double value;
  final double? upperValue;
  final double? lowerValue;

  Map<String, Object?> toJson() => {
        'name': name,
        'value': value,
        if (upperValue != null) 'upper_value': upperValue,
        if (lowerValue != null) 'lower_value': lowerValue,
      };
}

class BenchmarkResult {
  BenchmarkResult({required this.measures});

  BenchmarkResult.fromJson(Map<String, Object?> json)
      : measures = (json.entries
            .map((entry) =>
                Measure.fromJson(entry.value! as Map<String, Object?>))
            .toList());

  factory BenchmarkResult.combine(
    List<BenchmarkResult> results, {
    required StatisticFunction statistic,
  }) =>
      BenchmarkResult(
        measures: results
            .expand((result) => result.measures)
            .groupListsBy((measure) => measure.name)
            .values
            .map((measures) => Measure.combined(measures, statistic: statistic))
            .toList(),
      );

  factory BenchmarkResult.workload({
    required List<Duration> latencies,
    required StatisticFunction latencyStatistic,
    required Duration totalDuration,
  }) =>
      BenchmarkResult(measures: [
        Measure.combinedLatency(latencies, statistic: latencyStatistic),
        Measure.throughput(
          operations: latencies.length,
          totalDuration: totalDuration,
        )
      ]);

  final List<Measure> measures;

  Map<String, Object?> toJson() => {
        for (final measure in measures) measure.name: measure.toJson(),
      };
}

class BenchmarkResults {
  BenchmarkResults([this.results = const {}]);

  factory BenchmarkResults.combine(
    List<BenchmarkResults> results, {
    required StatisticFunction statistic,
  }) =>
      BenchmarkResults(
        results
            .expand((result) => result.results.entries)
            .groupListsBy((entry) => entry.key)
            .map((key, entry) => MapEntry(
                  key,
                  BenchmarkResult.combine(
                    entry.map((entry) => entry.value).toList(),
                    statistic: statistic,
                  ),
                )),
      );

  BenchmarkResults.fromJson(Map<String, Object?> json)
      : results = json.map((key, value) => MapEntry(
              key,
              BenchmarkResult.fromJson(value! as Map<String, Object?>),
            ));

  final Map<String, BenchmarkResult> results;

  BenchmarkResults merge(BenchmarkResults other) => BenchmarkResults({
        ...results,
        ...other.results,
      });

  Map<String, Object?> toJson() => {
        for (final entry in results.entries) entry.key: entry.value.toJson(),
      };
}
