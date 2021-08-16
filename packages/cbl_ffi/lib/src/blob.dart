import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'base.dart';
import 'bindings.dart';
import 'data.dart';
import 'database.dart';
import 'fleece.dart';
import 'slice.dart';
import 'utils.dart';

// === CBLBlob =================================================================

class CBLBlob extends Opaque {}

typedef _CBLDart_CBLBlob_CreateWithData = Pointer<CBLBlob> Function(
  FLString contentType,
  FLSlice contents,
);

typedef _FLDict_IsBlob_C = Int8 Function(Pointer<FLDict> dict);
typedef _FLDict_IsBlob = int Function(Pointer<FLDict> dict);

typedef _FLDict_GetBlob = Pointer<CBLBlob> Function(Pointer<FLDict> dict);

typedef _CBLBlob_Length_C = Uint64 Function(Pointer<CBLBlob> blob);
typedef _CBLBlob_Length = int Function(Pointer<CBLBlob> blob);

typedef _CBLDart_CBLBlob_Digest = FLString Function(Pointer<CBLBlob> blob);

typedef _CBLDart_CBLBlob_ContentType = FLString Function(Pointer<CBLBlob> blob);

typedef _CBLDart_CBLBlob_Content = FLSliceResult Function(
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
);

typedef _CBLBlob_Properties = Pointer<FLDict> Function(Pointer<CBLBlob> blob);

typedef _FLSlot_SetBlob_C = Void Function(
  Pointer<FLSlot> slot,
  Pointer<CBLBlob> blob,
);
typedef _FLSlot_SetBlob = void Function(
  Pointer<FLSlot> slot,
  Pointer<CBLBlob> blob,
);

class BlobBindings extends Bindings {
  BlobBindings(Bindings parent) : super(parent) {
    _createWithData = libs.cblDart.lookupFunction<
        _CBLDart_CBLBlob_CreateWithData, _CBLDart_CBLBlob_CreateWithData>(
      'CBLDart_CBLBlob_CreateWithData',
    );
    _isBlob = libs.cbl.lookupFunction<_FLDict_IsBlob_C, _FLDict_IsBlob>(
      'FLDict_IsBlob',
    );
    _getBlob = libs.cbl.lookupFunction<_FLDict_GetBlob, _FLDict_GetBlob>(
      'FLDict_GetBlob',
    );
    _length = libs.cbl.lookupFunction<_CBLBlob_Length_C, _CBLBlob_Length>(
      'CBLBlob_Length',
    );
    _digest = libs.cblDart
        .lookupFunction<_CBLDart_CBLBlob_Digest, _CBLDart_CBLBlob_Digest>(
      'CBLDart_CBLBlob_Digest',
    );
    _contentType = libs.cblDart.lookupFunction<_CBLDart_CBLBlob_ContentType,
        _CBLDart_CBLBlob_ContentType>(
      'CBLDart_CBLBlob_ContentType',
    );
    _content = libs.cblDart
        .lookupFunction<_CBLDart_CBLBlob_Content, _CBLDart_CBLBlob_Content>(
      'CBLDart_CBLBlob_Content',
    );
    _properties =
        libs.cbl.lookupFunction<_CBLBlob_Properties, _CBLBlob_Properties>(
      'CBLBlob_Properties',
    );
    _setBlob = libs.cbl.lookupFunction<_FLSlot_SetBlob_C, _FLSlot_SetBlob>(
      'FLSlot_SetBlob',
    );
  }

  late final _CBLDart_CBLBlob_CreateWithData _createWithData;
  late final _FLDict_IsBlob _isBlob;
  late final _FLDict_GetBlob _getBlob;
  late final _FLSlot_SetBlob _setBlob;
  late final _CBLBlob_Length _length;
  late final _CBLDart_CBLBlob_Digest _digest;
  late final _CBLDart_CBLBlob_Content _content;
  late final _CBLDart_CBLBlob_ContentType _contentType;
  late final _CBLBlob_Properties _properties;

  Pointer<CBLBlob> createWithData(String? contentType, Data content) =>
      withZoneArena(() => _createWithData(
            contentType.toFLStringInArena().ref,
            content.toSliceResult().makeGlobal().ref,
          ));

  bool isBlob(Pointer<FLDict> dict) => _isBlob(dict).toBool();

  Pointer<CBLBlob>? getBlob(Pointer<FLDict> dict) =>
      _getBlob(dict).toNullable();

  void setBlob(Pointer<FLSlot> slot, Pointer<CBLBlob> blob) =>
      _setBlob(slot, blob);

  int length(Pointer<CBLBlob> blob) => _length(blob);

  String digest(Pointer<CBLBlob> blob) => _digest(blob).toDartString()!;

  Data content(Pointer<CBLBlob> blob) => _content(blob, globalCBLError)
      .checkCBLError()
      .let(SliceResult.fromFLSliceResult)!
      .toData();

  String? contentType(Pointer<CBLBlob> blob) =>
      _contentType(blob).toDartString();

  Pointer<FLDict> properties(Pointer<CBLBlob> blob) => _properties(blob);
}

// === CBLBlobReadStream =======================================================

class CBLBlobReadStream extends Opaque {}

typedef _CBLBlob_OpenContentStream = Pointer<CBLBlobReadStream> Function(
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_BindBlobReadStreamToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLBlobReadStream> stream,
);
typedef _CBLDart_BindBlobReadStreamToDartObject = void Function(
  Object object,
  Pointer<CBLBlobReadStream> stream,
);

