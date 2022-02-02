import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_sentry/src/operation_debug_info.dart';
import 'package:test/test.dart';

import 'utils/mock_database.dart';
import 'utils/mock_query.dart';

void main() {
  setUpAll(() async {
    await CouchbaseLiteDart.init(edition: Edition.community);
  });

  group('debugName', () {
    test('TracedOperations', () {
      // Decapitalize name.
      expect(InitializeOp().debugName, 'cbl.initialize');
    });

    test('NativeCallOp', () {
      // Prefix with .native and do not decapitalize name.
      expect(NativeCallOp('Foo').debugName, 'cbl.native.Foo');
    });

    test('ChannelCallOp', () {
      // Prefix with .channel and do decapitalize name.
      expect(ChannelCallOp('Foo').debugName, 'cbl.channel.foo');
    });
  });

  group('debugDescription', () {
    test('OpenDatabaseOp', () {
      expect(OpenDatabaseOp('a', null).debugDescription, 'a');
    });

    test('GetDocumentOp', () {
      expect(GetDocumentOp(MockDatabase(name: 'a'), 'b').debugDescription, 'b');
    });

    test('DocumentOperationOp', () {
      expect(
        SaveDocumentOp(
          MockDatabase(name: 'a'),
          MutableDocument.withId('b'),
        ).debugDescription,
        'b',
      );
    });

    test('DatabaseOperationOp', () {
      final database = MockDatabase(name: 'a');
      expect(
        CloseDatabaseOp(database).debugDescription,
        'a',
      );
    });

    test('QueryOperationOp', () {
      expect(
        PrepareQueryOp(MockQuery(n1ql: 'a')).debugDescription,
        'a',
      );
      expect(
        PrepareQueryOp(MockQuery(jsonRepresentation: 'a')).debugDescription,
        'a',
      );
    });
  });

  group('debugDetails', () {
    test('SaveDocumentOp', () {
      final database = MockDatabase(name: 'a');
      final document = MutableDocument.withId('b');
      expect(
        SaveDocumentOp(database, document).debugDetails,
        {
          'withConflictHandler': true,
        },
      );
      expect(
        SaveDocumentOp(
          database,
          document,
          ConcurrencyControl.lastWriteWins,
        ).debugDetails,
        {
          'concurrencyControl': 'lastWriteWins',
        },
      );
    });

    test('DeleteDocumentOp', () {
      final database = MockDatabase(name: 'a');
      final document = MutableDocument.withId('b');
      expect(
        DeleteDocumentOp(
          database,
          document,
          ConcurrencyControl.lastWriteWins,
        ).debugDetails,
        {
          'concurrencyControl': 'lastWriteWins',
        },
      );
    });
  });
}
