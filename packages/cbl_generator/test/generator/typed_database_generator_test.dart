import 'package:build_test/build_test.dart';
import 'package:cbl_generator/src/builder.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

late TestReaderWriter readerWriter;

void main() {
  setUp(() async {
    readerWriter = TestReaderWriter(rootPackage: _testPkg);
    await readerWriter.testing.loadIsolateSources();
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
    await testBuilder(
      TypedDatabaseBuilder(),
      {
        _testLibId: _testLibContent(r'''
@TypedDatabase(types: {})
class $A {
}
'''),
      },
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
// dart format width=80
${TypedDatabaseBuilder.header}
// **************************************************************************
// TypedDatabaseGenerator
// **************************************************************************

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';
import '$_testLibFileName';

$content''';

Future<void> _expectBadSource(String source, [Object? messageMatcher]) async {
  if (messageMatcher is String) {
    messageMatcher = contains(messageMatcher);
  }

  String? errorMessage;

  void captureError(LogRecord record) {
    if (record.level >= Level.SEVERE) {
      if (errorMessage != null) {
        throw StateError('Expected only one error.');
      }
      errorMessage = record.message;
    }
  }

  await testBuilder(
    TypedDatabaseBuilder(),
    {_testLibId: _testLibContent(source)},
    onLog: captureError,
    readerWriter: readerWriter,
  );

  await expectLater(errorMessage, messageMatcher ?? isNotNull);
}
