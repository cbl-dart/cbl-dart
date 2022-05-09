// user.dart

import 'package:cbl/cbl.dart';

// Declare the part file into which the generated code will be written.
part 'user.cbl.type.g.dart';

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
