import 'dart:convert';

import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initFuture;
  late AsyncDatabase _db;

  var _posts = <Map<String, Object?>>[];

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    await CouchbaseLiteFlutter.init();

    _db = await Database.openAsync('Example');

    final query = await Query.fromN1qlAsync(
      _db,
      'SELECT post FROM _ AS post WHERE post.type = "post"',
    );

    query
        .changes()
        .asyncMap((resultSet) => resultSet
            .asStream()
            .map((result) => result['post'].dictionary!.toPlainMap())
            .toList())
        .listen((posts) => setState(() => _posts = posts));
  }

  Future<void> _createPost() async {
    final post = MutableDocument({
      'type': 'post',
      'title': 'The first post',
      'content': 'Here is some content for this post.',
      'tags': ['couchbase-late', 'flutter', 'dart'],
      'author': {
        'name': 'Gabriel',
      },
    });

    await _db.saveDocument(post);
  }

  Future<void> _clearDatabase() async {
    final ids = await Query.fromN1qlAsync(_db, 'SELECT META().id FROM _')
        .then((query) => query.execute())
        .then((resultSet) =>
            resultSet.asStream().map((result) => result[0].string!).toList());

    await _db
        .inBatch(() => Future.wait(ids.map((id) => _db.purgeDocumentById(id))));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Initializing...')
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: IconAndMessage(
                      icon: Icons.close,
                      iconColor: Colors.red,
                      text: 'Initialization failed:\n'
                          '${snapshot.error}\n${snapshot.stackTrace}',
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const IconAndMessage(
                        icon: Icons.check,
                        iconColor: Colors.green,
                        text: 'Initialized',
                      ),
                      const SizedBox(height: 32),
                      ButtonBar(
                        alignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _createPost,
                            child: const Text('Crate a Post'),
                          ),
                          ElevatedButton(
                            onPressed: _clearDatabase,
                            child: const Text('Clear Database'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              const JsonEncoder.withIndent('  ')
                                  .convert(_posts),
                              style: const TextStyle(fontFamily: ''),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class IconAndMessage extends StatelessWidget {
  const IconAndMessage({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.text,
  }) : super(key: key);

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 6),
                )
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(text),
        ],
      );
}
