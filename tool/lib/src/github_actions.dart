import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';

import 'utils.dart';

const _owner = 'cbl-dart';
const _repo = 'cbl-dart';
const _workflowFile = 'ci.yaml';

final class WorkflowRun {
  WorkflowRun({
    required this.id,
    required this.createdAt,
    required this.conclusion,
    required this.htmlUrl,
  });

  factory WorkflowRun.fromJson(Map<String, Object?> json) => WorkflowRun(
    id: json['id']! as int,
    createdAt: DateTime.parse(json['created_at']! as String),
    conclusion: json['conclusion'] as String?,
    htmlUrl: json['html_url']! as String,
  );

  final int id;
  final DateTime createdAt;
  final String? conclusion;
  final String htmlUrl;
}

final class Step {
  Step({required this.name, required this.conclusion});

  factory Step.fromJson(Map<String, Object?> json) => Step(
    name: json['name']! as String,
    conclusion: json['conclusion'] as String?,
  );

  final String name;
  final String? conclusion;
}

final class Job {
  Job({
    required this.name,
    required this.conclusion,
    required this.runId,
    required this.htmlUrl,
    required this.steps,
  });

  factory Job.fromJson(Map<String, Object?> json) => Job(
    name: json['name']! as String,
    conclusion: json['conclusion'] as String?,
    runId: json['run_id']! as int,
    htmlUrl: json['html_url']! as String,
    steps: (json['steps']! as List)
        .cast<Map<String, Object?>>()
        .map(Step.fromJson)
        .toList(),
  );

  final String name;
  final String? conclusion;
  final int runId;
  final String htmlUrl;
  final List<Step> steps;

  /// Returns the name of the first step that failed, or `null` if none.
  String? get failedStep {
    for (final step in steps) {
      if (step.conclusion == 'failure') {
        return step.name;
      }
    }
    return null;
  }
}

final class JobStats {
  JobStats({required this.name});

  final String name;
  // ignore: omit_obvious_property_types
  int totalRuns = 0;
  // ignore: omit_obvious_property_types
  int successes = 0;
  // ignore: omit_obvious_property_types
  int failures = 0;
  final recentFailures = <JobFailure>[];

  double get passRate => totalRuns == 0 ? 1.0 : successes / totalRuns;
  double get failureRate => 1.0 - passRate;

  /// A job is flaky if it fails sometimes but not always.
  bool get isFlaky => failures > 0 && successes > 0;

  /// A job is broken if it always fails.
  bool get isBroken => failures > 0 && successes == 0;

  /// Returns a frequency map of failed step names, sorted by count descending.
  Map<String, int> get failedStepCounts {
    final counts = <String, int>{};
    for (final failure in recentFailures) {
      if (failure.failedStep != null) {
        counts[failure.failedStep!] = (counts[failure.failedStep!] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'total_runs': totalRuns,
    'successes': successes,
    'failures': failures,
    'pass_rate': double.parse(passRate.toStringAsFixed(3)),
    'flaky': isFlaky,
    'broken': isBroken,
    'failed_steps': failedStepCounts,
    'recent_failures': [for (final failure in recentFailures) failure.toJson()],
  };
}

final class JobFailure {
  JobFailure({
    required this.runId,
    required this.date,
    required this.url,
    this.failedStep,
  });

  final int runId;
  final DateTime date;
  final String url;
  final String? failedStep;

  Map<String, Object?> toJson() => {
    'run_id': runId,
    'date': date.toIso8601String().substring(0, 10),
    'url': url,
    if (failedStep != null) 'failed_step': failedStep,
  };
}

final class FlakyReport {
  FlakyReport({
    required this.generatedAt,
    required this.runsAnalyzed,
    required this.dateFrom,
    required this.dateTo,
    required this.event,
    required this.jobs,
  });

  final DateTime generatedAt;
  final int runsAnalyzed;
  final DateTime dateFrom;
  final DateTime dateTo;
  final String event;
  final List<JobStats> jobs;

  Map<String, Object?> toJson() => {
    'generated_at': generatedAt.toIso8601String(),
    'runs_analyzed': runsAnalyzed,
    'event': event,
    'date_range': {
      'from': dateFrom.toIso8601String().substring(0, 10),
      'to': dateTo.toIso8601String().substring(0, 10),
    },
    'jobs': jobs.map((job) => job.toJson()).toList(),
  };
}

final class GitHubActionsClient {
  GitHubActionsClient({required this.logger, this.cacheDir});

  final Logger logger;

  /// Directory to cache API responses in. If `null`, caching is disabled.
  final Directory? cacheDir;

  Future<List<WorkflowRun>> fetchRuns({
    String? event,
    required int count,
  }) async {
    final eventParam = event != null ? '&event=$event' : '';
    final path =
        '/repos/$_owner/$_repo/actions/workflows'
        '/$_workflowFile/runs?branch=main$eventParam&per_page=$count';
    final result = await _gh(['api', path]);

    final json = jsonDecode(result.stdout as String) as Map<String, Object?>;
    final runs = (json['workflow_runs']! as List)
        .cast<Map<String, Object?>>()
        .map(WorkflowRun.fromJson)
        .toList();

    return runs;
  }

  Future<List<Job>> fetchJobsForRun(int runId) async {
    final cached = _readCache(runId);
    if (cached != null) {
      return _parseJobs(cached);
    }

    final result = await _gh([
      'api',
      '/repos/$_owner/$_repo/actions/runs/$runId/jobs?per_page=100',
    ]);

    final body = result.stdout as String;
    final jobs = _parseJobs(body);

    // Only cache if all jobs in the run have completed.
    final allComplete = jobs.every((job) => job.conclusion != null);
    if (allComplete) {
      _writeCache(runId, body);
    }

    return jobs;
  }

  List<Job> _parseJobs(String body) {
    final json = jsonDecode(body) as Map<String, Object?>;
    return (json['jobs']! as List)
        .cast<Map<String, Object?>>()
        .map(Job.fromJson)
        .toList();
  }

  File? _cacheFile(int runId) {
    if (cacheDir == null) {
      return null;
    }
    return File('${cacheDir!.path}/$runId.json');
  }

  String? _readCache(int runId) {
    final file = _cacheFile(runId);
    if (file != null && file.existsSync()) {
      logger.trace('Cache hit for run $runId');
      return file.readAsStringSync();
    }
    return null;
  }

  void _writeCache(int runId, String body) {
    final file = _cacheFile(runId);
    if (file == null) {
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(body);
    logger.trace('Cached run $runId');
  }

  Future<ProcessResult> _gh(List<String> args) =>
      runProcess('gh', args, logger: logger);
}
