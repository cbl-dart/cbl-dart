import 'dart:convert';

import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initFuture;
  late Database _db;

  var _posts = <Map<String, Object?>>[];

  @override
  void initState() {
    super.initState();
    CouchbaseLite.init(libraries: flutterLibraries());

    _initFuture = _init();
  }

  Future<void> _init() async {
    final appDocsDir = await getApplicationDocumentsDirectory();

    _db = Database.open(
      'Example',
      config: DatabaseConfiguration(directory: appDocsDir.path),
    );

    final query =
        _db.query(N1QLQuery('SELECT post FROM post WHERE post.type = "post"'));

    query
        .changes()
        .map((resultSet) => resultSet.asDictionaries
            .map((result) => result['post'].dictionary!.toPlainMap())
            .toList())
        .listen((posts) => setState(() => _posts = posts));
  }

  void _createPost() async {
    final post = MutableDocument({
      'type': 'post',
      'title': 'The first post',
      'content': 'Here is some content for this post.',
      'tags': ['couchbase-late', 'flutter', 'dart'],
      'author': {
        'name': 'Gabriel',
      },
    });

    _db.saveDocument(post);
  }

  void _clearDatabase() async {
    final ids = _db
        .query(N1QLQuery('SELECT META.id'))
        .execute()
        .map((r) => r[0] as String)
        .toList();

    _db.beginBatch();
    try {
      ids.map((id) => _db.purgeDocumentById(id));
    } finally {
      _db.endBatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        '${snapshot.error}',
                  ),
                );
              }

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconAndMessage(
                      icon: Icons.check,
                      iconColor: Colors.green,
                      text: 'Initialized',
                    ),
                    SizedBox(height: 32),
                    ButtonBar(
                      alignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _createPost,
                          child: Text('Crate a Post'),
                        ),
                        ElevatedButton(
                          onPressed: _clearDatabase,
                          child: Text('Clear Database'),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            const JsonEncoder.withIndent('  ').convert(_posts),
                            style: TextStyle(fontFamily: ''),
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
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
          padding: EdgeInsets.all(16),
          child: Icon(
            icon,
            size: 48,
            color: iconColor,
          ),
        ),
        SizedBox(height: 32),
        Text(text),
      ],
    );
  }
}
