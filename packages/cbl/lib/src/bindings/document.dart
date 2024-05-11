// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, camel_case_types, avoid_private_typedef_functions

import 'dart:ffi';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

typedef CBLDocument = cblite.CBLDocument;

final class DocumentBindings {
  const DocumentBindings();

  String id(Pointer<CBLDocument> doc) =>
      cblite.CBLDocument_ID(doc).toDartString()!;

  String? revisionId(Pointer<CBLDocument> doc) =>
      cblite.CBLDocument_RevisionID(doc).toDartString();

  int sequence(Pointer<CBLDocument> doc) => cblite.CBLDocument_Sequence(doc);

  FLDict properties(Pointer<CBLDocument> doc) =>
      cblite.CBLDocument_Properties(doc);

  String createJSON(Pointer<CBLDocument> doc) =>
      cblite.CBLDocument_CreateJSON(doc).toDartStringAndRelease()!;
}

typedef CBLMutableDocument = CBLDocument;

final class MutableDocumentBindings {
  const MutableDocumentBindings();

  Pointer<CBLMutableDocument> createWithID([String? id]) =>
      runWithSingleFLString(id, cblite.CBLDocument_CreateWithID);

  Pointer<CBLMutableDocument> mutableCopy(Pointer<CBLDocument> source) =>
      cblite.CBLDocument_MutableCopy(source);

  FLMutableDict mutableProperties(Pointer<CBLMutableDocument> doc) =>
      cblite.CBLDocument_MutableProperties(doc);

  void setProperties(
    Pointer<CBLMutableDocument> doc,
    FLMutableDict properties,
  ) =>
      cblite.CBLDocument_SetProperties(doc, properties);

  void setJSON(Pointer<CBLMutableDocument> doc, String properties) {
    runWithSingleFLString(properties, (flProperties) {
      cblite.CBLDocument_SetJSON(doc, flProperties, globalCBLError)
          .checkCBLError();
    });
  }
}
