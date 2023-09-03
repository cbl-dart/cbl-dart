// ignore_for_file: avoid_print

import 'package:cbl/cbl.dart';

/// You need to specify how to access the native libraries, on top of which
/// `cbl` is implemented.
LibrariesConfiguration getLibraries() {
  throw UnimplementedError('TODO');
}

Future<void> main() async {
  // Couchbase Lite needs to be initialized before it can be used.
  await CouchbaseLite.init(libraries: getLibraries());

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
