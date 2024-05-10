// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, avoid_private_typedef_functions, camel_case_types

import 'dart:ffi';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'data.dart';
import 'database.dart';
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

// === CBLBlob =================================================================

typedef CBLBlob = cblite.CBLBlob;

final class BlobBindings {
  const BlobBindings();

  Pointer<CBLBlob> createWithData(String? contentType, Data content) =>
      runWithSingleFLString(
        contentType,
        (flContentType) {
          final sliceResult = content.toSliceResult();
          return cblite.CBLBlob_CreateWithData(
              flContentType, sliceResult.makeGlobal().ref);
        },
      );

  bool isBlob(FLDict dict) => cblite.FLDict_IsBlob(dict);

  Pointer<CBLBlob>? getBlob(FLDict dict) =>
      cblite.FLDict_GetBlob(dict).toNullable();

  void setBlob(FLSlot slot, Pointer<CBLBlob> blob) =>
      cblite.FLSlot_SetBlob(slot, blob);

  int length(Pointer<CBLBlob> blob) => cblite.CBLBlob_Length(blob);

  String digest(Pointer<CBLBlob> blob) =>
      cblite.CBLBlob_Digest(blob).toDartString()!;

  Data content(Pointer<CBLBlob> blob) =>
      cblite.CBLBlob_Content(blob, globalCBLError)
          .checkCBLError()
          .let(SliceResult.fromFLSliceResult)!
          .toData();

  String? contentType(Pointer<CBLBlob> blob) =>
      cblite.CBLBlob_ContentType(blob).toDartString();

  FLDict properties(Pointer<CBLBlob> blob) => cblite.CBLBlob_Properties(blob);
}

// === CBLBlobReadStream =======================================================

typedef CBLBlobReadStream = cblite.CBLBlobReadStream;

final class BlobReadStreamBindings {
  const BlobReadStreamBindings();

  static final _finalizer = NativeFinalizer(
      Native.addressOf<NativeFunction<cblite.NativeCBLBlobReader_Close>>(
              cblite.CBLBlobReader_Close)
          .cast());

  Pointer<CBLBlobReadStream> openContentStream(Pointer<CBLBlob> blob) =>
      cblite.CBLBlob_OpenContentStream(blob, globalCBLError).checkCBLError();

  void bindToDartObject(
    Finalizable object,
    Pointer<CBLBlobReadStream> pointer,
  ) {
    _finalizer.attach(object, pointer.cast());
  }

  Data? read(Pointer<CBLBlobReadStream> stream, int bufferSize) {
    final buffer = cblitedart.CBLDart_CBLBlobReader_Read(
        stream, bufferSize, globalCBLError);

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

typedef CBLBlobWriteStream = cblite.CBLBlobWriteStream;

final class BlobWriteStreamBindings {
  const BlobWriteStreamBindings();

  Pointer<CBLBlobWriteStream> create(Pointer<CBLDatabase> db) =>
      cblite.CBLBlobWriter_Create(db, globalCBLError).checkCBLError();

  void close(Pointer<CBLBlobWriteStream> stream) {
    cblite.CBLBlobWriter_Close(stream);
  }

  bool write(Pointer<CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return cblite.CBLBlobWriter_Write(
            stream, slice.buf.cast(), slice.size, globalCBLError)
        .checkCBLError();
  }

  Pointer<CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<CBLBlobWriteStream> stream,
  ) =>
      runWithSingleFLString(
        contentType,
        (flContentType) =>
            cblite.CBLBlob_CreateWithStream(flContentType, stream),
      );
}
