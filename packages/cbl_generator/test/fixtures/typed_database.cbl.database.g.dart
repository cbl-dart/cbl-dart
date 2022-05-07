// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: avoid_classes_with_only_static_members, lines_longer_than_80_chars, directives_ordering, avoid_redundant_argument_values

// **************************************************************************
// TypedDatabaseGenerator
// **************************************************************************

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data_internal.dart';
import 'typed_database.dart';
import 'document_meta_data.dart';
import 'builtin_types.dart';

class NoTypesDatabase extends $NoTypesDatabase {
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
    types: [],
  );
}

class DocWithIdDatabase extends $DocWithIdDatabase {
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
      TypedDocumentMetadata<DocWithId, MutableDocWithId>(
        dartName: 'DocWithId',
        factory: ImmutableDocWithId.internal,
        mutableFactory: MutableDocWithId.internal,
        typeMatcher: const ValueTypeMatcher(
          path: ['type'],
        ),
      ),
    ],
  );
}

class StringDictDatabase extends $StringDictDatabase {
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
      TypedDictionaryMetadata<StringDict, MutableStringDict>(
        dartName: 'StringDict',
        factory: ImmutableStringDict.internal,
        mutableFactory: MutableStringDict.internal,
      ),
    ],
  );
}

class CustomValueTypeMatcherDatabase extends $CustomValueTypeMatcherDatabase {
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
      TypedDocumentMetadata<CustomValueTypeMatcherDoc,
          MutableCustomValueTypeMatcherDoc>(
        dartName: 'CustomValueTypeMatcherDoc',
        factory: ImmutableCustomValueTypeMatcherDoc.internal,
        mutableFactory: MutableCustomValueTypeMatcherDoc.internal,
        typeMatcher: const ValueTypeMatcher(
          path: ['meta', 0, 'id'],
          value: 'Custom',
        ),
      ),
    ],
  );
}
