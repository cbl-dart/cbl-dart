# Usage Examples

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

Check out the documentation for [`Database.saveDocument`][database.savedocument]
to learn about how conflicts are handled.

## Delete a document

To delete a document, you need to read it first and than pass it to
`Database.deleteDocument`:

```dart
final doc = await db.document('ali');

await db.deleteDocument(doc);
```

Check out the documentation for
[`Database.deleteDocument`][database.deletedocument] to learn about how
conflicts are handled.

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

[n1ql]: https://www.couchbase.com/products/n1ql
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
[database.savedocument]:
  https://pub.dev/documentation/cbl/latest/cbl/Database/saveDocument.html
[database.deletedocument]:
  https://pub.dev/documentation/cbl/latest/cbl/Database/deleteDocument.html
