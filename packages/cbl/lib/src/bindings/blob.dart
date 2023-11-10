// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_private_typedef_functions, camel_case_types

import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'data.dart';
import 'database.dart';
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

// === CBLBlob =================================================================

final class CBLBlob extends Opaque {}

typedef _CBLBlob_CreateWithData = Pointer<CBLBlob> Function(
  FLString contentType,
  FLSlice contents,
);

typedef _FLDict_IsBlob_C = Bool Function(Pointer<FLDict> dict);
typedef _FLDict_IsBlob = bool Function(Pointer<FLDict> dict);

typedef _FLDict_GetBlob = Pointer<CBLBlob> Function(Pointer<FLDict> dict);

typedef _CBLBlob_Length_C = Uint64 Function(Pointer<CBLBlob> blob);
typedef _CBLBlob_Length = int Function(Pointer<CBLBlob> blob);

typedef _CBLBlob_Digest = FLString Function(Pointer<CBLBlob> blob);

typedef _CBLBlob_ContentType = FLString Function(Pointer<CBLBlob> blob);

typedef _CBLBlob_Content = FLSliceResult Function(
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
  BlobBindings(super.parent) {
    _createWithData = libs.cbl
        .lookupFunction<_CBLBlob_CreateWithData, _CBLBlob_CreateWithData>(
      'CBLBlob_CreateWithData',
      isLeaf: useIsLeaf,
    );
    _isBlob = libs.cbl.lookupFunction<_FLDict_IsBlob_C, _FLDict_IsBlob>(
      'FLDict_IsBlob',
      isLeaf: useIsLeaf,
    );
    _getBlob = libs.cbl.lookupFunction<_FLDict_GetBlob, _FLDict_GetBlob>(
      'FLDict_GetBlob',
      isLeaf: useIsLeaf,
    );
    _length = libs.cbl.lookupFunction<_CBLBlob_Length_C, _CBLBlob_Length>(
      'CBLBlob_Length',
      isLeaf: useIsLeaf,
    );
    _digest = libs.cbl.lookupFunction<_CBLBlob_Digest, _CBLBlob_Digest>(
      'CBLBlob_Digest',
      isLeaf: useIsLeaf,
    );
    _contentType =
        libs.cbl.lookupFunction<_CBLBlob_ContentType, _CBLBlob_ContentType>(
      'CBLBlob_ContentType',
      isLeaf: useIsLeaf,
    );
    _content = libs.cbl.lookupFunction<_CBLBlob_Content, _CBLBlob_Content>(
      'CBLBlob_Content',
      isLeaf: useIsLeaf,
    );
    _properties =
        libs.cbl.lookupFunction<_CBLBlob_Properties, _CBLBlob_Properties>(
      'CBLBlob_Properties',
      isLeaf: useIsLeaf,
    );
    _setBlob = libs.cbl.lookupFunction<_FLSlot_SetBlob_C, _FLSlot_SetBlob>(
      'FLSlot_SetBlob',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLBlob_CreateWithData _createWithData;
  late final _FLDict_IsBlob _isBlob;
  late final _FLDict_GetBlob _getBlob;
  late final _FLSlot_SetBlob _setBlob;
  late final _CBLBlob_Length _length;
  late final _CBLBlob_Digest _digest;
  late final _CBLBlob_Content _content;
  late final _CBLBlob_ContentType _contentType;
  late final _CBLBlob_Properties _properties;

  Pointer<CBLBlob> createWithData(String? contentType, Data content) =>
      runWithSingleFLString(
        contentType,
        (flContentType) {
          final sliceResult = content.toSliceResult();
          return _createWithData(flContentType, sliceResult.makeGlobal().ref);
        },
      );

  bool isBlob(Pointer<FLDict> dict) => _isBlob(dict);

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

final class CBLBlobReadStream extends Opaque {}

typedef _CBLBlob_OpenContentStream = Pointer<CBLBlobReadStream> Function(
  Pointer<CBLBlob> blob,
  Pointer<CBLError> errorOut,
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

class BlobReadStreamBindings extends Bindings {
  BlobReadStreamBindings(super.parent) {
    _openContentStream = libs.cbl
        .lookupFunction<_CBLBlob_OpenContentStream, _CBLBlob_OpenContentStream>(
      'CBLBlob_OpenContentStream',
      isLeaf: useIsLeaf,
    );
    _read = libs.cblDart.lookupFunction<_CBLDart_CBLBlobReader_Read_C,
        _CBLDart_CBLBlobReader_Read>(
      'CBLDart_CBLBlobReader_Read',
      isLeaf: useIsLeaf,
    );
    _closePtr = libs.cbl.lookup('CBLBlobReader_Close');
  }

  late final _CBLBlob_OpenContentStream _openContentStream;
  late final _CBLDart_CBLBlobReader_Read _read;
  late final Pointer<NativeFunction<_CBLBlobReader_Close_C>> _closePtr;

  late final _finalizer = NativeFinalizer(_closePtr.cast());

  Pointer<CBLBlobReadStream> openContentStream(Pointer<CBLBlob> blob) =>
      _openContentStream(blob, globalCBLError).checkCBLError();

  void bindToDartObject(
    Finalizable object,
    Pointer<CBLBlobReadStream> pointer,
  ) {
    _finalizer.attach(object, pointer.cast());
  }

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
}

// === CBLBlobWriteStream ======================================================

final class CBLBlobWriteStream extends Opaque {}

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

typedef _CBLBlobWriter_Write_C = Bool Function(
  Pointer<CBLBlobWriteStream> stream,
  Pointer<Uint8> buf,
  Size bufSize,
  Pointer<CBLError> errorOut,
);
typedef _CBLBlobWriter_Write = bool Function(
  Pointer<CBLBlobWriteStream> stream,
  Pointer<Uint8> buf,
  int bufSize,
  Pointer<CBLError> errorOut,
);

typedef _CBLBlob_CreateWithStream = Pointer<CBLBlob> Function(
  FLString contentType,
  Pointer<CBLBlobWriteStream> stream,
);

class BlobWriteStreamBindings extends Bindings {
  BlobWriteStreamBindings(super.parent) {
    _create =
        libs.cbl.lookupFunction<_CBLBlobWriter_Create, _CBLBlobWriter_Create>(
      'CBLBlobWriter_Create',
      isLeaf: useIsLeaf,
    );
    _close =
        libs.cbl.lookupFunction<_CBLBlobWriter_Close_C, _CBLBlobWriter_Close>(
      'CBLBlobWriter_Close',
      isLeaf: useIsLeaf,
    );
    _write =
        libs.cbl.lookupFunction<_CBLBlobWriter_Write_C, _CBLBlobWriter_Write>(
      'CBLBlobWriter_Write',
      isLeaf: useIsLeaf,
    );
    _createBlobWithStream = libs.cbl
        .lookupFunction<_CBLBlob_CreateWithStream, _CBLBlob_CreateWithStream>(
      'CBLBlob_CreateWithStream',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLBlobWriter_Create _create;
  late final _CBLBlobWriter_Close _close;
  late final _CBLBlobWriter_Write _write;
  late final _CBLBlob_CreateWithStream _createBlobWithStream;

  Pointer<CBLBlobWriteStream> create(Pointer<CBLDatabase> db) =>
      _create(db, globalCBLError).checkCBLError();

  void close(Pointer<CBLBlobWriteStream> stream) {
    _close(stream);
  }

  bool write(Pointer<CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return _write(stream, slice.buf, slice.size, globalCBLError)
        .checkCBLError();
  }

  Pointer<CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<CBLBlobWriteStream> stream,
  ) =>
      runWithSingleFLString(
        contentType,
        (flContentType) => _createBlobWithStream(flContentType, stream),
      );
}

// === BlobsBindings ===========================================================

class BlobsBindings extends Bindings {
  BlobsBindings(super.parent) {
    blob = BlobBindings(this);
    readStream = BlobReadStreamBindings(this);
    writeStream = BlobWriteStreamBindings(this);
  }

  late final BlobBindings blob;
  late final BlobReadStreamBindings readStream;
  late final BlobWriteStreamBindings writeStream;
}
