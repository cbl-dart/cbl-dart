import 'dart:convert';
import 'dart:io';

import '../github_actions.dart';
import '../utils.dart';
import 'base_command.dart';

final class CiFlakyJobs extends BaseCommand {
  CiFlakyJobs() {
    argParser
      ..addOption(
        'runs',
        abbr: 'n',
        help: 'Number of recent CI runs to analyze.',
        defaultsTo: '30',
      )
      ..addOption(
        'event',
        help:
            'The trigger event type to filter runs by. '
            'Use "all" to include all trigger types.',
        allowed: ['all', 'schedule', 'push'],
        defaultsTo: 'all',
      )
      ..addOption(
        'branch',
        abbr: 'b',
        help:
            'Only include runs from this branch. '
            'By default all branches are included.',
      )
      ..addOption(
        'threshold',
        abbr: 't',
        help:
            'Only show jobs with failure rate at or above this value '
            '(0.0-1.0).',
        defaultsTo: '0.0',
      )
      ..addFlag(
        'json',
        help: 'Output structured JSON instead of human-readable text.',
        negatable: false,
      );
  }

  @override
  String get name => 'ci-flaky-jobs';

  @override
  String get description => 'Analyzes CI run history to identify flaky jobs.';

  @override
  Future<void> doRun() async {
    final runs = arg<String>('runs');
    final count = int.tryParse(runs);
    if (count == null || count <= 0) {
      usageException('--runs must be a positive integer, got "$runs".');
    }

    final eventArg = arg<String>('event');
    final event = eventArg == 'all' ? null : eventArg;

    final thresholdStr = arg<String>('threshold');
    final threshold = double.tryParse(thresholdStr);
    if (threshold == null || threshold < 0 || threshold > 1) {
      usageException(
        '--threshold must be a number between 0.0 and 1.0, '
        'got "$thresholdStr".',
      );
    }

    final branch = optionalArg<String>('branch');
    final jsonOutput = arg<bool>('json');

    final cacheDir = Directory('${projectLayout.rootDir}/.cache/ci-flaky-jobs');
    final client = GitHubActionsClient(logger: logger, cacheDir: cacheDir);

    // Fetch workflow runs.
    final eventLabel = event ?? 'all';
    final branchLabel = branch ?? 'all branches';
    final workflowRuns = await logger.runWithProgress(
      message: 'Fetching $eventLabel runs on $branchLabel',
      showTiming: true,
      () => client.fetchRuns(event: event, branch: branch, count: count),
    );

    if (workflowRuns.isEmpty) {
      logger.stderr('No $eventLabel runs found on $branchLabel.');
      return;
    }

    // Fetch jobs for all runs in parallel.
    final jobsByRun = await logger.runWithProgress(
      message: 'Fetching jobs for ${workflowRuns.length} runs',
      showTiming: true,
      () async {
        final futures = {
          for (final run in workflowRuns)
            run.id: client.fetchJobsForRun(run.id),
        };
        return {
          for (final entry in futures.entries) entry.key: await entry.value,
        };
      },
    );

    // Parse current CI workflow to filter out stale jobs/steps.
    final workflowPath = '${projectLayout.rootDir}/.github/workflows/ci.yaml';
    final ciConfig = CiWorkflowConfig.parse(workflowPath);

    // Aggregate stats per job name. We include all runs, but skip
    // individual jobs that didn't complete (cancelled/skipped/in-progress)
    // or that no longer exist in the current CI configuration.
    final statsMap = <String, JobStats>{};
    for (final run in workflowRuns) {
      final jobs = jobsByRun[run.id]!;
      for (final job in jobs) {
        if (job.conclusion == null ||
            job.conclusion == 'cancelled' ||
            job.conclusion == 'skipped') {
          continue;
        }

        if (!ciConfig.isCurrentJob(job.name)) {
          continue;
        }

        final stats = statsMap.putIfAbsent(
          job.name,
          () => JobStats(name: job.name),
        );
        stats.totalRuns++;

        if (job.conclusion == 'success') {
          stats.successes++;
        } else {
          stats.failures++;
          // Only record the failed step if it still exists in the current
          // CI configuration.
          final failedStep = job.failedStep;
          final currentStep =
              failedStep != null &&
              ciConfig.isCurrentStep(job.name, failedStep);
          stats.recentFailures.add(
            JobFailure(
              runId: run.id,
              date: run.createdAt,
              url: job.htmlUrl,
              failedStep: currentStep ? failedStep : null,
            ),
          );
        }
      }
    }

    // Apply threshold filter.
    var jobs = statsMap.values.toList();
    if (threshold > 0) {
      jobs = jobs.where((job) => job.failureRate >= threshold).toList();
    }

    // Sort by failure rate descending, then by name.
    jobs.sort((a, b) {
      final cmp = b.failureRate.compareTo(a.failureRate);
      return cmp != 0 ? cmp : a.name.compareTo(b.name);
    });

    final report = FlakyReport(
      generatedAt: DateTime.now().toUtc(),
      runsAnalyzed: workflowRuns.length,
      dateFrom: workflowRuns.last.createdAt,
      dateTo: workflowRuns.first.createdAt,
      event: eventLabel,
      branch: branchLabel,
      jobs: jobs,
    );

    if (jsonOutput) {
      _printJson(report);
    } else {
      _printText(report);
    }
  }

  void _printJson(FlakyReport report) {
    const encoder = JsonEncoder.withIndent('  ');
    stdout.writeln(encoder.convert(report.toJson()));
  }

  void _printText(FlakyReport report) {
    final from = report.dateFrom.toIso8601String().substring(0, 10);
    final to = report.dateTo.toIso8601String().substring(0, 10);

    stdout
      ..writeln(
        'CI Flaky Jobs Report '
        '(last ${report.runsAnalyzed} ${report.event} runs '
        'on ${report.branch}, $from to $to)',
      )
      ..writeln('=' * 72)
      ..writeln();

    final flaky = report.jobs.where((job) => job.isFlaky).toList();
    final broken = report.jobs.where((job) => job.isBroken).toList();
    final stable = report.jobs
        .where((job) => !job.isFlaky && !job.isBroken)
        .toList();

    if (broken.isNotEmpty) {
      stdout.writeln('BROKEN (always failing):');
      for (final job in broken) {
        _printJobLine(job);
        _printFailedSteps(job);
      }
      stdout.writeln();
    }

    if (flaky.isNotEmpty) {
      stdout.writeln('FLAKY:');
      for (final job in flaky) {
        _printJobLine(job);
        _printFailedSteps(job);
      }
      stdout.writeln();
    }

    if (stable.isNotEmpty) {
      stdout.writeln('STABLE:');
      stable.forEach(_printJobLine);
      stdout.writeln();
    }

    // Summary.
    stdout.writeln(
      '${flaky.length} flaky, ${broken.length} broken, '
      '${stable.length} stable out of '
      '${report.jobs.length} jobs.',
    );
  }

  void _printJobLine(JobStats job) {
    final passPercent = (job.passRate * 100).toStringAsFixed(1);
    final label = '  ${job.name}';
    final stat = '$passPercent% pass (${job.successes}/${job.totalRuns})';
    final padding = 56 - label.length;
    stdout.writeln('$label${padding > 0 ? ' ' * padding : '  '}$stat');
  }

  void _printFailedSteps(JobStats job) {
    final stepCounts = job.failedStepCounts;
    if (stepCounts.isEmpty) {
      return;
    }

    for (final MapEntry(:key, :value) in stepCounts.entries) {
      stdout.writeln('    -> $key (${value}x)');
    }
  }
}
