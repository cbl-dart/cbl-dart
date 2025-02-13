import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final database_path = p.join(Directory.current.path, 'test', 'local_assets_test');
  late Directory assets_dir;

  setUpAll(() async {
    // Setup assets directory only once
    var current = Directory.current;
    var levels = 0;
    var found = false;

    while (levels < 3 && !found) {
      final test_dir = Directory(p.join(current.path, 'assets'));
      if (test_dir.existsSync()) {
        assets_dir = test_dir;
        found = true;
        break;
      }
      current = current.parent;
      levels++;
    }

    if (!found) {
      final target_dir = p.join(Directory.current.path, 'assets');
      assets_dir = Directory(target_dir);
    }

    if (!assets_dir.existsSync() ||
        !Directory(p.join(assets_dir.path, 'linux')).existsSync() ||
        !Directory(p.join(assets_dir.path, 'macos')).existsSync() ||
        !Directory(p.join(assets_dir.path, 'windows')).existsSync()) {
      final download_script = File(p.join(Directory.current.path, 'download_libs.sh'));
      await Process.run('chmod', ['+x', download_script.path]);

      final target_dir = p.join(Directory.current.path, 'assets');
      final result = await Process.run(download_script.path, [target_dir]);

      if (result.exitCode != 0) {
        throw StateError('Failed to download libraries: ${result.stderr}');
      }

      assets_dir = Directory(target_dir);
    }

    // Initialize CouchbaseLite once for all tests
    await CouchbaseLiteDart.initWithLocalBinaryDependencies(
      edition: Edition.enterprise,
      binaryDependencies: Directory(assets_dir.path),
      databaseLocation: Directory(database_path),
    );
  });

  setUp(() async {
    // Clean up before each test
    final cleanup_dir = Directory(database_path);
    if (cleanup_dir.existsSync()) {
      await cleanup_dir.delete(recursive: true);
    }
  });

  test('database is created and initialized correctly in clean state', () async {
    final db = await Database.openAsync('local-assets');

    final database_file = Directory(p.join(Directory(database_path).path, 'CouchbaseLite', 'local-assets.cblite2'));
    expect(database_file.existsSync(), isTrue);

    // Create collection and test vector operation
    final collection = await db.defaultCollection;
    final DOCUMENT_METADATA_INDEX_CONFIG = ValueIndexConfiguration(['DOCUMENT_TYPE', 'DOCUMENT_NAME']);

    await collection.createIndex('DOCUMENT_METADATA_INDEX', DOCUMENT_METADATA_INDEX_CONFIG);

    // Create test documents first
    final test_doc1 = MutableDocument.withId('doc1')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('First Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the first test article', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    final test_doc2 = MutableDocument.withId('doc2')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('Second Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the second test article', key: 'CONTENT')
      ..setValue(false, key: 'PUBLISHED');

    final test_doc3 = MutableDocument.withId('doc3')
      ..setValue('note', key: 'DOCUMENT_TYPE')
      ..setValue('First Note', key: 'DOCUMENT_NAME')
      ..setValue('This is a test note', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    await collection.saveDocument(test_doc1);
    await collection.saveDocument(test_doc2);
    await collection.saveDocument(test_doc3);

    // Now verify index was created and is working
    final indexes = await collection.indexes;
    expect(indexes, contains('DOCUMENT_METADATA_INDEX'));

    // Test that the index is being used by checking explain plan
    final metadata_query = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property('DOCUMENT_TYPE')
            .equalTo(Expression.string('article'))
            .and(Expression.property('DOCUMENT_NAME').like(Expression.string('%Article%'))));

    final explain = await metadata_query.explain();
    expect(explain.toLowerCase(), contains('using index'));

    final metadata_results = await metadata_query.execute();
    final metadata_docs = await metadata_results.allResults();
    expect(metadata_docs.length, equals(2)); // Should find both article documents

    // Query all articles
    final articles_query = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property('DOCUMENT_TYPE').equalTo(Expression.string('article')));

    final articles_results = await articles_query.execute();
    final articles = await articles_results.allResults();

    expect(articles.length, equals(2));

    // Query published documents
    final published_query = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(collection))
        .where(Expression.property('PUBLISHED').equalTo(Expression.boolean(true)));

    final published_results = await published_query.execute();
    final published = await published_results.allResults();

    // Add more detailed debug logging
    print('\nPublished documents count: ${published.length}');
    for (final result in published) {
      final raw_data = result.toPlainMap();
      final doc = raw_data['_default'] as Map<String, dynamic>;
      print('\nDocument:');
      print('  Type: ${doc['DOCUMENT_TYPE']}');
      print('  Name: ${doc['DOCUMENT_NAME']}');
      print('  Published: ${doc['PUBLISHED']}');
      print('  Content: ${doc['CONTENT']}');
    }

    expect(published.length, equals(2));

    // Query published articles
    final published_articles_query =
        const QueryBuilder().select(SelectResult.all()).from(DataSource.collection(collection)).where(
              Expression.property('DOCUMENT_TYPE')
                  .equalTo(Expression.string('article'))
                  .and(Expression.property('PUBLISHED').equalTo(Expression.boolean(true))),
            );

    final published_articles_results = await published_articles_query.execute();
    final published_articles = await published_articles_results.allResults();

    expect(published_articles.length, equals(1));

    await db.close();
  });

  test('database persists and can be modified after reopening', () async {
    final db = await Database.openAsync('local-assets');
    final collection = await db.defaultCollection;

    // Create index first
    final DOCUMENT_METADATA_INDEX_CONFIG = ValueIndexConfiguration(['DOCUMENT_TYPE', 'DOCUMENT_NAME']);
    await collection.createIndex('DOCUMENT_METADATA_INDEX', DOCUMENT_METADATA_INDEX_CONFIG);

    // Create initial test documents
    final test_doc1 = MutableDocument.withId('doc1')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('First Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the first test article', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    final test_doc2 = MutableDocument.withId('doc2')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('Second Article', key: 'DOCUMENT_NAME')
      ..setValue('This is the second test article', key: 'CONTENT')
      ..setValue(false, key: 'PUBLISHED');

    final test_doc3 = MutableDocument.withId('doc3')
      ..setValue('note', key: 'DOCUMENT_TYPE')
      ..setValue('First Note', key: 'DOCUMENT_NAME')
      ..setValue('This is a test note', key: 'CONTENT')
      ..setValue(true, key: 'PUBLISHED');

    await collection.saveDocument(test_doc1);
    await collection.saveDocument(test_doc2);
    await collection.saveDocument(test_doc3);

    await db.close();

    // Reopen database and verify data
    final reopened_db = await Database.openAsync('local-assets');
    final reopened_collection = await reopened_db.defaultCollection;

    // Verify initial state
    final initial_published_query = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(reopened_collection))
        .where(Expression.property('PUBLISHED').equalTo(Expression.boolean(true)));

    final initial_published = await (await initial_published_query.execute()).allResults();
    expect(initial_published.length, equals(2));

    // Add new document
    final test_doc4 = MutableDocument.withId('doc4')
      ..setValue('article', key: 'DOCUMENT_TYPE')
      ..setValue('Fourth Article', key: 'DOCUMENT_NAME')
      ..setValue('This is another test article', key: 'CONTENT')
      ..setValue(false, key: 'PUBLISHED');

    await reopened_collection.saveDocument(test_doc4);

    // Modify existing document
    final doc1 = await reopened_collection.document('doc1');
    final updated_doc1 = doc1?.toMutable()?..setValue(false, key: 'PUBLISHED');
    await reopened_collection.saveDocument(updated_doc1!);

    // Verify updated state
    final updated_query = const QueryBuilder()
        .select(SelectResult.all())
        .from(DataSource.collection(reopened_collection))
        .where(Expression.property('PUBLISHED').equalTo(Expression.boolean(true)));

    final updated_results = await updated_query.execute();
    final updated = await updated_results.allResults();

    // Only doc3 should still be published
    expect(updated.length, equals(1));

    await reopened_db.close();
  });
}
