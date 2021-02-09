import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'fleece.dart';

// === CBLBlob =================================================================

class CBLBlob extends Opaque {}

typedef CBL_IsBlob_C = Int8 Function(Pointer<FLDict> dict);
typedef CBL_IsBlob = int Function(Pointer<FLDict> dict);

typedef CBLBlob_Get = Pointer<CBLBlob> Function(Pointer<FLDict> dict);

typedef CBLBlob_Length_C = Uint64 Function(Pointer<CBLBlob> blob);
typedef CBLBlob_Length = int Function(Pointer<CBLBlob> blob);

typedef CBLBlob_Digest = Pointer<Utf8> Function(Pointer<CBLBlob> blob);

typedef CBLBlob_ContentType = Pointer<Utf8> Function(
  Pointer<CBLBlob> blob,
);

typedef CBLBlob_Properties = Pointer<FLDict> Function(Pointer<CBLBlob> blob);

typedef FLSlot_SetBlob_C = Void Function(
  Pointer<FLSlot> slot,
  Pointer<CBLBlob> blob,
);
typedef FLSlot_SetBlob = void Function(
  Pointer<FLSlot> slot,
  Pointer<CBLBlob> blob,
);

class BlobBindings {
  BlobBindings(Libraries libs)
      : isBlob = libs.cbl.lookupFunction<CBL_IsBlob_C, CBL_IsBlob>(
          'CBL_IsBlob',
        ),
        get = libs.cbl.lookupFunction<CBLBlob_Get, CBLBlob_Get>(
          'CBLBlob_Get',
        ),
        length = libs.cbl.lookupFunction<CBLBlob_Length_C, CBLBlob_Length>(
          'CBLBlob_Length',
        ),
        digest = libs.cbl.lookupFunction<CBLBlob_Digest, CBLBlob_Digest>(
          'CBLBlob_Digest',
        ),
        contentType =
            libs.cbl.lookupFunction<CBLBlob_ContentType, CBLBlob_ContentType>(
          'CBLBlob_ContentType',
        ),
        properties =
            libs.cbl.lookupFunction<CBLBlob_Properties, CBLBlob_Properties>(
          'CBLBlob_Properties',
        ),
        setBlob = libs.cbl.lookupFunction<FLSlot_SetBlob_C, FLSlot_SetBlob>(
          'FLSlot_SetBlob',
        );

  final CBL_IsBlob isBlob;
  final CBLBlob_Get get;
  final CBLBlob_Length length;
  final CBLBlob_Digest digest;
  final CBLBlob_ContentType contentType;
  final CBLBlob_Properties properties;
  final FLSlot_SetBlob setBlob;
}

// === CBLBlobReadStream =======================================================

class CBLBlobReadStream extends Opaque {}

typedef CBLBlob_OpenContentStream = Pointer<CBLBlobReadStream> Function(
  Pointer<CBLBlob> blob,
  Pointer<CBLError> error,
);

typedef CBLDart_CBLBlobReader_Read_C = Uint64 Function(
  Pointer<CBLBlobReadStream> stream,
  Pointer<Uint8> buf,
  Uint64 bufSize,
  Pointer<CBLError> error,
);
typedef CBLDart_CBLBlobReader_Read = int Function(
  Pointer<CBLBlobReadStream> stream,
  Pointer<Uint8> buf,
  int bufSize,
  Pointer<CBLError> error,
);

typedef CBLBlobReader_Close_C = Void Function(
  Pointer<CBLBlobReadStream> stream,
);
typedef CBLBlobReader_Close = void Function(
  Pointer<CBLBlobReadStream> stream,
);

class BlobReadStreamBindings {
  BlobReadStreamBindings(Libraries libs)
      : openContentStream = libs.cbl.lookupFunction<CBLBlob_OpenContentStream,
            CBLBlob_OpenContentStream>(
          'CBLBlob_OpenContentStream',
        ),
        read = libs.cblDart.lookupFunction<CBLDart_CBLBlobReader_Read_C,
            CBLDart_CBLBlobReader_Read>(
          'CBLDart_CBLBlobReader_Read',
        ),
        close = libs.cblDart
            .lookupFunction<CBLBlobReader_Close_C, CBLBlobReader_Close>(
          'CBLBlobReader_Close',
        );

  final CBLBlob_OpenContentStream openContentStream;
  final CBLDart_CBLBlobReader_Read read;
  final CBLBlobReader_Close close;
}

// === CBLBlobWriteStream ======================================================

class CBLBlobWriteStream extends Opaque {}

typedef CBLBlobWriter_New = Pointer<CBLBlobWriteStream> Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> error,
);

typedef CBLBlobWriter_Close_C = Void Function(
  Pointer<CBLBlobWriteStream> stream,
);
typedef CBLBlobWriter_Close = void Function(
  Pointer<CBLBlobWriteStream> stream,
);

typedef CBLBlobWriter_Write_C = Uint8 Function(
  Pointer<CBLBlobWriteStream> stream,
  Pointer<Uint8> buf,
  Uint64 bufSize,
  Pointer<CBLError> error,
);
typedef CBLBlobWriter_Write = int Function(
  Pointer<CBLBlobWriteStream> stream,
  Pointer<Uint8> buf,
  int bufSize,
  Pointer<CBLError> error,
);

typedef CBLBlob_CreateWithStream = Pointer<CBLBlob> Function(
  Pointer<Utf8> contentType,
  Pointer<CBLBlobWriteStream> stream,
);

class BlobWriteStreamBindings {
  BlobWriteStreamBindings(Libraries libs)
      : makeNew = libs.cbl.lookupFunction<CBLBlobWriter_New, CBLBlobWriter_New>(
          'CBLBlobWriter_New',
        ),
        close =
            libs.cbl.lookupFunction<CBLBlobWriter_Close_C, CBLBlobWriter_Close>(
          'CBLBlobWriter_Close',
        ),
        write =
            libs.cbl.lookupFunction<CBLBlobWriter_Write_C, CBLBlobWriter_Write>(
          'CBLBlobWriter_Write',
        ),
        createBlobWithStream = libs.cbl
            .lookupFunction<CBLBlob_CreateWithStream, CBLBlob_CreateWithStream>(
          'CBLBlob_CreateWithStream',
        );

  final CBLBlobWriter_New makeNew;
  final CBLBlobWriter_Close close;
  final CBLBlobWriter_Write write;
  final CBLBlob_CreateWithStream createBlobWithStream;
}

// === BlobsBindings ===========================================================

class BlobsBindings {
  BlobsBindings(Libraries libs)
      : blob = BlobBindings(libs),
        readStream = BlobReadStreamBindings(libs),
        writeStream = BlobWriteStreamBindings(libs);

  final BlobBindings blob;
  final BlobReadStreamBindings readStream;
  final BlobWriteStreamBindings writeStream;
}
