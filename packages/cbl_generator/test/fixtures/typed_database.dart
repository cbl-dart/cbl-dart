import 'package:cbl/cbl.dart';

import 'builtin_types.dart';
import 'document_meta_data.dart';

part 'typed_database.cbl.type.g.dart';

@TypedDatabase(types: {})
class $NoTypesDatabase {}

@TypedDatabase(types: {DocWithId})
class $DocWithIdDatabase {}

@TypedDatabase(types: {StringDict})
class $StringDictDatabase {}

@TypedDocument(
  typeMatcher: ValueTypeMatcher(
    path: ['meta', 0, 'id'],
    value: 'Custom',
  ),
)
abstract class CustomValueTypeMatcherDoc with _$CustomValueTypeMatcherDoc {
  factory CustomValueTypeMatcherDoc(String value) =
      MutableCustomValueTypeMatcherDoc;
}

@TypedDatabase(types: {CustomValueTypeMatcherDoc})
class $CustomValueTypeMatcherDatabase {}
