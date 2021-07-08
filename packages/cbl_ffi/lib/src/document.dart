import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'fleece.dart';
import 'utils.dart';

class CBLDocument extends Opaque {}

typedef CBLDocument_ID = Pointer<Utf8> Function(Pointer<CBLDocument> doc);

typedef CBLDocument_RevisionID = Pointer<Utf8> Function(
  Pointer<CBLDocument> doc,
);

typedef CBLDocument_Sequence_C = Uint64 Function(Pointer<CBLDocument> doc);
typedef CBLDocument_Sequence = int Function(Pointer<CBLDocument> doc);

typedef CBLDocument_Properties = Pointer<FLDict> Function(
  Pointer<CBLDocument> doc,
);

typedef CBLDocument_Delete_C = Uint8 Function(
  Pointer<CBLDocument> doc,
  Uint8 concurrency,
  Pointer<CBLError> errorOut,
);
typedef CBLDocument_Delete = int Function(
  Pointer<CBLDocument> doc,
  int concurrency,
  Pointer<CBLError> errorOut,
);

typedef CBLDocument_Purge_C = Uint8 Function(
  Pointer<CBLDocument> doc,
  Pointer<CBLError> errorOut,
);
typedef CBLDocument_Purge = int Function(
  Pointer<CBLDocument> doc,
  Pointer<CBLError> errorOut,
);

typedef CBLDocument_PropertiesAsJSON = Pointer<Utf8> Function(
  Pointer<CBLDocument> doc,
);

class DocumentBindings extends Bindings {
  DocumentBindings(Bindings parent) : super(parent) {
    _id = libs.cbl.lookupFunction<CBLDocument_ID, CBLDocument_ID>(
      'CBLDocument_ID',
    );
    _revisionId =
        libs.cbl.lookupFunction<CBLDocument_RevisionID, CBLDocument_RevisionID>(
      'CBLDocument_RevisionID',
    );
    _sequence =
        libs.cbl.lookupFunction<CBLDocument_Sequence_C, CBLDocument_Sequence>(
      'CBLDocument_Sequence',
    );
    _properties =
        libs.cbl.lookupFunction<CBLDocument_Properties, CBLDocument_Properties>(
      'CBLDocument_Properties',
    );
    _propertiesAsJson = libs.cbl.lookupFunction<CBLDocument_PropertiesAsJSON,
        CBLDocument_PropertiesAsJSON>(
      'CBLDocument_PropertiesAsJSON',
    );
    _delete = libs.cbl.lookupFunction<CBLDocument_Delete_C, CBLDocument_Delete>(
      'CBLDocument_Delete',
    );
    _purge = libs.cbl.lookupFunction<CBLDocument_Purge_C, CBLDocument_Purge>(
      'CBLDocument_Purge',
    );
  }

  late final CBLDocument_ID _id;
  late final CBLDocument_RevisionID _revisionId;
  late final CBLDocument_Sequence _sequence;
  late final CBLDocument_Properties _properties;
  late final CBLDocument_PropertiesAsJSON _propertiesAsJson;
  late final CBLDocument_Delete _delete;
  late final CBLDocument_Purge _purge;

  String id(Pointer<CBLDocument> doc) {
    return _id(doc).toDartString();
  }

  String? revisionId(Pointer<CBLDocument> doc) {
    return _revisionId(doc).toNullable()?.toDartString();
  }

  int sequence(Pointer<CBLDocument> doc) {
    return _sequence(doc);
  }

  Pointer<FLDict> properties(Pointer<CBLDocument> doc) {
    return _properties(doc);
  }

  String propertiesAsJson(Pointer<CBLDocument> doc) {
    final cString = _propertiesAsJson(doc);
    final string = cString.toDartString();
    malloc.free(cString);
    return string;
  }

  void delete(
    Pointer<CBLDocument> doc,
    CBLConcurrencyControl concurrencyControl,
  ) {
    _delete(doc, concurrencyControl.toInt(), globalCBLError).checkCBLError();
  }

  void purge(Pointer<CBLDocument> doc) {
    _purge(doc, globalCBLError).checkCBLError();
  }
}

class CBLMutableDocument extends Opaque {}

typedef CBLDocument_New = Pointer<CBLMutableDocument> Function(
  Pointer<Utf8> id,
);

typedef CBLDocument_MutableCopy = Pointer<CBLMutableDocument> Function(
  Pointer<CBLDocument> source,
);

typedef CBLDocument_MutableProperties = Pointer<FLMutableDict> Function(
  Pointer<CBLMutableDocument> doc,
);

typedef CBLDocument_SetProperties_C = Void Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<FLDict> properties,
);
typedef CBLDocument_SetProperties = void Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<FLDict> properties,
);

typedef CBLDocument_SetPropertiesAsJSON_C = Uint8 Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<Utf8> json,
  Pointer<CBLError> errorOut,
);
typedef CBLDocument_SetPropertiesAsJSON = int Function(
  Pointer<CBLMutableDocument> doc,
  Pointer<Utf8> json,
  Pointer<CBLError> errorOut,
);

class MutableDocumentBindings extends Bindings {
  MutableDocumentBindings(Bindings parent) : super(parent) {
    _new = libs.cbl.lookupFunction<CBLDocument_New, CBLDocument_New>(
      'CBLDocument_New',
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
    _setPropertiesAsJSON = libs.cbl.lookupFunction<
        CBLDocument_SetPropertiesAsJSON_C, CBLDocument_SetPropertiesAsJSON>(
      'CBLDocument_SetPropertiesAsJSON',
    );
  }

  late final CBLDocument_New _new;
  late final CBLDocument_MutableCopy _mutableCopy;
  late final CBLDocument_MutableProperties _mutableProperties;
  late final CBLDocument_SetProperties _setProperties;
  late final CBLDocument_SetPropertiesAsJSON _setPropertiesAsJSON;

  Pointer<CBLMutableDocument> create(String? id) {
    return stringTable
        .autoFree(() => _new(id == null ? nullptr : stringTable.cString(id)));
  }

  Pointer<CBLMutableDocument> mutableCopy(Pointer<CBLDocument> source) {
    return _mutableCopy(source);
  }

  Pointer<FLMutableDict> mutableProperties(Pointer<CBLMutableDocument> doc) {
    return _mutableProperties(doc);
  }

  void setProperties(
    Pointer<CBLMutableDocument> doc,
    Pointer<FLDict> properties,
  ) {
    return _setProperties(doc, properties);
  }

  void setPropertiesAsJSON(
    Pointer<CBLMutableDocument> doc,
    String properties,
  ) {
    stringTable.autoFree(() {
      _setPropertiesAsJSON(
        doc,
        stringTable.cString(properties),
        globalCBLError,
      ).checkCBLError();
    });
  }
}
