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
