import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'database.dart';
import 'fleece.dart';
import 'utils.dart';

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

class BlobBindings extends Bindings {
  BlobBindings(Bindings parent) : super(parent) {
    _isBlob = libs.cbl.lookupFunction<CBL_IsBlob_C, CBL_IsBlob>(
      'CBL_IsBlob',
    );
    _get = libs.cbl.lookupFunction<CBLBlob_Get, CBLBlob_Get>(
      'CBLBlob_Get',
    );
    _length = libs.cbl.lookupFunction<CBLBlob_Length_C, CBLBlob_Length>(
      'CBLBlob_Length',
    );
    _digest = libs.cbl.lookupFunction<CBLBlob_Digest, CBLBlob_Digest>(
      'CBLBlob_Digest',
    );
    _contentType =
        libs.cbl.lookupFunction<CBLBlob_ContentType, CBLBlob_ContentType>(
      'CBLBlob_ContentType',
    );
    _properties =
        libs.cbl.lookupFunction<CBLBlob_Properties, CBLBlob_Properties>(
      'CBLBlob_Properties',
    );
    _setBlob = libs.cbl.lookupFunction<FLSlot_SetBlob_C, FLSlot_SetBlob>(
      'FLSlot_SetBlob',
    );
  }

  late final CBL_IsBlob _isBlob;
  late final CBLBlob_Get _get;
  late final CBLBlob_Length _length;
  late final CBLBlob_Digest _digest;
  late final CBLBlob_ContentType _contentType;
  late final CBLBlob_Properties _properties;
  late final FLSlot_SetBlob _setBlob;

  bool isBlob(Pointer<FLDict> dict) {
    return _isBlob(dict).toBool();
  }

  Pointer<CBLBlob>? getBlob(Pointer<FLDict> dict) {
    return _get(dict).toNullable();
  }

  int length(Pointer<CBLBlob> blob) {
    return _length(blob);
  }

  String digest(Pointer<CBLBlob> blob) {
    return _digest(blob).toDartString();
  }

  String? contentType(Pointer<CBLBlob> blob) {
    return _contentType(blob).toNullable()?.toDartString();
  }

  Pointer<FLDict> properties(Pointer<CBLBlob> blob) {
    return _properties(blob);
  }

  void setBlob(Pointer<FLSlot> slot, Pointer<CBLBlob> blob) {
    _setBlob(slot, blob);
  }
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

class BlobReadStreamBindings extends Bindings {
  BlobReadStreamBindings(Bindings parent) : super(parent) {
    _openContentStream = libs.cbl
        .lookupFunction<CBLBlob_OpenContentStream, CBLBlob_OpenContentStream>(
      'CBLBlob_OpenContentStream',
    );
    _read = libs.cblDart.lookupFunction<CBLDart_CBLBlobReader_Read_C,
        CBLDart_CBLBlobReader_Read>(
      'CBLDart_CBLBlobReader_Read',
    );
    _close =
        libs.cblDart.lookupFunction<CBLBlobReader_Close_C, CBLBlobReader_Close>(
      'CBLBlobReader_Close',
    );
  }

  late final CBLBlob_OpenContentStream _openContentStream;
  late final CBLDart_CBLBlobReader_Read _read;
  late final CBLBlobReader_Close _close;

  Pointer<CBLBlobReadStream> openContentStream(Pointer<CBLBlob> blob) {
    return _openContentStream(blob, globalCBLError).checkCBLError();
  }

  int read(Pointer<CBLBlobReadStream> stream, Pointer<Uint8> buf, int bufSize) {
    return _read(stream, buf, bufSize, globalCBLError).checkCBLError();
  }

  void close(Pointer<CBLBlobReadStream> stream) {
    _close(stream);
  }
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

class BlobWriteStreamBindings extends Bindings {
  BlobWriteStreamBindings(Bindings parent) : super(parent) {
    _new = libs.cbl.lookupFunction<CBLBlobWriter_New, CBLBlobWriter_New>(
      'CBLBlobWriter_New',
    );
    _close =
        libs.cbl.lookupFunction<CBLBlobWriter_Close_C, CBLBlobWriter_Close>(
      'CBLBlobWriter_Close',
    );
    _write =
        libs.cbl.lookupFunction<CBLBlobWriter_Write_C, CBLBlobWriter_Write>(
      'CBLBlobWriter_Write',
    );
    _createBlobWithStream = libs.cbl
        .lookupFunction<CBLBlob_CreateWithStream, CBLBlob_CreateWithStream>(
      'CBLBlob_CreateWithStream',
    );
  }

  late final CBLBlobWriter_New _new;
  late final CBLBlobWriter_Close _close;
  late final CBLBlobWriter_Write _write;
  late final CBLBlob_CreateWithStream _createBlobWithStream;

  Pointer<CBLBlobWriteStream> create(Pointer<CBLDatabase> db) {
    return _new(db, globalCBLError).checkCBLError();
  }

  void close(Pointer<CBLBlobWriteStream> stream) {
    _close(stream);
  }

  bool write(Pointer<CBLBlobWriteStream> stream, Uint8List buf) {
    final nativeBuf = malloc<Uint8>(buf.length);
    nativeBuf.asTypedList(buf.length).setAll(0, buf);
    try {
      return _write(stream, nativeBuf, buf.length, globalCBLError)
          .checkCBLError()
          .toBool();
    } finally {
      malloc.free(nativeBuf);
    }
  }

  Pointer<CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<CBLBlobWriteStream> stream,
  ) {
    return stringTable.autoFree(() {
      return _createBlobWithStream(
        contentType == null ? nullptr : stringTable.cString(contentType),
        stream,
      );
    });
  }
}

// === BlobsBindings ===========================================================

class BlobsBindings extends Bindings {
  BlobsBindings(Bindings parent) : super(parent) {
    blob = BlobBindings(this);
    readStream = BlobReadStreamBindings(this);
    writeStream = BlobWriteStreamBindings(this);
  }

  late final BlobBindings blob;
  late final BlobReadStreamBindings readStream;
  late final BlobWriteStreamBindings writeStream;

  @override
  List<Bindings> get children => [blob, readStream, writeStream];
}
