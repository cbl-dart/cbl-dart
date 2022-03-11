[![Version](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)
[![License](https://badgen.net/pub/license/cbl)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

Couchbase Lite is an embedded, NoSQL JSON Document Style database, supporting
Blobs, Encryption, N1QL Queries, Live Queries, Full-Text Search and Data Sync.

It can be used as a standalone embedded database for mobile or desktop apps. Or
it can be combined with [Sync Gateway] to synchronize with a central data store.

---

❤️ If you find this package useful, please ⭐ us on [pub.dev][cbl] and
[GitHub][repository]. 🙏

🐛 & ✨ Did you find a bug or have a feature request? Please open a [GitHub
issue][issues].

👋 Do you you have a question or feedback? Let us know in a [GitHub
discussion][discussions].

---

**What are all these packages for?**

Couchbase Lite can be used with **standalone Dart** or with **Flutter** apps and
comes in two editions: **Community** and **Enterprise**.

Regardless of the app platform and edition of Couchbase Lite you use, you always
need the `cbl` package. All of the APIs of Couchbase Lite live in this package.

What other packages you need depends on the app platform and the edition of
Couchbase Lite you use.

| Package          | Required when you want to:                                                                                 | Pub                                          | Likes                                         | Points                                         | Popularity                                         |
| ---------------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------- | --------------------------------------------- | ---------------------------------------------- | -------------------------------------------------- |
| [cbl]            | use Couchbase Lite.                                                                                        | ![](https://badgen.net/pub/v/cbl)            | ![](https://badgen.net/pub/likes/cbl)         | ![](https://badgen.net/pub/points/cbl)         | ![](https://badgen.net/pub/popularity/cbl)         |
| [cbl_dart]       | use the **Community** or **Enterprise Edition** in a **standalone Dart** app or in **Flutter unit tests**. | ![](https://badgen.net/pub/v/cbl_dart)       | ![](https://badgen.net/pub/likes/cbl_dart)    | ![](https://badgen.net/pub/points/cbl_dart)    | ![](https://badgen.net/pub/popularity/cbl_dart)    |
| [cbl_flutter]    | use Couchbase Lite in a **Flutter app**.                                                                   | ![](https://badgen.net/pub/v/cbl_flutter)    | ![](https://badgen.net/pub/likes/cbl_flutter) | ![](https://badgen.net/pub/points/cbl_flutter) | ![](https://badgen.net/pub/popularity/cbl_flutter) |
| [cbl_flutter_ce] | use the **Community Edition** in a Flutter app.                                                            | ![](https://badgen.net/pub/v/cbl_flutter_ce) |                                               |                                                |                                                    |
| [cbl_flutter_ee] | use the **Enterprise Edition** in a Flutter app.                                                           | ![](https://badgen.net/pub/v/cbl_flutter_ee) |                                               |                                                |                                                    |
| [cbl_sentry]     | integrate Couchbase Lite with Sentry in a Dart or Flutter app.                                             | ![](https://badgen.net/pub/v/cbl_sentry)     | ![](https://badgen.net/pub/likes/cbl_sentry)  | ![](https://badgen.net/pub/points/cbl_sentry)  | ![](https://badgen.net/pub/popularity/cbl_sentry)  |

### Table of contents

- [🤩 Features](#-features)
- [⛔ Limitations](#-limitations)
- [🔌 Getting started](#-getting-started)
- [🔑 Key concepts](#-key-concepts)
  - [Synchronous and Asynchronous APIs](#synchronous-and-asynchronous-apis)
  - [Change listeners](#change-listeners)
  - [Change streams](#change-streams)
  - [Closing resources](#closing-resources)
- [📖 Usage examples](#-usage-examples)
  - [Open a database](#open-a-database)
  - [Create a document](#create-a-document)
  - [Read a document](#read-a-document)
  - [Update a document](#update-a-document)
  - [Delete a document](#delete-a-document)
  - [Build a `Query` with the `QueryBuilder` API](#build-a-query-with-the-querybuilder-api)
  - [Build a `Query` with N1QL](#build-a-query-with-n1ql)
  - [Data sync with `Replicator` to Sync Gateway](#data-sync-with-replicator-to-sync-gateway)
- [🔮 Tracing](#-tracing)
- [💡 Where to go next](#-where-to-go-next)
- [🤝 Contributing](#-contributing)
- [⚖️ Disclaimer](#️-disclaimer)

# 🤩 Features

- Offline first
- Documents
  - Schemaless
  - Stored in efficient binary format
- Blobs
  - Store binary data, for example JPGs or PDFs
- Queries
  - Write queries for JSON data with SQL semantics
  - Construct queries through a type safe builder API
  - Write queries in [N1QL]
  - Full-Text Search
  - Indexing
- Data Sync
  - With remote [Sync Gateway]
  - Intra-device Sync **\***
  - Delta Sync **\***
- Data Conflict Handling
- Change observer APIs for:
  - Database
  - Query
  - Replicator
- Encryption
  - Full database on device **\***

**\***: **Enterprise Edition** only feature

# ⛔ Limitations

Some of the features supported by other platform implementation of Couchbase
Lite are currently not supported:

- Predictive Queries
- Peer-to-Peer Data Sync
- Background Data Sync on iOS and Android
- Integration with system-wide configured proxies
- VPN On Demand on iOS

# 🔌 Getting started

To use Couchbase Lite in a

- **Standalone Dart** app go to [`cbl_dart`][cbl_dart]
- **Flutter** app go to [`cbl_flutter`][cbl_flutter]

and follow the instructions for getting started.

# 🔑 Key concepts

## Synchronous and Asynchronous APIs

The whole Couchbase Lite API comes in both a synchronous and asynchronous
version. The synchronous version is more efficient and slightly more convenient
to use, but has the downside that it blocks the current [isolate].

In UI applications, such as Flutter apps, this is problematic. Blocking the UI
isolate for too long causes janky animations, or worse, makes the app
unresponsive. With only a synchronous API available, the solution would be to
offload the work to a worker isolate. That is what the asynchronous API does in
a transparent way.

Unless you are noticing the performance impact of the overhead of the
asynchronous API, use the asynchronous API.

To support writing code that works with both synchronous and asynchronous APIs,
synchronous and asynchronous APIs always extend from a common base class that
uses `FutureOr` wherever a result could be synchronous or asynchronous.

Take for example this simplified version of the `Query` API:

```dart
abstract class Query {
  // The common base class leaves open whether the results are returned
  // synchronously or asynchronously.
  FutureOr<ResultSet> execute();
}

abstract class SyncQuery extends Query {
  // The synchronous version of `Query` returns results directly.
  ResultSet execute();
}

abstract class AsyncQuery extends Query {
  // The asynchronous version of `Query` returns results in a `Future`.
  Future<ResultSet> execute();
}
```

`FutureOr` can be awaited just like a `Future`, so by programming against
`Query` your code works with both the synchronous and asynchronous API:

```dart
/// Runs a query that returns a result set with one row and one column and
/// returns its value.
Future<int> runCountQuery(Query query) {
  final resultSet = await query.execute();
  final results = await resultSet.allResults();
  // Returns the first column of the first row.
  return result[0].integer(0);
}
```

## Change listeners

Certain objects allow you to register change listeners. In the case of
synchronous APIs, all changes are delivered to the listeners as soon as they are
registered.

With asynchronous APIs, changes are only guaranteed to be delivered once the
`Future` returned from the registration call is completed:

```dart
// Await the future returned from the registration call.
await db.addChangeListener((change) {
  print('Ids of changed documents: ${change.documentIds}'):
});

// The listener is guaranteed to be notified of this change.
await db.saveDocument(MutableDocument.withId('Hey'));
```

To stop receiving notifications, call `removeChangeListener` with the token that
was returned from the registration call. Regardless of the whether the API is
synchronous or asynchronous, listeners will stop receiving notifications
immediately:

```dart
final token = await db.addChangeListener((change) { });

// Some time goes by...

await db.removeChangeListener(token);
```

## Change streams

Streams are a convenient alternative to listen for changes. Similarly to change
listeners, change streams returned from synchronous APIs are receiving changes
as soon as the stream is subscribed to.

Streams returned from asynchronous APIs start to listen asynchronously. But it's
not possible to return a `Future` from `Stream.listen` to signal the point in
time after which the the stream will observe events. Instead, asynchronous APIs
return [`AsyncListenStream`][asynclistenstream]s, which expose a `Future` in
`AsyncListenStream.listening` that completes when the stream is fully listening:

```dart
final stream = db.changes();

stream.listen((change) {
  print('Ids of changed documents: ${change.documentIds}'):
});

// Await the Future exposed by the stream.
await stream.listening;

// The stream is guaranteed to be notified of this change.
await db.saveDocument(MutableDocument.withId('Hey'));
```

If you only ever open the same physical database once at a time, you don't need
to await the `listening` future. In this case the stream will always observe all
subsequent events.

To stop listening to changes just cancel the subscription, like with any other
stream.

## Closing resources

Some types implement [`ClosableResource`][closableresource]. At the moment these
are [`Database`][database] and [`Replicator`][replicator]. Once you are done
with an instance of these types, call its `close` method. This will free
resources used by the object, as well as remove listeners, close streams and
close child resources. For example closing a database will also close any
associated replicators.

# 📖 Usage examples

## Open a database

Every [`Database`][database] has a name which is used to determine its filename.
The full filename is the concatenation of the database name and the extension
`.cblite2`.

When opening a database without specifying a directory it will be put into a
default location that is platform dependent:

```dart
final db = await Database.openAsync('my-database');
```

If you want to open a database in a specific directory you can specify the
directory like this:

```dart
final db = await Database.openAsync(
  'my-database',
  DatabaseConfiguration(directory: 'my-directory')
);
```

If a database with the same name already exists in the directory, it will be
opened. Otherwise a new database will be created.

When you are done with the database, you should close it by calling
`Database.close`. This will free up any resources used by the database, as well
as remove change listeners, close change streams and close associated
replicators.

## Create a document

The default constructor of [`MutableDocument`][mutabledocument] creates a
document with a randomly generated id and optionally initializes it with some
properties:

```dart
final doc = MutableDocument({
  'name': 'Alice',
  'age': 29,
});

await db.saveDocument(doc);
```

It's also possible to create a document with a specific id:

```dart
final doc = MutableDocument.withId('ali', {
  'name': 'Alice',
  'age': 29,
});

await db.saveDocument(doc);
```

## Read a document

To read a [`Document`][document] pass the document's id to `Database.document`:

```dart
final doc = await db.document('ali');

// If the document exists, an immutable `Document` is returned.
if (doc != null) {
  print('Name: ${doc.string('name')}');
  print('Age: ${doc.string('age')}');
}
```

## Update a document

To update a document, first read it, turn it into a
[`MutableDocument`][mutabledocument] and update its properties. Then save it
again with `Database.saveDocument`:

```dart
final doc = await db.document('ali');

final mutableDoc = doc!.toMutable();

// You can use one of the typed setters to update the document's properties.
mutableDoc.setArray(MutableArray(['Dart']), key: 'languages');

// Or alternatively, use this subscript syntax to get a [MutableFragment] and
// use it to update the document.
mutableDoc['languages'].array = MutableArray(['Dart']);

// The untyped `setValue` setter does the conversion from a plain Dart collection
// to a document collection (`MutableArray` or `MutableDictionary`) for you.
mutableDoc.setValue(['Dart'], key: 'languages');

// Again, there is an alternative subscript syntax available.
mutableDoc['languages'].value = ['Dart'];


await db.saveDocument(mutableDoc);
```

Check out the documentation for
[`Database.saveDocument`](https://pub.dev/documentation/cbl/latest/cbl/Database/saveDocument.html)
to learn about how conflicts are handled.

## Delete a document

To delete a document, you need to read it first and than pass it to
`Database.deleteDocument`:

```dart
final doc = await db.document('ali');

await db.deleteDocument(doc);
```

Check out the documentation for
[`Database.deleteDocument`](https://pub.dev/documentation/cbl/latest/cbl/Database/deleteDocument.html)
to learn about how conflicts are handled.

## Build a `Query` with the `QueryBuilder` API

A [`Query`][query] can be built in a type safe way through the
[`QueryBuilder`][querybuilder] API.

The query below returns the average age of people with the same name:

```dart
final query = const QueryBuilder()
  .select(
    SelectResult.property('name'),
    SelectResult.expression(
      Function_.avg(Expression.property('age'))
    ).as('avgAge'),
  )
  .from(DataSource.database(db))
  .groupBy(Expression.property('name'));

final resultSet = await query.execute();
final results = await resultSet
  .asStream()
  // Converts each result into a `Map`, consisting only of plain Dart values.
  .map((result) => result.toPlainMap())
  .toList();

print(results);
```

Given these documents:

```dart
[
  {'name': 'Alice', 'age': 29},
  {'name': 'Bob', 'age': 45},
  {'name': 'Alice', 'age': 16},
]
```

`results` will be:

```dart
[
  {'name': 'Alice', 'avgAge': 22.5},
  {'name': 'Bob', 'avgAge': 45},
]
```

## Build a `Query` with N1QL

[N1QL] is a query language that is similar to SQL but for JSON style data.

The query below is equivalent to query from the `QueryBuilder` example above:

```dart
final query = await Query.fromN1ql(
  db,
  '''
  SELECT name, avg(age) AS avgAge
  FROM _
  GROUP BY name
  ''',
);
```

## Data sync with `Replicator` to Sync Gateway

This example synchronizes the database with a remote Sync Gateway instance,
without authentication. This only works when Sync Gateway has been configured
with the `GUEST` user.

A [`ReplicatorConfiguration`][replicatorconfiguration] with only default values
creates a [`Replicator`][replicator] with `type` `ReplicatorType.pushAndPull`
that is not `continuous`.

After starting this replicator, it will push changes from the local database to
the remote database and pull changes from the remote database to the local
database and then stop again.

Both `Replicator.start` and `Replicator.stop` don't immediately start/stop the
replicator. The current status of the replicator is available in
`Replicator.status.activity`.

```dart
final replicator = await Replicator.create(ReplicatorConfiguration(
  database: db,
  target: UrlEndpoint('http://localhost:4984/my-database'),
));

await replicator.addChangeListener((change) {
    print('Replicator activity: ${change.status.activity}');
});

await replicator.start();
```

When you are done with the replicator, you should close it by calling
`Replicator.close`. This will free up any resources used by the replicator, as
well as remove change listeners and close change streams.

# 🔮 Tracing

The execution of certain operations can be traced through the tracing API. This
is useful for debugging and performance profiling.

CBL Dart has builtin trace points at which flow control is given to the
currently installed `TracingDelegate`.

Included in this package is the `DevToolsTracing` delegate, which records
timeline events that can be later visualized through the Dart DevTools
Performance Page.

You can install a delegate by calling `TracingDelegate.install`:

```dart
await TracingDelegate.install(DevToolsTracing());
```

The Sentry integration provided by [`cbl_sentry`][cbl_sentry] installs a
`TracingDelegate` to transparently record breadcrumbs and transaction spans.

# 💡 Where to go next

- [API Reference]: The Dart API is well documented and organized into topics.
- [Couchbase Lite Swift Docs]: For more information on Couchbase Lite concepts.
  The Swift API is very similar to the Dart API.
- [N1QL Language Reference]
- [Sync Gateway Docs]

# 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# ⚖️ Disclaimer

> ⚠️ This is not an official Couchbase product.

[repository]: https://github.com/cbl-dart/cbl-dart
[contributing]: https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md
[n1ql]: https://www.couchbase.com/products/n1ql
[n1ql language reference]:
  https://docs.couchbase.com/server/current/n1ql/n1ql-language-reference/index.html
[couchbase lite swift docs]:
  https://docs.couchbase.com/couchbase-lite/3.0/swift/quickstart.html
[cbl]: https://pub.dev/packages/cbl
[cbl_dart]: https://pub.dev/packages/cbl_dart
[cbl_flutter]: https://pub.dev/packages/cbl_flutter
[cbl_flutter_ce]: https://pub.dev/packages/cbl_flutter_ce
[cbl_flutter_ee]: https://pub.dev/packages/cbl_flutter_ee
[cbl_sentry]: https://pub.dev/packages/cbl_sentry
[issues]: https://github.com/cbl-dart/cbl-dart/issues
[discussions]: https://github.com/cbl-dart/cbl-dart/discussions
[sync gateway]: https://www.couchbase.com/sync-gateway
[sync gateway docs]:
  https://docs.couchbase.com/sync-gateway/3.0/introduction.html
[api reference]: https://pub.dev/documentation/cbl/latest/
[isolate]: https://api.dart.dev/stable/2.16.1/dart-isolate/Isolate-class.html
[asynclistenstream]:
  https://pub.dev/documentation/cbl/latest/cbl/AsyncListenStream-class.html
[closableresource]:
  https://pub.dev/documentation/cbl/latest/cbl/ClosableResource-class.html
[database]: https://pub.dev/documentation/cbl/latest/cbl/Database-class.html
[replicator]: https://pub.dev/documentation/cbl/latest/cbl/Replicator-class.html
[replicatorconfiguration]:
  https://pub.dev/documentation/cbl/latest/cbl/ReplicatorConfiguration-class.html
[query]: https://pub.dev/documentation/cbl/latest/cbl/Query-class.html
[querybuilder]:
  https://pub.dev/documentation/cbl/latest/cbl/QueryBuilder-class.html
[document]: https://pub.dev/documentation/cbl/latest/cbl/Document-class.html
[mutabledocument]:
  https://pub.dev/documentation/cbl/latest/cbl/MutableDocument-class.html
