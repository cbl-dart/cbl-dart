import 'dart:ffi';

import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'data.dart';
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

export 'cblite.dart' show CBLBlob, CBLBlobReadStream;

// === CBLBlob =================================================================

final class BlobBindings {
  const BlobBindings();

  Pointer<cblite.CBLBlob> createWithData(String? contentType, Data content) =>
      runWithSingleFLString(contentType, (flContentType) {
        final sliceResult = content.toSliceResult();
        return cblite.CBLBlob_CreateWithData(
          flContentType,
          sliceResult.makeGlobal().ref,
        );
      });

  bool isBlob(cblite.FLDict dict) => cblite.FLDict_IsBlob(dict);

  Pointer<cblite.CBLBlob>? getBlob(cblite.FLDict dict) =>
      cblite.FLDict_GetBlob(dict).toNullable();

  void setBlob(cblite.FLSlot slot, Pointer<cblite.CBLBlob> blob) =>
      cblite.FLSlot_SetBlob(slot, blob);

  int length(Pointer<cblite.CBLBlob> blob) => cblite.CBLBlob_Length(blob);

  String digest(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_Digest(blob).toDartString()!;

  Data content(Pointer<cblite.CBLBlob> blob) => cblite.CBLBlob_Content(
    blob,
    globalCBLError,
  ).checkError().let(SliceResult.fromFLSliceResult)!.toData();

  String? contentType(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_ContentType(blob).toDartString();

  cblite.FLDict properties(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_Properties(blob);
}

// === CBLBlobReadStream =======================================================

final class BlobReadStreamBindings {
  const BlobReadStreamBindings();

  static final _finalizer = NativeFinalizer(
    cblite.addresses.CBLBlobReader_Close.cast(),
  );

  Pointer<cblite.CBLBlobReadStream> openContentStream(
    Pointer<cblite.CBLBlob> blob,
  ) => cblite.CBLBlob_OpenContentStream(blob, globalCBLError).checkError();

  void bindToDartObject(
    Finalizable object,
    Pointer<cblite.CBLBlobReadStream> pointer,
  ) {
    _finalizer.attach(object, pointer.cast());
  }

  Data? read(Pointer<cblite.CBLBlobReadStream> stream, int bufferSize) {
    final buffer = cblitedart.CBLDart_CBLBlobReader_Read(
      stream,
      bufferSize,
      globalCBLError,
    );

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

final class BlobWriteStreamBindings {
  const BlobWriteStreamBindings();

  Pointer<cblite.CBLBlobWriteStream> create(Pointer<cblite.CBLDatabase> db) =>
      cblite.CBLBlobWriter_Create(db, globalCBLError).checkError();

  void close(Pointer<cblite.CBLBlobWriteStream> stream) {
    cblite.CBLBlobWriter_Close(stream);
  }

  bool write(Pointer<cblite.CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return cblite.CBLBlobWriter_Write(
      stream,
      slice.buf,
      slice.size,
      globalCBLError,
    ).checkError();
  }

  Pointer<cblite.CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<cblite.CBLBlobWriteStream> stream,
  ) => runWithSingleFLString(
    contentType,
    (flContentType) => cblite.CBLBlob_CreateWithStream(flContentType, stream),
  );
}

// === BlobsBindings ===========================================================

final class BlobsBindings {
  const BlobsBindings();

  BlobBindings get blob => const BlobBindings();
  BlobReadStreamBindings get readStream => const BlobReadStreamBindings();
  BlobWriteStreamBindings get writeStream => const BlobWriteStreamBindings();
}
