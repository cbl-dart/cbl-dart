// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_classes_with_only_static_members, lines_longer_than_80_chars, directives_ordering, avoid_redundant_argument_values

// **************************************************************************
// TypedDatabaseGenerator
// **************************************************************************

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';
import 'app_database.dart';
import 'user.dart';

class AppDatabase extends $AppDatabase {
  static Future<AsyncDatabase> openAsync(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      // ignore: invalid_use_of_internal_member
      AsyncDatabase.openInternal(name, config, _adapter);

  static SyncDatabase openSync(
    String name, [
    DatabaseConfiguration? config,
  ]) =>
      // ignore: invalid_use_of_internal_member
      SyncDatabase.internal(name, config, _adapter);

  static final _adapter = TypedDataRegistry(
    types: [
      TypedDocumentMetadata<User, MutableUser>(
        dartName: 'User',
        factory: ImmutableUser.internal,
        mutableFactory: MutableUser.internal,
        typeMatcher: const ValueTypeMatcher(
          path: ['type'],
        ),
      ),
      TypedDictionaryMetadata<PersonalName, MutablePersonalName>(
        dartName: 'PersonalName',
        factory: ImmutablePersonalName.internal,
        mutableFactory: MutablePersonalName.internal,
      ),
    ],
  );
}
