// ignore_for_file: avoid_print, lines_longer_than_80_chars, diagnostic_describe_all_properties

/// This simple example app allows users to view and add to a list of log
/// messages.
///
/// It demonstrates how to:
///
/// - initialize Couchbase Lite,
/// - open a database,
/// - create an index,
/// - save a new document,
/// - build a query through the query builder,
/// - explain how that query is executed,
/// - and watch that query.
library main;

import 'dart:async';

import 'package:cbl/cbl.dart';
import 'package:cbl_flutter/cbl_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  await initApp();
  runApp(const MyApp());
}

// === UI ======================================================================

const spacing = 16.0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LogMessagesPage(),
      );
}

class LogMessagesPage extends StatefulWidget {
  const LogMessagesPage({super.key});

  @override
  State<LogMessagesPage> createState() => _LogMessagesPageState();
}

class _LogMessagesPageState extends State<LogMessagesPage> {
  List<LogMessage> _logMessages = [];
  late StreamSubscription _logMessagesSub;

  @override
  void initState() {
    super.initState();
    _logMessagesSub =
        logMessageRepository.allLogMessagesStream().listen((logMessages) {
      setState(() => _logMessages = logMessages);
    });
  }

  @override
  void dispose() {
    _logMessagesSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView.builder(
                // By reversing the ListView new messages will be immediately
                // visible and when opening the page the ListView starts out
                // scrolled all the way to the bottom.
                reverse: true,
                itemCount: _logMessages.length,
                itemBuilder: (context, index) {
                  // Since the ListView is reversed, we need to access the
                  // log messages in reverse, to end up with the correct
                  // ordering.
                  final logMessage =
                      _logMessages[_logMessages.length - 1 - index];

                  return LogMessageTile(logMessage: logMessage);
                },
              ),
            ),
            const Divider(height: 0),
            _LogMessageForm(onSubmit: logMessageRepository.createLogMessage)
          ]),
        ),
      );
}

class LogMessageTile extends StatelessWidget {
  const LogMessageTile({super.key, required this.logMessage});

  final LogMessage logMessage;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMd().add_jm().format(logMessage.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: spacing / 4),
            Text(logMessage.message)
          ],
        ),
      );
}

class _LogMessageForm extends StatefulWidget {
  const _LogMessageForm({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  _LogMessageFormState createState() => _LogMessageFormState();
}

class _LogMessageFormState extends State<_LogMessageForm> {
  late final TextEditingController _messageController;
  late final FocusNode _messageFocusNode;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    widget.onSubmit(message);
    _messageController.clear();
    _messageFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(spacing),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration:
                    const InputDecoration.collapsed(hintText: 'Message'),
                autofocus: true,
                focusNode: _messageFocusNode,
                controller: _messageController,
                minLines: 1,
                maxLines: 10,
                style: Theme.of(context).textTheme.bodyMedium,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: spacing / 2),
            TextButton(
              onPressed: _onSubmit,
              child: const Text('Write to log'),
            )
          ],
        ),
      );
}

// === Log Message Storage =====================================================

/// The model of a log message.
abstract class LogMessage {
  String get id;
  DateTime get createdAt;
  String get message;
}

/// Implementation of a [LogMessage] that wraps a [DictionaryInterface], which
/// contains a log message.
///
/// [DictionaryInterface] is implemented by a few types in `cbl`:
///
/// - [Document],
/// - [Dictionary],
/// - [Result].
///
/// Accessing data through objects returned from the `cbl` API is more efficient
/// than converting them to plain Dart objects (e.g.
/// [DictionaryInterface.toPlainMap]). These objects pull only the data that is
/// accessed, out of the binary encoded, stored data.
class CblLogMessage extends LogMessage {
  CblLogMessage(this.dict);

  final DictionaryInterface dict;

  // `dict` could be a `Document` or a `Result` from a query.
  // The extension `DictionaryDocumentIdExt` handles getting the id in both
  // cases.
  @override
  String get id => dict.documentId;

  @override
  DateTime get createdAt => dict.value('createdAt')!;

  @override
  String get message => dict.value('message')!;
}

extension DictionaryDocumentIdExt on DictionaryInterface {
  /// If this is a [Document], returns its `id`, otherwise returns the [String]
  /// in the field `id`.
  String get documentId {
    final self = this;
    return self is Document ? self.id : self.value('id')!;
  }
}

/// Repository for [LogMessage]s, which abstracts data storage access.
class LogMessageRepository {
  LogMessageRepository(this.database, this.collection);

  final Database database;
  final Collection collection;

  Future<LogMessage> createLogMessage(String message) async {
    final doc = MutableDocument({
      'type': 'logMessage',
      'createdAt': DateTime.now(),
      'message': message,
    });
    await collection.saveDocument(doc);
    return CblLogMessage(doc);
  }

  Stream<List<LogMessage>> allLogMessagesStream() {
    final query = const QueryBuilder()
        .select(
          SelectResult.expression(Meta.id),
          SelectResult.property('createdAt'),
          SelectResult.property('message'),
        )
        .from(DataSource.collection(collection))
        .where(
          Expression.property('type').equalTo(Expression.value('logMessage')),
        )
        .orderBy(Ordering.property('createdAt'));

    // The line below prints an explanation of how the query will be executed.
    // This explanation should contain this line, which tells us that the query
    // uses the index we created in the `initApp` function:
    // 4|0|0| SEARCH TABLE kv_default AS example USING INDEX type+createdAt (<expr>=?)
    Future(query.explain).then(print);

    return query.changes().asyncMap(
          (change) => change.results.asStream().map(CblLogMessage.new).toList(),
        );
  }
}

// === App Setup ===============================================================

late Database database;
late Collection logMessages;
late LogMessageRepository logMessageRepository;

/// Initializes global app state.
Future<void> initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TracingDelegate.install(DevToolsTracing());

  await CouchbaseLiteFlutter.init();

  // Uncomment the line below to reset the database each time the app starts.
  // await Database.remove('example');

  database = await Database.openAsync('example');
  logMessages = await database.createCollection('logMessages');

  // This index speeds up queries, among others, that filter documents by an
  // exact `type` and sort by `createdAt`.
  await logMessages.createIndex(
    'type+createdAt',
    ValueIndex([
      ValueIndexItem.property('type'),
      ValueIndexItem.property('createdAt'),
    ]),
  );

  logMessageRepository = LogMessageRepository(database, logMessages);
}