typedef _CBLDart_CBLBlobReader_Read_C = FLSliceResult Function(
  Pointer<CBLBlobReadStream> stream,
  Uint64 bufferSize,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_CBLBlobReader_Read = FLSliceResult Function(
  Pointer<CBLBlobReadStream> stream,
  int bufferSize,
  Pointer<CBLError> errorOut,
);

typedef _CBLBlobReader_Close_C = Void Function(
  Pointer<CBLBlobReadStream> stream,
);
typedef _CBLBlobReader_Close = void Function(
  Pointer<CBLBlobReadStream> stream,
);

class BlobReadStreamBindings extends Bindings {
  BlobReadStreamBindings(Bindings parent) : super(parent) {
    _openContentStream = libs.cbl
        .lookupFunction<_CBLBlob_OpenContentStream, _CBLBlob_OpenContentStream>(
      'CBLBlob_OpenContentStream',
    );
    _bindtoDartObject = libs.cblDart.lookupFunction<
        _CBLDart_BindBlobReadStreamToDartObject_C,
        _CBLDart_BindBlobReadStreamToDartObject>(
      'CBLDart_BindBlobReadStreamToDartObject',
    );
    _read = libs.cblDart.lookupFunction<_CBLDart_CBLBlobReader_Read_C,
        _CBLDart_CBLBlobReader_Read>(
      'CBLDart_CBLBlobReader_Read',
    );
    _close = libs.cblDart
        .lookupFunction<_CBLBlobReader_Close_C, _CBLBlobReader_Close>(
      'CBLBlobReader_Close',
    );
  }

  late final _CBLBlob_OpenContentStream _openContentStream;
  late final _CBLDart_BindBlobReadStreamToDartObject _bindtoDartObject;
  late final _CBLDart_CBLBlobReader_Read _read;
  late final _CBLBlobReader_Close _close;

  void bindToDartObject(
    Object object,
    Pointer<CBLBlobReadStream> pointer,
  ) {
    _bindtoDartObject(object, pointer);
  }

  Pointer<CBLBlobReadStream> openContentStream(Pointer<CBLBlob> blob) =>
      _openContentStream(blob, globalCBLError).checkCBLError();

  Data? read(Pointer<CBLBlobReadStream> stream, int bufferSize) {
    final buffer = _read(stream, bufferSize, globalCBLError);

    // A null slice signals an error.
    if (buffer.buf == nullptr) {
      throwCBLError();
    }

    // Empty buffer means stream has been fully read, but its important to
    // create a SliceResult to ensure the the FLSliceResult is freed.
    final sliceResult = SliceResult.fromFLSliceResult(buffer)!;
    return sliceResult.size == 0 ? null : sliceResult.toData();
  }

  void close(Pointer<CBLBlobReadStream> stream) {
    _close(stream);
  }
}

// === CBLBlobWriteStream ======================================================

class CBLBlobWriteStream extends Opaque {}

typedef _CBLBlobWriter_Create = Pointer<CBLBlobWriteStream> Function(
  Pointer<CBLDatabase> db,
  Pointer<CBLError> errorOut,
);

typedef _CBLBlobWriter_Close_C = Void Function(
  Pointer<CBLBlobWriteStream> stream,
);
typedef _CBLBlobWriter_Close = void Function(
  Pointer<CBLBlobWriteStream> stream,
);

typedef _CBLBlobWriter_Write_C = Uint8 Function(
  Pointer<CBLBlobWriteStream> stream,
  Pointer<Uint8> buf,
  Uint64 bufSize,
  Pointer<CBLError> errorOut,
);
typedef _CBLBlobWriter_Write = int Function(
  Pointer<CBLBlobWriteStream> stream,
  Pointer<Uint8> buf,
  int bufSize,
  Pointer<CBLError> errorOut,
);

typedef _CBLDart_CBLBlob_CreateWithStream = Pointer<CBLBlob> Function(
  FLString contentType,
  Pointer<CBLBlobWriteStream> stream,
);

class BlobWriteStreamBindings extends Bindings {
  BlobWriteStreamBindings(Bindings parent) : super(parent) {
    _create =
        libs.cbl.lookupFunction<_CBLBlobWriter_Create, _CBLBlobWriter_Create>(
      'CBLBlobWriter_Create',
    );
    _close =
        libs.cbl.lookupFunction<_CBLBlobWriter_Close_C, _CBLBlobWriter_Close>(
      'CBLBlobWriter_Close',
    );
    _write =
        libs.cbl.lookupFunction<_CBLBlobWriter_Write_C, _CBLBlobWriter_Write>(
      'CBLBlobWriter_Write',
    );
    _createBlobWithStream = libs.cblDart.lookupFunction<
        _CBLDart_CBLBlob_CreateWithStream, _CBLDart_CBLBlob_CreateWithStream>(
      'CBLDart_CBLBlob_CreateWithStream',
    );
  }

  late final _CBLBlobWriter_Create _create;
  late final _CBLBlobWriter_Close _close;
  late final _CBLBlobWriter_Write _write;
  late final _CBLDart_CBLBlob_CreateWithStream _createBlobWithStream;

  Pointer<CBLBlobWriteStream> create(Pointer<CBLDatabase> db) =>
      _create(db, globalCBLError).checkCBLError();

  void close(Pointer<CBLBlobWriteStream> stream) {
    _close(stream);
  }

  bool write(Pointer<CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return _write(stream, slice.buf, slice.size, globalCBLError)
        .checkCBLError()
        .toBool();
  }

  Pointer<CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<CBLBlobWriteStream> stream,
  ) =>
      withZoneArena(() => _createBlobWithStream(
            contentType.toFLStringInArena().ref,
            stream,
          ));
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
}
