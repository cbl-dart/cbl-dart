// coverage:ignore-file

import 'dart:io';
import 'dart:math' as math;

import 'package:build_test/build_test.dart';
import 'package:cbl_generator/src/builder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'generator_test_utils.dart';

void main() {
  final iterations = generatorStressIterations();

  group(
    'typed dictionary generator stress diagnostics',
    skip: generatorStressEnabled
        ? false
        : 'Set CBL_GENERATOR_STRESS=1 to run generator stress diagnostics.',
    () {
      test(
        'metadata bad-source builds stay isolated under repetition',
        () async {
          final readerWriter = await createGeneratorTestReaderWriter(
            rootPackage: _testPkg,
            label: 'stress shared reader',
          );
          final random = math.Random(0);
          final samples = <_StressSample>[];

          for (var iteration = 0; iteration < iterations; iteration++) {
            final cases = List.of(_metadataCases)..shuffle(random);

            for (final testCase in cases) {
              samples.addAll([
                await _runStressCase(
                  testCase,
                  iteration: iteration,
                  assetMode: _AssetMode.shared,
                  readerWriter: readerWriter,
                ),
                await _runStressCase(
                  testCase,
                  iteration: iteration,
                  assetMode: _AssetMode.unique,
                  readerWriter: readerWriter,
                ),
              ]);
            }
          }

          stdout.writeln(_formatSummary(samples));
        },
        timeout: Timeout(Duration(minutes: math.max(2, iterations))),
      );
    },
  );
}

const _testPkg = 'pkg';

const _metadataCases = [
  _StressCase(
    name: 'document_id_getter_wrong_type',
    source: r'''
@TypedDocument()
abstract class A with _$A {
  factory A() = MutableA;

  @DocumentId()
  int get id;
}
''',
    expectedMessage:
        '@DocumentId must be used on a getter which returns a String.',
  ),
  _StressCase(
    name: 'document_sequence_getter_wrong_type',
    source: r'''
@TypedDocument()
abstract class A with _$A {
  factory A() = MutableA;

  @DocumentSequence()
  String get sequence;
}
''',
    expectedMessage:
        '@DocumentSequence must be used on a getter which returns a int.',
  ),
  _StressCase(
    name: 'document_revision_id_getter_wrong_type',
    source: r'''
@TypedDocument()
abstract class A with _$A {
  factory A() = MutableA;

  @DocumentRevisionId()
  String get sequence;
}
''',
    expectedMessage:
        '@DocumentRevisionId must be used on a getter which returns a String?.',
  ),
];

Future<_StressSample> _runStressCase(
  _StressCase testCase, {
  required int iteration,
  required _AssetMode assetMode,
  required TestReaderWriter readerWriter,
}) async {
  final label =
      'stress ${assetMode.name} ${testCase.name} iteration=$iteration';
  final assetStem = switch (assetMode) {
    _AssetMode.shared => 'generated/stress_${testCase.name}',
    _AssetMode.unique => uniqueGeneratorAssetStem(
      'stress_${testCase.name}_$iteration',
    ),
  };
  final assetName = assetStem.split('/').last;
  final sourceAsset = '$_testPkg|lib/$assetStem.dart';
  final severeMessages = <String>[];
  final stopwatch = Stopwatch()..start();

  void captureError(LogRecord record) {
    if (record.level >= Level.SEVERE) {
      severeMessages.add(record.message);
    }
  }

  try {
    await runGeneratorTestBuilder(
      TypedDataBuilder(),
      {
        sourceAsset: _testLibContent(
          testCase.source,
          partFileName: '$assetName.cbl.type.g.dart',
        ),
      },
      label: label,
      onLog: captureError,
      readerWriter: readerWriter,
    );
  } finally {
    deleteGeneratorTestAsset(readerWriter, sourceAsset);
  }
  stopwatch.stop();

  expect(
    severeMessages,
    hasLength(1),
    reason: 'Captured severe messages:\n${severeMessages.join('\n---\n')}',
  );
  expect(severeMessages.single, contains(testCase.expectedMessage));

  return _StressSample(
    caseName: testCase.name,
    assetMode: assetMode,
    iteration: iteration,
    elapsed: stopwatch.elapsed,
  );
}

String _testLibContent(String content, {required String partFileName}) =>
    '''
import 'package:cbl/cbl.dart';

part '$partFileName';

$content''';

String _formatSummary(List<_StressSample> samples) {
  final buffer = StringBuffer()
    ..writeln('typed_dictionary_generator_stress summary')
    ..writeln('samples=${samples.length}')
    ..writeln(
      'iterations=${samples.map((sample) => sample.iteration).toSet().length}',
    );

  for (final assetMode in _AssetMode.values) {
    for (final testCase in _metadataCases) {
      final matching = samples
          .where(
            (sample) =>
                sample.assetMode == assetMode &&
                sample.caseName == testCase.name,
          )
          .toList();
      if (matching.isEmpty) {
        continue;
      }

      final totalMs = matching.fold<int>(
        0,
        (previous, sample) => previous + sample.elapsed.inMilliseconds,
      );
      final maxMs = matching
          .map((sample) => sample.elapsed.inMilliseconds)
          .reduce(math.max);
      buffer.writeln(
        '${assetMode.name}/${testCase.name}: '
        'count=${matching.length} '
        'avgMs=${totalMs ~/ matching.length} '
        'maxMs=$maxMs',
      );
    }
  }

  return buffer.toString();
}

enum _AssetMode { shared, unique }

final class _StressCase {
  const _StressCase({
    required this.name,
    required this.source,
    required this.expectedMessage,
  });

  final String name;
  final String source;
  final String expectedMessage;
}

final class _StressSample {
  const _StressSample({
    required this.caseName,
    required this.assetMode,
    required this.iteration,
    required this.elapsed,
  });

  final String caseName;
  final _AssetMode assetMode;
  final int iteration;
  final Duration elapsed;
}
