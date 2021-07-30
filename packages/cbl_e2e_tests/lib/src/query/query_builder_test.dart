import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  group('QueryBuilder', () {
    test('SelectResult.all()', () {
      final db = openTestDb('QueryBuilderSmoke');

      db.saveDocument(MutableDocument({'a': true}));

      final result = QueryBuilder.selectOne(SelectResult.all())
          .from(DataSource.database(db))
          .execute()
          .map((result) => result.toPlainMap())
          .toList();

      expect(result, [
        {
          db.name: {'a': true}
        }
      ]);
    });
  });
}
