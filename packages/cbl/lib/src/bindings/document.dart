import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

export 'cblite.dart' show CBLDocument;

final class DocumentBindings extends Bindings {
  DocumentBindings(super.libraries);

  String id(Pointer<cblite.CBLDocument> doc) =>
      cbl.CBLDocument_ID(doc).toDartString()!;

  String? revisionId(Pointer<cblite.CBLDocument> doc) =>
      cbl.CBLDocument_RevisionID(doc).toDartString();

  int sequence(Pointer<cblite.CBLDocument> doc) =>
      cbl.CBLDocument_Sequence(doc);

  cblite.FLDict properties(Pointer<cblite.CBLDocument> doc) =>
      cbl.CBLDocument_Properties(doc);

  String createJSON(Pointer<cblite.CBLDocument> doc) =>
      cbl.CBLDocument_CreateJSON(doc).toDartStringAndRelease()!;
}

final class MutableDocumentBindings extends Bindings {
  MutableDocumentBindings(super.libraries);

  Pointer<cblite.CBLDocument> createWithID([String? id]) =>
      runWithSingleFLString(id, cbl.CBLDocument_CreateWithID);

  Pointer<cblite.CBLDocument> mutableCopy(Pointer<cblite.CBLDocument> source) =>
      cbl.CBLDocument_MutableCopy(source);

  cblite.FLMutableDict mutableProperties(Pointer<cblite.CBLDocument> doc) =>
      cbl.CBLDocument_MutableProperties(doc);

  void setProperties(
    Pointer<cblite.CBLDocument> doc,
    cblite.FLMutableDict properties,
  ) => cbl.CBLDocument_SetProperties(doc, properties);

  void setJSON(Pointer<cblite.CBLDocument> doc, String properties) {
    runWithSingleFLString(properties, (flProperties) {
      cbl.CBLDocument_SetJSON(doc, flProperties, globalCBLError).checkError();
    });
  }
}
