// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, camel_case_types, avoid_private_typedef_functions

import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

final class CBLDocument extends Opaque {}

typedef _CBLDocument_ID = FLString Function(Pointer<CBLDocument> doc);

typedef _CBLDocument_RevisionID = FLString Function(Pointer<CBLDocument> doc);

typedef _CBLDocument_Sequence_C = Uint64 Function(Pointer<CBLDocument> doc);
typedef _CBLDocument_Sequence = int Function(Pointer<CBLDocument> doc);

typedef _CBLDocument_Properties = Pointer<FLDict> Function(
  Pointer<CBLDocument> doc,
);

typedef _CBLDocument_CreateJSON = FLStringResult Function(
  Pointer<CBLDocument> doc,
);

class DocumentBindings extends Bindings {
  DocumentBindings(super.parent) {
    _id = libs.cbl.lookupFunction<_CBLDocument_ID, _CBLDocument_ID>(
      'CBLDocument_ID',
      isLeaf: useIsLeaf,
    );
    _revisionId = libs.cbl
        .lookupFunction<_CBLDocument_RevisionID, _CBLDocument_RevisionID>(
      'CBLDocument_RevisionID',
      isLeaf: useIsLeaf,
    );
    _sequence =
        libs.cbl.lookupFunction<_CBLDocument_Sequence_C, _CBLDocument_Sequence>(
      'CBLDocument_Sequence',
      isLeaf: useIsLeaf,
    );
    _properties = libs.cbl
        .lookupFunction<_CBLDocument_Properties, _CBLDocument_Properties>(
      'CBLDocument_Properties',
      isLeaf: useIsLeaf,
    );
    _createJSON = libs.cbl
        .lookupFunction<_CBLDocument_CreateJSON, _CBLDocument_CreateJSON>(
      'CBLDocument_CreateJSON',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDocument_ID _id;
  late final _CBLDocument_RevisionID _revisionId;
  late final _CBLDocument_Sequence _sequence;
  late final _CBLDocument_Properties _properties;
  late final _CBLDocument_CreateJSON _createJSON;

  String id(Pointer<CBLDocument> doc) => _id(doc).toDartString()!;

  String? revisionId(Pointer<CBLDocument> doc) =>
      _revisionId(doc).toDartString();

  int sequence(Pointer<CBLDocument> doc) => _sequence(doc);

  Pointer<FLDict> properties(Pointer<CBLDocument> doc) => _properties(doc);

  String createJSON(Pointer<CBLDocument> doc) =>
      _createJSON(doc).toDartStringAndRelease()!;
}

final class CBLMutableDocument extends Opaque {}

typedef _CBLDocument_CreateWithID = Pointer<CBLMutableDocument> Function(
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
typedef _CBLDocument_SetJSON = int Function(
  Pointer<CBLMutableDocument> doc,
  FLString json,
  Pointer<CBLError> errorOut,
);

class MutableDocumentBindings extends Bindings {
  MutableDocumentBindings(super.parent) {
    _createWithID = libs.cbl
        .lookupFunction<_CBLDocument_CreateWithID, _CBLDocument_CreateWithID>(
      'CBLDocument_CreateWithID',
      isLeaf: useIsLeaf,
    );
    _mutableCopy = libs.cbl
        .lookupFunction<_CBLDocument_MutableCopy, _CBLDocument_MutableCopy>(
      'CBLDocument_MutableCopy',
      isLeaf: useIsLeaf,
    );
    _mutableProperties = libs.cbl.lookupFunction<_CBLDocument_MutableProperties,
        _CBLDocument_MutableProperties>(
      'CBLDocument_MutableProperties',
      isLeaf: useIsLeaf,
    );
    _setProperties = libs.cbl.lookupFunction<_CBLDocument_SetProperties_C,
        _CBLDocument_SetProperties>(
      'CBLDocument_SetProperties',
      isLeaf: useIsLeaf,
    );
    _setJSON = libs.cbl.lookupFunction<_CBLDocument_SetPropertiesAsJSON_C,
        _CBLDocument_SetJSON>(
      'CBLDocument_SetJSON',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDocument_CreateWithID _createWithID;
  late final _CBLDocument_MutableCopy _mutableCopy;
  late final _CBLDocument_MutableProperties _mutableProperties;
  late final _CBLDocument_SetProperties _setProperties;
  late final _CBLDocument_SetJSON _setJSON;

  Pointer<CBLMutableDocument> createWithID([String? id]) =>
      runWithSingleFLString(id, _createWithID);

  Pointer<CBLMutableDocument> mutableCopy(Pointer<CBLDocument> source) =>
      _mutableCopy(source);

  Pointer<FLMutableDict> mutableProperties(Pointer<CBLMutableDocument> doc) =>
      _mutableProperties(doc);

  void setProperties(
    Pointer<CBLMutableDocument> doc,
    Pointer<FLMutableDict> properties,
  ) =>
      _setProperties(doc, properties);

  void setJSON(Pointer<CBLMutableDocument> doc, String properties) {
    runWithSingleFLString(properties, (flProperties) {
      _setJSON(doc, flProperties, globalCBLError).checkCBLError();
    });
  }
}
