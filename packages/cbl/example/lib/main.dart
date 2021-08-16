// ignore_for_file: avoid_print

import 'package:cbl/cbl.dart';

/// You need to specify how to access the native libraries, on top of which
/// `cbl` is implemented.
///
/// For Flutter apps you can get the [Libraries] from the `cbl_flutter` package
/// from the `flutterLibraries` function.
Libraries getLibraries() {
  throw UnimplementedError('TODO');
}

Future<void> main() async {
  // The `cbl` package needs to be initialized before it can be used.
  CouchbaseLite.init(libraries: getLibraries());

  // Now open a database.
  final db = await Database.open('chat-messages');

  // To create a new document start with an empty [MutableDocument] and fill
  // its properties.
  final doc = MutableDocument({
    'type': 'message',
    'body': 'Heyo',
    'from': 'Alice',
  });

  // Saving a document will return an immutable [Document].
  await db.saveDocument(doc);

  print(doc);
  print(doc.toPlainMap());

  await db.close();
}
