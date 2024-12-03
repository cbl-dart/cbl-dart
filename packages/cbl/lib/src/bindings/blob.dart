import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'data.dart';
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

export 'cblite.dart' show CBLBlob, CBLBlobReadStream;

// === CBLBlob =================================================================

final class BlobBindings extends Bindings {
  BlobBindings(super.parent);

  Pointer<cblite.CBLBlob> createWithData(String? contentType, Data content) =>
      runWithSingleFLString(
        contentType,
        (flContentType) {
          final sliceResult = content.toSliceResult();
          return cbl.CBLBlob_CreateWithData(
            flContentType,
            sliceResult.makeGlobal().ref,
          );
        },
      );

  bool isBlob(cblite.FLDict dict) => cbl.FLDict_IsBlob(dict);

  Pointer<cblite.CBLBlob>? getBlob(cblite.FLDict dict) =>
      cbl.FLDict_GetBlob(dict).toNullable();

  void setBlob(cblite.FLSlot slot, Pointer<cblite.CBLBlob> blob) =>
      cbl.FLSlot_SetBlob(slot, blob);

  int length(Pointer<cblite.CBLBlob> blob) => cbl.CBLBlob_Length(blob);

  String digest(Pointer<cblite.CBLBlob> blob) =>
      cbl.CBLBlob_Digest(blob).toDartString()!;

  Data content(Pointer<cblite.CBLBlob> blob) =>
      cbl.CBLBlob_Content(blob, globalCBLError)
          .checkError()
          .let(SliceResult.fromFLSliceResult)!
          .toData();

  String? contentType(Pointer<cblite.CBLBlob> blob) =>
      cbl.CBLBlob_ContentType(blob).toDartString();

  cblite.FLDict properties(Pointer<cblite.CBLBlob> blob) =>
      cbl.CBLBlob_Properties(blob);
}

// === CBLBlobReadStream =======================================================

final class BlobReadStreamBindings extends Bindings {
  BlobReadStreamBindings(super.parent);

  late final _finalizer =
      NativeFinalizer(cbl.addresses.CBLBlobReader_Close.cast());

  Pointer<cblite.CBLBlobReadStream> openContentStream(
    Pointer<cblite.CBLBlob> blob,
  ) =>
      cbl.CBLBlob_OpenContentStream(blob, globalCBLError).checkError();

  void bindToDartObject(
    Finalizable object,
    Pointer<cblite.CBLBlobReadStream> pointer,
  ) {
    _finalizer.attach(object, pointer.cast());
  }

  Data? read(Pointer<cblite.CBLBlobReadStream> stream, int bufferSize) {
    final buffer =
        cblDart.CBLDart_CBLBlobReader_Read(stream, bufferSize, globalCBLError);

    // A null slice signals an error.
    if (buffer.buf == nullptr) {
      throwError();
    }

    // Empty buffer means stream has been fully read, but its important to
    // create a SliceResult to ensure the the FLSliceResult is freed.
    final sliceResult = SliceResult.fromFLSliceResult(buffer)!;
    return sliceResult.size == 0 ? null : sliceResult.toData();
  }
}

// === CBLBlobWriteStream ======================================================

final class BlobWriteStreamBindings extends Bindings {
  BlobWriteStreamBindings(super.parent);

  Pointer<cblite.CBLBlobWriteStream> create(Pointer<cblite.CBLDatabase> db) =>
      cbl.CBLBlobWriter_Create(db, globalCBLError).checkError();

  void close(Pointer<cblite.CBLBlobWriteStream> stream) {
    cbl.CBLBlobWriter_Close(stream);
  }

  bool write(Pointer<cblite.CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return cbl.CBLBlobWriter_Write(
      stream,
      slice.buf,
      slice.size,
      globalCBLError,
    ).checkError();
  }

  Pointer<cblite.CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<cblite.CBLBlobWriteStream> stream,
  ) =>
      runWithSingleFLString(
        contentType,
        (flContentType) => cbl.CBLBlob_CreateWithStream(flContentType, stream),
      );
}

// === BlobsBindings ===========================================================

final class BlobsBindings extends Bindings {
  BlobsBindings(super.parent) {
    blob = BlobBindings(this);
    readStream = BlobReadStreamBindings(this);
    writeStream = BlobWriteStreamBindings(this);
  }

  late final BlobBindings blob;
  late final BlobReadStreamBindings readStream;
  late final BlobWriteStreamBindings writeStream;
}
