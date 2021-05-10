import 'dart:async';
import 'dart:math';

abstract class Benchmark {
  Benchmark(this.description);

  final String description;

  FutureOr<void> run();

  FutureOr<void> setUp() {}

  FutureOr<void> validate();
}

Future<void> runBenchmarks(
  Iterable<Benchmark> benchmarks, {
  int repetitions = 10000,
}) async {
  if (benchmarks.isEmpty) {
    throw ArgumentError.value(benchmarks, 'benchmarks', 'must not be empty');
  }

  final formattingDecimalPoints = 2;
  final middleLineDeco = '\u251c\u2500\u25B6';
  final lastLineDeco = '\u2514\u2500\u25B6';
  final singleLineDeco = '\u2576\u2500\u25B6';

  final stopwatch = Stopwatch();

  final results = <Benchmark, double>{};

  for (final benchmark in benchmarks) {
    print('Running benchmark: ${benchmark.description} ($repetitions reps)');

    var totalUs = 0;

    for (var i = 0; i < repetitions; i++) {
      await benchmark.setUp();

      stopwatch
        ..reset()
        ..start();
      await benchmark.run();
      stopwatch.stop();

      totalUs += stopwatch.elapsedMicroseconds;

      await benchmark.validate();
    }

    final totalMs = totalUs / 1000;
    final avgUs = totalUs / repetitions;
    print(
      '$middleLineDeco Total: '
      '${totalMs.toStringAsFixed(formattingDecimalPoints)} ms',
    );
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
    final relativeTime = (results[benchmark]! / fastestTime);
    final relativeTimeStr =
        relativeTime.toStringAsFixed(formattingDecimalPoints);
    print('$singleLineDeco ${benchmark.description}: ${relativeTimeStr}x');
  }
}
