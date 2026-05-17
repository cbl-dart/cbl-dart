import 'package:build_test/build_test.dart';
import 'package:cbl_generator/src/builder.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'generator_test_utils.dart';

late TestReaderWriter readerWriter;

void main() {
  setUpAll(() async {
    readerWriter = await createGeneratorTestReaderWriter(
      rootPackage: _testPkg,
      label: 'typed_database shared reader',
    );
  });

  test('annotated declaration is not a class', () async {
    await _expectBadSource('''
@TypedDatabase(types: {})
const a = '';
  ''', '@TypedDatabase can only be used on a class.');
  });

  test('class does not start with dollar sign', () async {
    await _expectBadSource('''
@TypedDatabase(types: {})
class A {
}
  ''', r'Classes annotated with @TypedDatabase must start with $');
  });

  test('database without types', () async {
    await runGeneratorTestBuilder(
      TypedDatabaseBuilder(),
      {
        _testLibId: _testLibContent(r'''
@TypedDatabase(types: {})
class $A {
}
'''),
      },
      label: 'typed_database database without types',
      readerWriter: readerWriter,
      outputs: {
        _genPartId: _typedDatabaseGeneratorContent(r'''
class A extends $A {
  static Future<AsyncDatabase> openAsync(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      // ignore: invalid_use_of_internal_member
      AsyncDatabase.openInternal(name, config, _adapter);

  static SyncDatabase openSync(String name, [DatabaseConfiguration? config]) =>
      // ignore: invalid_use_of_internal_member
      SyncDatabase.internal(name, config, _adapter);

  static final _adapter = TypedDataRegistry(types: []);
}
'''),
      },
    );
  });
}

const _testPkg = 'pkg';
const _testLib = 'lib';
const _testLibFileName = '$_testLib.dart';
const _genLibFileName = '$_testLib.cbl.database.g.dart';
const _testLibId = '$_testPkg|$_testLibFileName';
const _genPartId = '$_testPkg|$_genLibFileName';

String _testLibContent(String content) => '''
import 'package:cbl/cbl.dart';

$content''';

String _typedDatabaseGeneratorContent(String content) =>
    '''
$defaultFileHeader
// dart format width=80

${TypedDatabaseBuilder.ignoreForFile}

// **************************************************************************
// TypedDatabaseGenerator
// **************************************************************************

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';
import '$_testLibFileName';

$content''';

Future<void> _expectBadSource(String source, [Object? messageMatcher]) async {
  final effectiveMatcher = messageMatcher is String
      ? contains(messageMatcher)
      : messageMatcher;

  String? errorMessage;

  void captureError(LogRecord record) {
    if (record.level >= Level.SEVERE) {
      if (errorMessage != null) {
        throw StateError('Expected only one error.');
      }
      errorMessage = record.message;
    }
  }

  final assetStem = uniqueGeneratorAssetStem('typed_database_bad_source');
  final sourceAsset = '$_testPkg|lib/$assetStem.dart';

  try {
    await runGeneratorTestBuilder(
      TypedDatabaseBuilder(),
      {sourceAsset: _testLibContent(source)},
      label: 'typed_database bad source',
      onLog: captureError,
      readerWriter: readerWriter,
    );
  } finally {
    deleteGeneratorTestAsset(readerWriter, sourceAsset);
  }

  await expectLater(errorMessage, effectiveMatcher ?? isNotNull);
}
