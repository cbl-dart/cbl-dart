// ignore_for_file: avoid_print

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';

void runBenchmarks(Iterable<BenchmarkBase> benchmarks) {
  if (benchmarks.isEmpty) {
    throw ArgumentError.value(benchmarks, 'benchmarks', 'must not be empty');
  }

  const formattingDecimalPoints = 2;
  const lastLineDeco = '\u2514\u2500\u25B6';
  const singleLineDeco = '\u2576\u2500\u25B6';

  final results = <BenchmarkBase, double>{};

  for (final benchmark in benchmarks) {
    print('Running benchmark: ${benchmark.name}');

    final avgUs = benchmark.measure();
    print(
      '$lastLineDeco Avg:   '
      '${avgUs.toStringAsFixed(formattingDecimalPoints)} us',
    );
    print('');
    results[benchmark] = avgUs;
  }

  final fastestTime = results.values.reduce(min);

  print('Relative Results:');
  for (final benchmark in benchmarks) {
    final relativeTime = results[benchmark]! / fastestTime;
    final relativeTimeStr =
        relativeTime.toStringAsFixed(formattingDecimalPoints);
    print('$singleLineDeco ${benchmark.name}: ${relativeTimeStr}x');
  }
}
