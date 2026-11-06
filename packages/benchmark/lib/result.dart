import 'dart:math';

double median(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, 'values', 'must not be empty');
  }
  final sorted = List.of(values)..sort();
  return sorted[sorted.length ~/ 2];
}

/// Result of a single benchmark.
class BenchmarkResult {
  BenchmarkResult({required this.latency, this.throughput});

  /// Creates the result of a workload from the [latencies] of its operations
  /// and the [totalDuration] it took to complete them.
  factory BenchmarkResult.workload({
    required List<Duration> latencies,
    required Duration totalDuration,
  }) => BenchmarkResult(
    latency: median([
      for (final latency in latencies) latency.inMicroseconds.toDouble(),
    ]),
    throughput:
        latencies.length /
        (totalDuration.inMicroseconds / Duration.microsecondsPerSecond),
  );

  BenchmarkResult.fromJson(Map<String, Object?> json)
    : latency = (json['latency']! as num).toDouble(),
      throughput = (json['throughput'] as num?)?.toDouble();

  /// Latency of a single operation, in microseconds.
  final double latency;

  /// Number of operations per second, if measured.
  final double? throughput;

  Map<String, Object?> toJson() => {
    'latency': latency,
    if (throughput != null) 'throughput': throughput,
  };
}

/// Formats [results] as a plain text table.
String formatResults(Map<String, BenchmarkResult> results) {
  final header = ['Benchmark', 'Latency (us)', 'Throughput (ops/s)'];
  final rows = [
    header,
    for (final MapEntry(key: name, value: result) in results.entries)
      [
        name,
        result.latency.toStringAsFixed(2),
        result.throughput?.toStringAsFixed(0) ?? '-',
      ],
  ];
  final widths = [
    for (var column = 0; column < header.length; column++)
      rows.map((row) => row[column].length).reduce(max),
  ];

  return rows
      .map(
        (row) => [
          row.first.padRight(widths.first),
          for (var column = 1; column < row.length; column++)
            row[column].padLeft(widths[column]),
        ].join('  '),
      )
      .join('\n');
}
