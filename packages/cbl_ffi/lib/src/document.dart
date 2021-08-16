import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'fleece.dart';
import 'utils.dart';

class CBLDocument extends Opaque {}

typedef _CBLDocument_ID = FLString Function(Pointer<CBLDocument> doc);

typedef _CBLDocument_RevisionID = FLString Function(Pointer<CBLDocument> doc);

typedef _CBLDocument_Sequence_C = Uint64 Function(Pointer<CBLDocument> doc);
typedef _CBLDocument_Sequence = int Function(Pointer<CBLDocument> doc);

typedef _CBLDocument_Properties = Pointer<FLDict> Function(
  Pointer<CBLDocument> doc,
);

typedef _CBLDart_CBLDocument_CreateJSON = FLStringResult Function(
  Pointer<CBLDocument> doc,
);

class DocumentBindings extends Bindings {
  DocumentBindings(Bindings parent) : super(parent) {
    _id = libs.cblDart.lookupFunction<_CBLDocument_ID, _CBLDocument_ID>(
      'CBLDart_CBLDocument_ID',
    );
    _revisionId = libs.cblDart
        .lookupFunction<_CBLDocument_RevisionID, _CBLDocument_RevisionID>(
      'CBLDart_CBLDocument_RevisionID',
    );
    _sequence =
        libs.cbl.lookupFunction<_CBLDocument_Sequence_C, _CBLDocument_Sequence>(
      'CBLDocument_Sequence',
    );
    _properties = libs.cbl
        .lookupFunction<_CBLDocument_Properties, _CBLDocument_Properties>(
      'CBLDocument_Properties',
    );
    _createJSON = libs.cblDart.lookupFunction<_CBLDart_CBLDocument_CreateJSON,
        _CBLDart_CBLDocument_CreateJSON>(
      'CBLDart_CBLDocument_CreateJSON',
    );
  }

  late final _CBLDocument_ID _id;
  late final _CBLDocument_RevisionID _revisionId;
  late final _CBLDocument_Sequence _sequence;
  late final _CBLDocument_Properties _properties;
  late final _CBLDart_CBLDocument_CreateJSON _createJSON;

  String id(Pointer<CBLDocument> doc) => _id(doc).toDartString()!;

  String? revisionId(Pointer<CBLDocument> doc) =>
      _revisionId(doc).toDartString();

  int sequence(Pointer<CBLDocument> doc) => _sequence(doc);

  Pointer<FLDict> properties(Pointer<CBLDocument> doc) => _properties(doc);

  String createJSON(Pointer<CBLDocument> doc) =>
      _createJSON(doc).toDartStringAndRelease()!;
}

class CBLMutableDocument extends Opaque {}

typedef _CBLDart_CBLDocument_CreateWithID = Pointer<CBLMutableDocument>
    Function(
  FLString id,
);

typedef _CBLDocument_MutableCopy = Pointer<CBLMutableDocument> Function(
  Pointer<CBLDocument> source,
);

typedef _CBLDocument_MutableProperties = Pointer<FLMutableDict> Function(
  Pointer<CBLMutableDocument> doc,
);

typedef _CBLDocument_SetProperties_C = Void Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<FLMutableDict> properties,
);
typedef _CBLDocument_SetProperties = void Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<FLMutableDict> properties,
);

typedef _CBLDocument_SetPropertiesAsJSON_C = Uint8 Function(
  Pointer<CBLMutableDocument> doc,
  FLString json,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLDocument_SetJSON = int Function(
  Pointer<CBLMutableDocument> doc,
  FLString json,
  Pointer<CBLError> errorOut,
);

class MutableDocumentBindings extends Bindings {
  MutableDocumentBindings(Bindings parent) : super(parent) {
    _createWithID = libs.cblDart.lookupFunction<
        _CBLDart_CBLDocument_CreateWithID, _CBLDart_CBLDocument_CreateWithID>(
      'CBLDart_CBLDocument_CreateWithID',
    );
    _mutableCopy = libs.cbl
        .lookupFunction<_CBLDocument_MutableCopy, _CBLDocument_MutableCopy>(
      'CBLDocument_MutableCopy',
    );
    _mutableProperties = libs.cbl.lookupFunction<_CBLDocument_MutableProperties,
        _CBLDocument_MutableProperties>(
      'CBLDocument_MutableProperties',
    );
    _setProperties = libs.cbl.lookupFunction<_CBLDocument_SetProperties_C,
        _CBLDocument_SetProperties>(
      'CBLDocument_SetProperties',
    );
    _setJSON = libs.cblDart.lookupFunction<_CBLDocument_SetPropertiesAsJSON_C,
        _CBLDart_CBLDocument_SetJSON>(
      'CBLDart_CBLDocument_SetJSON',
    );
  }

  late final _CBLDart_CBLDocument_CreateWithID _createWithID;
  late final _CBLDocument_MutableCopy _mutableCopy;
  late final _CBLDocument_MutableProperties _mutableProperties;
  late final _CBLDocument_SetProperties _setProperties;
  late final _CBLDart_CBLDocument_SetJSON _setJSON;

  Pointer<CBLMutableDocument> createWithID([String? id]) =>
      withZoneArena(() => _createWithID(
            id.toFLStringInArena().ref,
          ));

  Pointer<CBLMutableDocument> mutableCopy(Pointer<CBLDocument> source) =>
      _mutableCopy(source);

  Pointer<FLMutableDict> mutableProperties(Pointer<CBLMutableDocument> doc) =>
      _mutableProperties(doc);

  void setProperties(
    Pointer<CBLMutableDocument> doc,
    Pointer<FLMutableDict> properties,
  ) =>
      _setProperties(doc, properties);

  void setJSON(
    Pointer<CBLMutableDocument> doc,
    String properties,
  ) {
    withZoneArena(() {
      _setJSON(
        doc,
        properties.toFLStringInArena().ref,
        globalCBLError,
      ).checkCBLError();
    });
  }
}
