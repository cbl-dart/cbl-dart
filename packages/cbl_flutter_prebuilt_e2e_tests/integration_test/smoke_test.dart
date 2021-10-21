import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:cbl_flutter_ee/cbl_flutter_ee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('initialize and use Couchbase Lite', (tester) async {
    if (Platform.isAndroid || Platform.isIOS) {
      CblFlutterEe.registerWith();
    }
    await CouchbaseLiteFlutter.init();

    final db = await Database.openAsync('init-and-use-test');
    expect(db.name, 'init-and-use-test');

    final doc = MutableDocument({'message': 'Hello Couchbase Lite!'});
    await db.saveDocument(doc);
    expect(doc.revisionId, isNotNull);
  });
}
