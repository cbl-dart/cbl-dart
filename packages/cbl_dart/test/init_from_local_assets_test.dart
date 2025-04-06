import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final databasePath =
      p.join(Directory.current.path, 'test', 'from_local_assets_test');
  late Directory assetsDir;

  setUpAll(() async {
    // Setup assets directory only once
    var current = Directory.current;
    var levels = 0;
    var found = false;

    while (levels < 3 && !found) {
      final testDir = Directory(p.join(current.path, 'assets'));
      if (testDir.existsSync()) {
        assetsDir = testDir;
        found = true;
        break;
      }
      current = current.parent;
      levels++;
    }

    if (!found) {
      final targetDir = p.join(Directory.current.path, 'assets');
      assetsDir = Directory(targetDir);
    }

    if (!assetsDir.existsSync() ||
        !Directory(p.join(assetsDir.path, 'linux')).existsSync() ||
        !Directory(p.join(assetsDir.path, 'macos')).existsSync() ||
        !Directory(p.join(assetsDir.path, 'windows')).existsSync()) {
      final downloadScript = File(p.join(Directory.current.path, '..', 'cbl',
          'scripts', 'download_local_assets.sh'));

      if (!downloadScript.existsSync()) {
        throw StateError(
            'Could not find download_local_assets.sh script at ${downloadScript.path}');
      }

      await Process.run('chmod', ['+x', downloadScript.path]);

      final targetDir = p.join(Directory.current.path, 'assets');
      final result = await Process.run(downloadScript.path, [
        '--dir',
        targetDir,
        '--platform',
        'all',
        '--cbl-version',
        '3.2.0',
        '--cblitedart',
        '8.0.0',
        '--vector-search',
        '1.0.0',
        '--edition',
        'enterprise'
      ]);

      if (result.exitCode != 0) {
        throw StateError('Failed to download libraries: ${result.stderr}');
      }

      assetsDir = Directory(targetDir);
    }

    // Initialize CouchbaseLite once for all tests
    await CouchbaseLiteDart.initWithLocalBinaryDependencies(
      edition: Edition.enterprise,
      binaryDependencies: Directory(assetsDir.path),
      filesDir: Directory(databasePath).path,
    );
  });

  setUp(() async {
    // Clean up before each test
    final cleanupDir = Directory(databasePath);
    if (cleanupDir.existsSync()) {
      await cleanupDir.delete(recursive: true);
    }
  });

  tearDownAll(() async {
    // Clean up database directory
    final dbCleanupDir = Directory(databasePath);
    if (dbCleanupDir.existsSync()) {
      await dbCleanupDir.delete(recursive: true);
    }

    // Clean up assets directory
    if (assetsDir.existsSync()) {
      await assetsDir.delete(recursive: true);
    }
  });

  test('database is created and initialized correctly in clean state',
      () async {
    final db = await Database.openAsync('local-assets');

    final databaseFile = Directory(p.join(
        Directory(databasePath).path, 'CouchbaseLite', 'local-assets.cblite2'));
    expect(databaseFile.existsSync(), isTrue);

    // Create collection and test vector operation
    final collection = await db.defaultCollection;
    final documentMetadataIndexConfig =
        ValueIndexConfiguration(['DOCUMENT_TYPE', 'DOCUMENT_NAME']);

    await collection.createIndex(
        'DOCUMENT_METADATA_INDEX', documentMetadataIndexConfig);

    // Create test documents first
    final testDoc1 = MutableDocument.withId('doc1')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('First Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the first test article', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    final testDoc2 = MutableDocument.withId('doc2')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('Second Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the second test article', key: 'CONTENT')
      ..setValue(false, key: 'PUBLISHED');

    final testDoc3 = MutableDocument.withId('doc3')
      ..setValue('note', key: 'DOCUMENT_TYPE')
      ..setValue('First Note', key: 'DOCUMENT_NAME')
      ..setValue('This is a test note', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    await collection.saveDocument(testDoc1);
    await collection.saveDocument(testDoc2);
    await collection.saveDocument(testDoc3);

    // Now verify index was created and is working
    final indexes = await collection.indexes;
    expect(indexes, contains('DOCUMENT_METADATA_INDEX'));

    // Test that the index is being used by checking explain plan
    final metadataQuery = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
          Expression.property('DOCUMENT_TYPE')
              .equalTo(Expression.string('article'))
              .and(Expression.property('DOCUMENT_NAME')
                  .like(Expression.string('%Article%'))),
        );

    final explain = await metadataQuery.explain();
    expect(explain.toLowerCase(), contains('using index'));

    final metadataResults = await metadataQuery.execute();
    final metadataDocs = await metadataResults.allResults();
    expect(metadataDocs.length, equals(2));

    // Query all articles
    final articlesQuery = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property('DOCUMENT_TYPE')
            .equalTo(Expression.string('article')));

    final articlesResults = await articlesQuery.execute();
    final articles = await articlesResults.allResults();

    expect(articles.length, equals(2));

    // Query published documents
    final publishedQuery = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
            Expression.property('PUBLISHED').equalTo(Expression.boolean(true)));

    final publishedResults = await publishedQuery.execute();
    final published = await publishedResults.allResults();

    // Add more detailed debug logging
    print('\nPublished documents count: ${published.length}');
    for (final result in published) {
      final rawData = result.toPlainMap();
      final doc = rawData['_default'] as Map<String, dynamic>;
      print('\nDocument:');
      print('  Type: ${doc['DOCUMENT_TYPE']}');
      print('  Name: ${doc['DOCUMENT_NAME']}');
      print('  Published: ${doc['PUBLISHED']}');
      print('  Content: ${doc['CONTENT']}');
    }

    expect(published.length, equals(2));

    // Query published articles
    final publishedArticlesQuery = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(
          Expression.property('DOCUMENT_TYPE')
              .equalTo(Expression.string('article'))
              .and(Expression.property('PUBLISHED')
                  .equalTo(Expression.boolean(true))),
        );

    final publishedArticlesResults = await publishedArticlesQuery.execute();
    final publishedArticles = await publishedArticlesResults.allResults();

    expect(publishedArticles.length, equals(1));

    await db.close();
  });

  test('database persists and can be modified after reopening', () async {
    final db = await Database.openAsync('local-assets');
    final collection = await db.defaultCollection;

    // Create index first
    final documentMetadataIndexConfig =
        ValueIndexConfiguration(['DOCUMENT_TYPE', 'DOCUMENT_NAME']);
    await collection.createIndex(
        'DOCUMENT_METADATA_INDEX', documentMetadataIndexConfig);

    // Create initial test documents
    final testDoc1 = MutableDocument.withId('doc1')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('First Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the first test article', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    final testDoc2 = MutableDocument.withId('doc2')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('Second Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the second test article', key: 'CONTENT')
      ..setValue(false, key: 'PUBLISHED');

    final testDoc3 = MutableDocument.withId('doc3')
      ..setValue('note', key: 'DOCUMENT_TYPE')
      ..setValue('First Note', key: 'DOCUMENT_NAME')
      ..setValue('This is a test note', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    await collection.saveDocument(testDoc1);
    await collection.saveDocument(testDoc2);
    await collection.saveDocument(testDoc3);

    await db.close();

    // Reopen database and verify data
    final reopenedDb = await Database.openAsync('local-assets');
    final reopenedCollection = await reopenedDb.defaultCollection;

    // Verify initial state
    final initialPublishedQuery = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(reopenedCollection))
        .where(
            Expression.property('PUBLISHED').equalTo(Expression.boolean(true)));

    final initialPublished =
        await (await initialPublishedQuery.execute()).allResults();
    expect(initialPublished.length, equals(2));

    // Add new document
    final testDoc4 = MutableDocument.withId('doc4')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('Fourth Article', key: 'DOCUMENT_NAME')
      ..setValue('This is another test article', key: 'CONTENT')
      ..setValue(false, key: 'PUBLISHED');

    await reopenedCollection.saveDocument(testDoc4);

    // Modify existing document
    final doc1 = await reopenedCollection.document('doc1');
    final updatedDoc1 = doc1?.toMutable()?..setValue(false, key: 'PUBLISHED');
    await reopenedCollection.saveDocument(updatedDoc1!);

    // Verify updated state
    final updatedQuery = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(reopenedCollection))
        .where(
            Expression.property('PUBLISHED').equalTo(Expression.boolean(true)));

    final updatedResults = await updatedQuery.execute();
    final updated = await updatedResults.allResults();

    // Only doc3 should still be published
    expect(updated.length, equals(1));

    await reopenedDb.close();
  });
}
