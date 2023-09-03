import 'dart:convert';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_sentry/cbl_sentry.dart';
import 'package:sentry/sentry.dart';

Future<void> main() async {
  await Sentry.init(
    (options) => options
      ..dsn = File.fromUri(Uri.parse('sentry_dsn.txt')).readAsStringSync()
      ..tracesSampleRate = 1
      ..addIntegration(CouchbaseLiteIntegration()),
    appRunner: runApp,
  );
  await Sentry.close();
}

late final Database db;
late final Collection users;

Future<void> runApp() async {
  await initApp();
  try {
    await doStuff();
  } finally {
    await shutDownApp();
  }
}

Future<void> initApp() => runAppTransaction('initApp', () async {
      await CouchbaseLiteDart.init(edition: Edition.community);
      await Database.remove('example');
      db = await Database.openAsync('example');
      users = await db.createCollection('users');
    });

Future<void> shutDownApp() => runAppTransaction('shutDownApp', () async {
      await db.close();
    });

Future<void> doStuff() => runAppTransaction('doStuff', () async {
      await fillDatabase();
      await queryDatabase();
      // throw Exception('Triggering exception event...');
    });

Future<void> fillDatabase() => runAppOperation('fillDatabase', () async {
      await users.saveDocument(MutableDocument({
        'name': 'Alice',
        'age': 25,
      }));
      await users.saveDocument(MutableDocument({
        'name': 'Bob',
        'age': 57,
      }));
      await users.saveDocument(MutableDocument({
        'name': 'Sohla',
        'age': 36,
      }));
    });

Future<void> queryDatabase() => runAppOperation('queryDatabase', () async {
      final query = await Query.fromN1ql(
        db,
        'SELECT * FROM users WHERE age >= 28 OR name LIKE "A%"',
      );
      final resultSet = await query.execute();
      final results = await resultSet
          .asStream()
          .map((result) => result.toPlainMap())
          .toList();

      prettyPrintJson(results);
    });

Future<T> runAppTransaction<T>(String name, Future<T> Function() fn) =>
    _runAppSpan(Sentry.startTransaction(name, 'task'), fn);

Future<T> runAppOperation<T>(String name, Future<T> Function() fn) =>
    _runAppSpan(cblSentrySpan!.startChild(name), fn);

Future<T> _runAppSpan<T>(ISentrySpan span, Future<T> Function() fn) async {
  try {
    return await runWithCblSentrySpan(span, fn);
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    span
      ..throwable = e
      ..status = const SpanStatus.internalError();
    rethrow;
  } finally {
    span.status ??= const SpanStatus.ok();
    await span.finish();
  }
}

void prettyPrintJson(Object? value) =>
    // ignore: avoid_print
    print(const JsonEncoder.withIndent('  ').convert(value));
