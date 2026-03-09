import 'dart:ffi';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

export 'cblite.dart' show CBLDocument;

final class DocumentBindings {
  const DocumentBindings();

  String id(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_ID(doc).toDartString()!;

  String? revisionId(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_RevisionID(doc).toDartString();

  int sequence(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Sequence(doc);

  cblite.FLDict properties(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Properties(doc);

  String createJSON(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_CreateJSON(doc).toDartStringAndRelease()!;
}

final class MutableDocumentBindings {
  const MutableDocumentBindings();

  Pointer<cblite.CBLDocument> createWithID([String? id]) =>
      runWithSingleFLString(id, cblite.CBLDocument_CreateWithID);

  Pointer<cblite.CBLDocument> mutableCopy(Pointer<cblite.CBLDocument> source) =>
      cblite.CBLDocument_MutableCopy(source);

  cblite.FLMutableDict mutableProperties(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_MutableProperties(doc);

  void setProperties(
    Pointer<cblite.CBLDocument> doc,
    cblite.FLMutableDict properties,
  ) => cblite.CBLDocument_SetProperties(doc, properties);

  void setJSON(Pointer<cblite.CBLDocument> doc, String properties) {
    runWithSingleFLString(properties, (flProperties) {
      cblite.CBLDocument_SetJSON(
        doc,
        flProperties,
        globalCBLError,
      ).checkError();
    });
  }
}
