import 'dart:io';

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
  await CouchbaseLite.initialize(libraries: getLibraries());

  // Now open a database.
  final db = await CouchbaseLite.instance.openDatabase(
    'DB',
    config: DatabaseConfiguration(directory: Directory.current.path),
  );

  // To create a new document start with an empty [MutableDocument] and fill
  // its properties.
  final doc = MutableDocument()
    ..properties.addAll({
      'type': 'message',
      'body': 'Heyo',
      'from': 'Alice',
    });

  // Saving a document will return an immutable [Document].
  final savedDoc = await db.saveDocument(doc);

  print(savedDoc);
  print(savedDoc.properties);

  await db.close();

  // If you are completely done using the `cbl` package and have closed all
  // resources, you should clean up global resources, which the package creates
  // during [CouchbaseLite.initialize].
  await CouchbaseLite.dispose();
}
