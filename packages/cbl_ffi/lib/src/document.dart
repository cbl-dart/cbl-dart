import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'libraries.dart';

typedef CBLDocument_ID = Pointer<Utf8> Function(Pointer<Void> doc);

typedef CBLDocument_Sequence_C = Uint64 Function(Pointer<Void> doc);
typedef CBLDocument_Sequence = int Function(Pointer<Void> doc);

typedef CBLDocument_Properties = Pointer<Void> Function(Pointer<Void> doc);

typedef CBLDocument_Delete_C = Uint8 Function(
  Pointer<Void> doc,
  Uint8 concurrency,
  Pointer<CBLError> error,
);
typedef CBLDocument_Delete = int Function(
  Pointer<Void> doc,
  int concurrency,
  Pointer<CBLError> error,
);

typedef CBLDocument_Purge_C = Uint8 Function(
  Pointer<Void> doc,
  Pointer<CBLError> error,
);
typedef CBLDocument_Purge = int Function(
  Pointer<Void> doc,
  Pointer<CBLError> error,
);

typedef CBLDocument_PropertiesAsJSON = Pointer<Utf8> Function(
  Pointer<Void> doc,
);

class DocumentBindings {
  DocumentBindings(Libraries libs)
      : id = libs.cbl.lookupFunction<CBLDocument_ID, CBLDocument_ID>(
          'CBLDocument_ID',
        ),
        sequence = libs.cbl
            .lookupFunction<CBLDocument_Sequence_C, CBLDocument_Sequence>(
          'CBLDocument_Sequence',
        ),
        properties = libs.cbl
            .lookupFunction<CBLDocument_Properties, CBLDocument_Properties>(
          'CBLDocument_Properties',
        ),
        propertiesAsJson = libs.cbl.lookupFunction<CBLDocument_PropertiesAsJSON,
            CBLDocument_PropertiesAsJSON>(
          'CBLDocument_PropertiesAsJSON',
        ),
        delete =
            libs.cbl.lookupFunction<CBLDocument_Delete_C, CBLDocument_Delete>(
          'CBLDocument_Delete',
        ),
        purge = libs.cbl.lookupFunction<CBLDocument_Purge_C, CBLDocument_Purge>(
          'CBLDocument_Purge',
        );

  final CBLDocument_ID id;
  final CBLDocument_Sequence sequence;
  final CBLDocument_Properties properties;
  final CBLDocument_PropertiesAsJSON propertiesAsJson;
  final CBLDocument_Delete delete;
  final CBLDocument_Purge purge;
}

typedef CBLDocument_New = Pointer<Void> Function(Pointer<Utf8> id);

typedef CBLDocument_MutableProperties = Pointer<Void> Function(
  Pointer<Void> doc,
);

typedef CBLDocument_MutableCopy = Pointer<Void> Function(
  Pointer<Void> original,
);

typedef CBLDocument_SetProperties_C = Void Function(
  Pointer<Void> doc,
  Pointer<Void> properties,
);
typedef CBLDocument_SetProperties = void Function(
  Pointer<Void> doc,
  Pointer<Void> properties,
);

typedef CBLDocument_SetPropertiesAsJSON_C = Uint8 Function(
  Pointer<Void> doc,
  Pointer<Utf8> json,
  Pointer<CBLError> error,
);
typedef CBLDocument_SetPropertiesAsJSON = int Function(
  Pointer<Void> doc,
  Pointer<Utf8> json,
  Pointer<CBLError> error,
);

class MutableDocumentBindings {
  MutableDocumentBindings(Libraries libs)
      : makeNew = libs.cbl.lookupFunction<CBLDocument_New, CBLDocument_New>(
          'CBLDocument_New',
        ),
        mutableCopy = libs.cbl
            .lookupFunction<CBLDocument_MutableCopy, CBLDocument_MutableCopy>(
          'CBLDocument_MutableCopy',
        ),
        mutableProperties = libs.cbl.lookupFunction<
            CBLDocument_MutableProperties, CBLDocument_MutableProperties>(
          'CBLDocument_MutableProperties',
        ),
        setProperties = libs.cbl.lookupFunction<CBLDocument_SetProperties_C,
            CBLDocument_SetProperties>(
          'CBLDocument_SetProperties',
        ),
        setPropertiesAsJSON = libs.cbl.lookupFunction<
            CBLDocument_SetPropertiesAsJSON_C, CBLDocument_SetPropertiesAsJSON>(
          'CBLDocument_SetPropertiesAsJSON',
        );

  final CBLDocument_New makeNew;
  final CBLDocument_MutableCopy mutableCopy;
  final CBLDocument_MutableProperties mutableProperties;
  final CBLDocument_SetProperties setProperties;
  final CBLDocument_SetPropertiesAsJSON setPropertiesAsJSON;
}
