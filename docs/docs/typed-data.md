# Typed Data

:::caution

The typed data API is **experimental** and might be missing some feature that
you need. Please file an [issue][issues] if you find a bug or have a feature
request.

:::

Couchbase Lite allows dynamic access to data without a fixed data model, not
requiring any code generation. This is useful when the data is very dynamic or
code generation is undesirable.

Often though, the data is known to have a regular structure, and accessing it
through a typed Dart API makes working with it easier and safer.

With the help of the `api|cbl_generator|pkg:` package you can quickly create
Dart classes that can be used to access data in a typed way. Theses classes can
be used with specialized APIs of `api|Database`, `api|Query` and
`api|Replicator`.

## Getting started

1. Make sure your [app is setup](install.md) for using Couchbase Lite.

1. Add `api|cbl_generator|pkg:` and `api|build_runner|pkg:` as development
   dependencies:

   ```shell
   flutter pub add --dev cbl_generator build_runner
   ```

1. Create typed data classes and annotated them with `api|TypedDocument` and
   `api|TypedDictionary`:

   ```dart
   // user.dart

   import 'package:cbl/cbl.dart';

   // Declare the part file into which the generated code will be written.
   part 'user.cbl.type.g.dart';

   // Per default the type of a document is encoded in the `type` property in
   // the underlying data. The value is a string that is the name of the annotated
   // class. This can be customized by setting `TypedDocument.typeMatcher`.
   @TypedDocument()
   abstract class User with _$User {
     factory User({
       @DocumentId() String? id,
       required PersonalName name,
       String? email,
       required String username,
       required DateTime createdAt,
     }) = MutableUser;
   }

   @TypedDictionary()
   abstract class PersonalName with _$PersonalName {
     factory PersonalName({
       required String first,
       required String last,
     }) = MutablePersonalName;
   }
   ```

1. Create a typed database by annotating a class with `api|TypedDatabase`:

   ```dart
   // app_database.dart

   import 'package:cbl/cbl.dart';

   import 'user.dart';

   @TypedDatabase(
     // List all the typed data classes that will be used in the database.
     types: {
       User,
       PersonalName,
     },
   )
   abstract class $AppDatabase {}
   ```

1. Run the build runner to invoke the generator:

   ```shell
   dart run build_runner build
   # or
   flutter run build_runner build
   ```

1. Open an instance of the typed database and use it:

   ```dart
   import 'app_database.cbl.database.g.dart';
   import 'user.dart';

   Future<void> useTypedDatabase() {
     // Use a static method on the generated typed database class to open an instance.
     final db = await AppDatabase.openAsync('app');

     // Every typed data class has a mutable and immutable variant. The mutable
     // class has the same name as the immutable class, but with the `Mutable`
     // suffix. A mutable instance can be created by constructing it, or from
     // an immutable instance, through the `toMutable` method.
     final user = MutableUser(
       name: PersonalName(first: 'Alice', last: 'Green'),
       email: 'alice@green.com',
       username: 'ali',
       createdAt: DateTime.now(),
     );

     // The API to save typed documents is slightly different than the API to
     // save plain documents. `saveTypedDocument` returns an object that has methods
     // for saving the document with conflict resolution through concurrency control or
     // a custom conflict handler.
     await db.saveTypedDocument(user).withConcurrencyControl();

     // To retrieve a typed document, use the `typedDocument` method and pass it the
     // type of the requested document through the type parameter.
     final savedUser = await db.typedDocument<User>(user.id);
   }
   ```
