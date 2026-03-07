import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings/bindings.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';

bool get _vectorSearchAvailable {
  final base = CBLBindings.instance.base;
  return base.vectorSearchLibraryAvailable && base.systemSupportsVectorSearch;
}

void main() {
  setupTestBinding();

  group('IndexUpdater', () {
    apiTest(
      'update vector index',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        await collection.createIndex(
          'a',
          VectorIndexConfiguration(
            'a',
            dimensions: 2,
            centroids: 1,
            lazy: true,
          ),
        );

        final index = (await collection.index('a'))!;

        {
          final updater = await index.beginUpdate(limit: 10);
          expect(updater, isNull);
        }

        await collection.saveDocument(MutableDocument({'a': 'x'}));

        {
          final updater = (await index.beginUpdate(limit: 10))!;
          expect(updater.length, 1);
          expect(await updater.value(0), 'x');

          await updater.skipVector(0);
          await updater.finish();
        }

        {
          final updater = (await index.beginUpdate(limit: 10))!;
          expect(updater.length, 1);
          expect(await updater.value(0), 'x');

          await updater.setVector(0, [1, 2]);
          await updater.finish();
        }

        {
          final updater = await index.beginUpdate(limit: 10);
          expect(updater, isNull);
        }
      },
      skip: _vectorSearchAvailable
          ? null
          : 'Vector search not available on this system',
    );

    apiTest(
      'finish without setting or skipping all values',
      () async {
        final db = await openTestDatabase();
        final collection = await db.defaultCollection;
        await collection.createIndex(
          'a',
          VectorIndexConfiguration(
            'a',
            dimensions: 2,
            centroids: 1,
            lazy: true,
          ),
        );

        final index = (await collection.index('a'))!;

        await collection.saveDocument(MutableDocument({'a': 'x'}));

        {
          final updater = (await index.beginUpdate(limit: 10))!;
          expect(updater.length, 1);
          expect(await updater.value(0), 'x');

          await expectLater(updater.finish, throwsException);

          await updater.setVector(0, [1, 2]);
          await updater.finish();
        }

        {
          final updater = await index.beginUpdate(limit: 10);
          expect(updater, isNull);
        }
      },
      skip: _vectorSearchAvailable
          ? null
          : 'Vector search not available on this system',
    );
  });
}
