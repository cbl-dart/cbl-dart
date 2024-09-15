import 'package:cbl/cbl.dart';

Future<void> main() async {
  // Couchbase Lite needs to be initialized before it can be used.
  await CouchbaseLite.init();

  final db = await Database.openAsync('chat-app');
  final messages = await db.createCollection('messages');

  final doc = MutableDocument({
    'type': 'message',
    'body': 'Heyo',
    'from': 'Alice',
  });

  await messages.saveDocument(doc);

  await db.close();
}
