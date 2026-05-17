// coverage:ignore-file

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

const _diagnosticsEnv = 'CBL_GENERATOR_TEST_DIAGNOSTICS';
const _slowBuildMsEnv = 'CBL_GENERATOR_SLOW_BUILD_MS';
const _stressEnv = 'CBL_GENERATOR_STRESS';
const _stressIterationsEnv = 'CBL_GENERATOR_STRESS_ITERATIONS';

var _nextBuildInvocationId = 0;
var _nextUniqueAssetId = 0;

bool get generatorTestDiagnosticsEnabled =>
    _isTruthy(Platform.environment[_diagnosticsEnv]);

bool get generatorStressEnabled => _isTruthy(Platform.environment[_stressEnv]);

int generatorStressIterations({int defaultValue = 10}) =>
    _intFromEnvironment(_stressIterationsEnv, defaultValue: defaultValue);

String uniqueGeneratorAssetStem(String label) {
  final id = _nextUniqueAssetId++;
  final sanitized = label
      .replaceAll(RegExp('[^a-zA-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '')
      .toLowerCase();
  return 'generated/${sanitized}_$id';
}

Future<TestReaderWriter> createGeneratorTestReaderWriter({
  required String rootPackage,
  required String label,
}) async {
  final stopwatch = Stopwatch()..start();
  final readerWriter = TestReaderWriter(rootPackage: rootPackage);
  Timer? heartbeat;

  void emit(String message) =>
      _emitDiagnostic('[generator-test-reader-writer] $label $message');

  emit('LOAD_BEGIN rootPackage=$rootPackage');
  if (generatorTestDiagnosticsEnabled) {
    heartbeat = Timer.periodic(
      const Duration(seconds: 15),
      (_) => emit(
        'LOAD_RUNNING elapsedMs=${stopwatch.elapsedMilliseconds} '
        'assets=${readerWriter.testing.assets.length} '
        'rss=${ProcessInfo.currentRss}',
      ),
    );
  }

  try {
    await readerWriter.testing.loadIsolateSources();
    stopwatch.stop();
    heartbeat?.cancel();
    emit(
      'LOAD_END elapsedMs=${stopwatch.elapsedMilliseconds} '
      'assets=${readerWriter.testing.assets.length} '
      'rss=${ProcessInfo.currentRss}',
    );
    return readerWriter;
  } on Object catch (error, stackTrace) {
    stopwatch.stop();
    heartbeat?.cancel();
    emit(
      'LOAD_ERROR elapsedMs=${stopwatch.elapsedMilliseconds} '
      'assets=${readerWriter.testing.assets.length} error=$error',
    );
    emit('LOAD_STACK $stackTrace');
    rethrow;
  }
}

void deleteGeneratorTestAsset(TestReaderWriter readerWriter, String assetId) {
  final separator = assetId.indexOf('|');
  if (separator < 0) {
    throw ArgumentError.value(assetId, 'assetId', 'Expected package|path.');
  }

  final id = AssetId(
    assetId.substring(0, separator),
    assetId.substring(separator + 1),
  );
  if (readerWriter.testing.exists(id)) {
    readerWriter.testing.delete(id);
  }
}

Future<TestBuilderResult> runGeneratorTestBuilder(
  Builder builder,
  Map<String, Object> sourceAssets, {
  required String label,
  TestReaderWriter? readerWriter,
  Map<String, Object>? outputs,
  void Function(LogRecord record)? onLog,
  Duration? slowThreshold,
}) async {
  final invocationId = _nextBuildInvocationId++;
  final stopwatch = Stopwatch()..start();
  final logs = <LogRecord>[];
  Timer? heartbeat;
  final packageConfig =
      (await PackageAssetReader.currentIsolate()).packageConfig;
  final effectiveSlowThreshold =
      slowThreshold ??
      Duration(
        milliseconds: _intFromEnvironment(_slowBuildMsEnv, defaultValue: 10000),
      );

  void emit(String message) => _emitDiagnostic(
    '[generator-test-builder] #$invocationId $label $message',
  );

  emit(
    'BEGIN assets=${_describeAssets(sourceAssets)} '
    'readerAssets=${_readerAssetCount(readerWriter) ?? 'none'} '
    'packageConfig=custom',
  );
  if (generatorTestDiagnosticsEnabled) {
    heartbeat = Timer.periodic(
      const Duration(seconds: 15),
      (_) => emit(
        'RUNNING elapsedMs=${stopwatch.elapsedMilliseconds} '
        'logs=${logs.length}',
      ),
    );
  }

  void captureLog(LogRecord record) {
    logs.add(record);
    _emitDiagnostic(
      '[generator-test-builder] #$invocationId $label '
      'LOG ${_formatLogRecord(record)}',
    );
    onLog?.call(record);
  }

  try {
    final result = await testBuilder(
      builder,
      sourceAssets,
      outputs: outputs,
      onLog: captureLog,
      readerWriter: readerWriter,
      packageConfig: packageConfig,
    );

    stopwatch.stop();
    heartbeat?.cancel();
    emit(
      'END elapsedMs=${stopwatch.elapsedMilliseconds} '
      'logs=${logs.length} succeeded=${result.succeeded} '
      'outputs=${result.outputs.length} errors=${result.errors.length}',
    );

    if (stopwatch.elapsed > effectiveSlowThreshold) {
      emit('SLOW thresholdMs=${effectiveSlowThreshold.inMilliseconds}');
    }

    return result;
  } on Object catch (error, stackTrace) {
    stopwatch.stop();
    heartbeat?.cancel();
    emit(
      'ERROR elapsedMs=${stopwatch.elapsedMilliseconds} '
      'logs=${logs.length} error=$error',
    );
    emit('STACK $stackTrace');
    for (final entry in sourceAssets.entries) {
      emit('SOURCE ${entry.key}\n${entry.value}');
    }
    rethrow;
  }
}

void _emitDiagnostic(String message) {
  printOnFailure(message);

  if (generatorTestDiagnosticsEnabled) {
    stdout.writeln(message);
  }
}

String _describeAssets(Map<String, Object> assets) => assets.entries
    .map((entry) => '${entry.key}#${_stableHash(entry.value)}')
    .join(',');

int? _readerAssetCount(TestReaderWriter? readerWriter) {
  if (readerWriter == null) {
    return null;
  }

  return readerWriter.testing.assets.length;
}

String _formatLogRecord(LogRecord record) {
  final buffer = StringBuffer()
    ..write(record.time.toIso8601String())
    ..write(' ')
    ..write(record.level.name)
    ..write(' ')
    ..write(record.loggerName)
    ..write(' ')
    ..write(record.message);

  if (record.error != null) {
    buffer
      ..write(' error=')
      ..write(record.error);
  }

  if (record.stackTrace != null) {
    buffer
      ..write(' stack=')
      ..write(record.stackTrace);
  }

  return buffer.toString();
}

String _stableHash(Object value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.toString().codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

int _intFromEnvironment(String name, {required int defaultValue}) {
  final value = int.tryParse(Platform.environment[name] ?? '');
  if (value == null || value <= 0) {
    return defaultValue;
  }
  return value;
}

bool _isTruthy(String? value) =>
    value != null && value.isNotEmpty && value != '0' && value != 'false';
