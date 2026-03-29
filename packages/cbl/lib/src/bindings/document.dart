import 'dart:convert';
import 'dart:ffi';

import '../support/isolate.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';

export 'cblite.dart' show CBLDocument;

final class DocumentBindings {
  static String id(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_ID(doc).toDartString()!;

  static String? revisionId(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_RevisionID(doc).toDartString();

  static int sequence(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Sequence(doc);

  static int timestamp(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Timestamp(doc);

  static cblite.FLDict properties(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_Properties(doc);

  static String createJSON(Pointer<cblite.CBLDocument> doc) =>
      cblite.CBLDocument_CreateJSON(doc).toDartStringAndRelease()!;
}

final class MutableDocumentBindings {
  static Pointer<cblite.CBLDocument> createWithID([String? id]) {
    ensureInitializedForCurrentIsolate();
    if (id == null) {
      return cblitedart.CBLDart_CBLDocument_CreateWithID(nullptr, 0);
    }
    final encoded = utf8.encode(id);
    return cblitedart.CBLDart_CBLDocument_CreateWithID(
      encoded.address.cast(),
      encoded.length,
    );
  }

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
    final encoded = utf8.encode(properties);
    cblitedart.CBLDart_CBLDocument_SetJSON(
      doc,
      encoded.address.cast(),
      encoded.length,
      globalCBLError,
    ).checkError();
  }
}
