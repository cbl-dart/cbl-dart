import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:cbl_flutter_ce/cbl_flutter_ce.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS || Platform.isAndroid) {
    CblFlutterCe.registerWith();
  }
  await CouchbaseLiteFlutter.init();

  final db = await Database.openAsync('example');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Text('Hello Couchbase Lite!'),
        ),
      );
}
