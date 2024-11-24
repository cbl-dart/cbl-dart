import 'dart:isolate' as isolate;

import 'package:cbl/cbl.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/api_variant.dart';
import '../utils/database_utils.dart';

void main() {
  setupTestBinding();

  apiTest('register and unregister model', () async {
    Database.prediction.registerModel('uppercase', UppercaseModel());
    Database.prediction.unregisterModel('uppercase');
  });

  apiTest('output from model is used in query', () async {
    registerModelForTest('uppercase', UppercaseModel());

    final db = await openTestDatabase();
    final users = await db.createCollection('users');
    await users.saveDocument(MutableDocument({'name': 'Alice'}));
    final query = await db.createQuery(
      '''
      SELECT PREDICTION(uppercase, {"in": name}, "out") AS prediction
      FROM users
      ''',
    );
    final resultSet = await query.execute();
    final results = await resultSet.allPlainMapResults();
    expect(results, [
      {'prediction': 'ALICE'}
    ]);
  });

  apiTest('register model in separate isolate', () async {
    final modelIsolate = await isolate.Isolate.spawn(
      uppercaseModelIsolate,
      CouchbaseLite.context,
    );
    addTearDown(modelIsolate.kill);

    final db = await openTestDatabase();
    final users = await db.createCollection('users');
    await users.saveDocument(MutableDocument({'name': 'Alice'}));
    final query = await db.createQuery(
      '''
      SELECT PREDICTION(uppercase, {"in": name}, "out") AS prediction
      FROM users
      ''',
    );
    final resultSet = await query.execute();
    final results = await resultSet.allPlainMapResults();
    expect(results, [
      {'prediction': 'ALICE'}
    ]);
  });

  apiTest('no output from model is handled as MISSING', () async {
    registerModelForTest('noop', NoOpModel());

    final db = await openTestDatabase();
    final users = await db.createCollection('users');
    await users.saveDocument(MutableDocument({'name': 'Alice'}));
    final query = await db.createQuery(
      '''
      SELECT PREDICTION(noop, {}) IS MISSING
      FROM users
      ''',
    );
    final resultSet = await query.execute();
    final results = await resultSet.allPlainListResults();
    expect(results, [
      {true}
    ]);
  });

  apiTest('handle exception thrown by model', () async {
    registerModelForTest('throwing', ThrowingModel());

    final db = await openTestDatabase();
    final users = await db.createCollection('users');
    await users.saveDocument(MutableDocument({'name': 'Alice'}));
    final query = await db.createQuery(
      '''
      SELECT PREDICTION(throwing, {}) IS MISSING
      FROM users
      ''',
    );
    final resultSet = await query.execute();
    final results = await resultSet.allPlainListResults();
    expect(results, [
      {true}
    ]);
  });
}

void registerModelForTest(String name, PredictiveModel model) {
  Database.prediction.registerModel(name, model);
  addTearDown(() => Database.prediction.unregisterModel(name));
}

Future<void> uppercaseModelIsolate(Object context) async {
  await CouchbaseLite.initSecondary(context);
  Database.prediction.registerModel('uppercase', UppercaseModel());
}

class UppercaseModel implements PredictiveModel {
  @override
  Dictionary? predict(Dictionary input) =>
      MutableDictionary({'out': input.string('in')!.toUpperCase()});
}

class ThrowingModel implements PredictiveModel {
  @override
  Dictionary? predict(Dictionary input) => throw UnimplementedError();
}

class NoOpModel implements PredictiveModel {
  @override
  Dictionary? predict(Dictionary input) => null;
}
