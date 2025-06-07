import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

export 'cblite.dart' show CBLDocument;

final class DocumentBindings extends Bindings {
  DocumentBindings(super.libraries);

  String id(Pointer<cblite_lib.CBLDocument> doc) =>
      cblite.CBLDocument_ID(doc).toDartString()!;

  String? revisionId(Pointer<cblite_lib.CBLDocument> doc) =>
      cblite.CBLDocument_RevisionID(doc).toDartString();

  int sequence(Pointer<cblite_lib.CBLDocument> doc) =>
      cblite.CBLDocument_Sequence(doc);

  cblite_lib.FLDict properties(Pointer<cblite_lib.CBLDocument> doc) =>
      cblite.CBLDocument_Properties(doc);

  String createJSON(Pointer<cblite_lib.CBLDocument> doc) =>
      cblite.CBLDocument_CreateJSON(doc).toDartStringAndRelease()!;
}

final class MutableDocumentBindings extends Bindings {
  MutableDocumentBindings(super.libraries);

  Pointer<cblite_lib.CBLDocument> createWithID([String? id]) =>
      runWithSingleFLString(id, cblite.CBLDocument_CreateWithID);

  Pointer<cblite_lib.CBLDocument> mutableCopy(
    Pointer<cblite_lib.CBLDocument> source,
  ) => cblite.CBLDocument_MutableCopy(source);

  cblite_lib.FLMutableDict mutableProperties(
    Pointer<cblite_lib.CBLDocument> doc,
  ) => cblite.CBLDocument_MutableProperties(doc);

  void setProperties(
    Pointer<cblite_lib.CBLDocument> doc,
    cblite_lib.FLMutableDict properties,
  ) => cblite.CBLDocument_SetProperties(doc, properties);

  void setJSON(Pointer<cblite_lib.CBLDocument> doc, String properties) {
    runWithSingleFLString(properties, (flProperties) {
      cblite.CBLDocument_SetJSON(
        doc,
        flProperties,
        globalCBLError,
      ).checkError();
    });
  }
}
