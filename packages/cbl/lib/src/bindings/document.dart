import 'dart:ffi';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

export 'cblite.dart' show CBLDocument;

final class DocumentBindings {
  static String id(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_ID(doc).toDartString()!;

  static String? revisionId(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_RevisionID(doc).toDartString();

  static int sequence(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Sequence(doc);

  static cblite.FLDict properties(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Properties(doc);

  static String createJSON(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_CreateJSON(doc).toDartStringAndRelease()!;
}

final class MutableDocumentBindings {
  static Pointer<cblite.CBLDocument> createWithID([String? id]) =>
      runWithSingleFLString(id, cblite.CBLDocument_CreateWithID);

  static Pointer<cblite.CBLDocument> mutableCopy(
    Pointer<cblite.CBLDocument> source,
  ) => cblite.CBLDocument_MutableCopy(source);

  static cblite.FLMutableDict mutableProperties(
    Pointer<cblite.CBLDocument> doc,
  ) => cblite.CBLDocument_MutableProperties(doc);

  static void setProperties(
    Pointer<cblite.CBLDocument> doc,
    cblite.FLMutableDict properties,
  ) => cblite.CBLDocument_SetProperties(doc, properties);

  static void setJSON(Pointer<cblite.CBLDocument> doc, String properties) {
    runWithSingleFLString(properties, (flProperties) {
      cblite.CBLDocument_SetJSON(
        doc,
        flProperties,
        globalCBLError,
      ).checkError();
    });
  }
}
