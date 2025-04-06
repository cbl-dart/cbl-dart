import 'dart:math';

class Measure {
  Measure({
    required this.name,
    required this.value,
    this.upperValue,
    this.lowerValue,
  });

  Measure.median({
    required this.name,
    required List<double> values,
  })  : value = _median(values),
        upperValue = values.reduce(max),
        lowerValue = values.reduce(min);

  Measure.fromJson(Map<String, Object?> json)
      : name = json['name']! as String,
        value = (json['value']! as num).toDouble(),
        upperValue = (json['upper_value'] as num?)?.toDouble(),
        lowerValue = (json['lower_value'] as num?)?.toDouble();

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

double _median(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'values', 'must not be empty');
  }
  final sorted = List.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted[middle];
}

class BenchmarkResult {
  BenchmarkResult({required this.measures});

  BenchmarkResult.fromJson(Map<String, Object?> json)
      : measures = (json.entries
            .map((entry) =>
                Measure.fromJson(entry.value! as Map<String, Object?>))
            .toList());

  final List<Measure> measures;

  Map<String, Object?> toJson() => {
        for (final measure in measures) measure.name: measure.toJson(),
      };
}

class BenchmarkResults {
  BenchmarkResults([this.results = const {}]);

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
