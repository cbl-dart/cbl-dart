// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';

late final Database db;

Future<void> main(List<String> args) async {
  if (args.contains('--help') ||
      args.contains('-h') ||
      (args.isNotEmpty && args.length != 1)) {
    print(
      '''
Usage: dart lib/main.dart [message]

The provided message will be stored in the database.

If no message is provided, all stored messages will be listed.
''',
    );
    exit(1);
  }

  await CouchbaseLiteDart.init(edition: Edition.community);

  db = await Database.openAsync('messages');

  final message = args.isEmpty ? null : args[0];

  if (message != null) {
    await storeMessage(message);
  } else {
    await listMessages();
  }

  await db.close();
}

Future<void> storeMessage(String message) async {
  final doc = MutableDocument({
    'type': 'message',
    'createdAt': DateTime.now(),
    'body': message,
  });

  await db.saveDocument(doc);

  print('Message ${doc.id} stored: ${doc.toJson()}');
}

Future<void> listMessages() async {
  final query = const QueryBuilder()
      .select(
        SelectResult.expression(Meta.id),
        SelectResult.property('createdAt'),
        SelectResult.property('body'),
      )
      .from(DataSource.database(db))
      .where(Expression.property('type').equalTo(
        Expression.string('message'),
      ))
      .orderBy(Ordering.property('createdAt').descending());

  final resultSet = await query.execute();
  var messages = 0;

  await for (final result in resultSet.asStream()) {
    messages++;
    print(result.toJson());
  }

  print('$messages messages found');
}
