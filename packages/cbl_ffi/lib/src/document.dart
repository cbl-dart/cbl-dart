import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'fleece.dart';

class CBLDocument extends Opaque {}

typedef CBLDocument_ID = FLString Function(Pointer<CBLDocument> doc);

typedef CBLDocument_RevisionID = FLString Function(Pointer<CBLDocument> doc);

typedef CBLDocument_Sequence_C = Uint64 Function(Pointer<CBLDocument> doc);
typedef CBLDocument_Sequence = int Function(Pointer<CBLDocument> doc);

typedef CBLDocument_Properties = Pointer<FLDict> Function(
  Pointer<CBLDocument> doc,
);

typedef CBLDart_CBLDocument_CreateJSON = FLStringResult Function(
  Pointer<CBLDocument> doc,
);

class DocumentBindings extends Bindings {
  DocumentBindings(Bindings parent) : super(parent) {
    _id = libs.cblDart.lookupFunction<CBLDocument_ID, CBLDocument_ID>(
      'CBLDart_CBLDocument_ID',
    );
    _revisionId = libs.cblDart
        .lookupFunction<CBLDocument_RevisionID, CBLDocument_RevisionID>(
      'CBLDart_CBLDocument_RevisionID',
    );
    _sequence =
        libs.cbl.lookupFunction<CBLDocument_Sequence_C, CBLDocument_Sequence>(
      'CBLDocument_Sequence',
    );
    _properties =
        libs.cbl.lookupFunction<CBLDocument_Properties, CBLDocument_Properties>(
      'CBLDocument_Properties',
    );
    _createJSON = libs.cblDart.lookupFunction<CBLDart_CBLDocument_CreateJSON,
        CBLDart_CBLDocument_CreateJSON>(
      'CBLDart_CBLDocument_CreateJSON',
    );
  }

  late final CBLDocument_ID _id;
  late final CBLDocument_RevisionID _revisionId;
  late final CBLDocument_Sequence _sequence;
  late final CBLDocument_Properties _properties;
  late final CBLDart_CBLDocument_CreateJSON _createJSON;

  String id(Pointer<CBLDocument> doc) {
    return _id(doc).toDartString()!;
  }

  String? revisionId(Pointer<CBLDocument> doc) {
    return _revisionId(doc).toDartString();
  }

  int sequence(Pointer<CBLDocument> doc) {
    return _sequence(doc);
  }

  Pointer<FLDict> properties(Pointer<CBLDocument> doc) {
    return _properties(doc);
  }

  String createJSON(Pointer<CBLDocument> doc) {
    return _createJSON(doc).toDartStringAndRelease()!;
  }
}

class CBLMutableDocument extends Opaque {}

typedef CBLDart_CBLDocument_CreateWithID = Pointer<CBLMutableDocument> Function(
  FLString id,
);

typedef CBLDocument_MutableCopy = Pointer<CBLMutableDocument> Function(
  Pointer<CBLDocument> source,
);

typedef CBLDocument_MutableProperties = Pointer<FLMutableDict> Function(
  Pointer<CBLMutableDocument> doc,
);

typedef CBLDocument_SetProperties_C = Void Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<FLMutableDict> properties,
);
typedef CBLDocument_SetProperties = void Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<FLMutableDict> properties,
);

typedef CBLDocument_SetPropertiesAsJSON_C = Uint8 Function(
  Pointer<CBLMutableDocument> doc,
  FLString json,
  Pointer<CBLError> errorOut,
);
typedef CBLDart_CBLDocument_SetJSON = int Function(
  Pointer<CBLMutableDocument> doc,
  FLString json,
  Pointer<CBLError> errorOut,
);

class MutableDocumentBindings extends Bindings {
  MutableDocumentBindings(Bindings parent) : super(parent) {
    _createWithID = libs.cblDart.lookupFunction<
        CBLDart_CBLDocument_CreateWithID, CBLDart_CBLDocument_CreateWithID>(
      'CBLDart_CBLDocument_CreateWithID',
    );
    _mutableCopy = libs.cbl
        .lookupFunction<CBLDocument_MutableCopy, CBLDocument_MutableCopy>(
      'CBLDocument_MutableCopy',
    );
    _mutableProperties = libs.cbl.lookupFunction<CBLDocument_MutableProperties,
        CBLDocument_MutableProperties>(
      'CBLDocument_MutableProperties',
    );
    _setProperties = libs.cbl
        .lookupFunction<CBLDocument_SetProperties_C, CBLDocument_SetProperties>(
      'CBLDocument_SetProperties',
    );
    _setJSON = libs.cblDart.lookupFunction<CBLDocument_SetPropertiesAsJSON_C,
        CBLDart_CBLDocument_SetJSON>(
      'CBLDart_CBLDocument_SetJSON',
    );
  }

  late final CBLDart_CBLDocument_CreateWithID _createWithID;
  late final CBLDocument_MutableCopy _mutableCopy;
  late final CBLDocument_MutableProperties _mutableProperties;
  late final CBLDocument_SetProperties _setProperties;
  late final CBLDart_CBLDocument_SetJSON _setJSON;

  Pointer<CBLMutableDocument> createWithID([String? id]) {
    return stringTable.autoFree(() => _createWithID(
          stringTable.flString(id).ref,
        ));
  }

  Pointer<CBLMutableDocument> mutableCopy(Pointer<CBLDocument> source) {
    return _mutableCopy(source);
  }

  Pointer<FLMutableDict> mutableProperties(Pointer<CBLMutableDocument> doc) {
    return _mutableProperties(doc);
  }

  void setProperties(
    Pointer<CBLMutableDocument> doc,
    Pointer<FLMutableDict> properties,
  ) {
    return _setProperties(doc, properties);
  }

  void setJSON(
    Pointer<CBLMutableDocument> doc,
    String properties,
  ) {
    stringTable.autoFree(() {
      _setJSON(
        doc,
        stringTable.flString(properties).ref,
        globalCBLError,
      ).checkCBLError();
    });
  }
}
