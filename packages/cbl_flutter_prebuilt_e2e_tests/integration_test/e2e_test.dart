import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize and use Couchbase Lite', (tester) async {
    await CouchbaseLiteFlutter.init();

    final db = await Database.openAsync('init-and-use-test');
    final collection = await db.defaultCollection;
    expect(db.name, 'init-and-use-test');

    final doc = MutableDocument({'message': 'Hello Couchbase Lite!'});
    await collection.saveDocument(doc);
    expect(doc.revisionId, isNotNull);
  });
}
