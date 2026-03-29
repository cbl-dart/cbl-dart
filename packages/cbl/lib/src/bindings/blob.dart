import 'dart:convert';
import 'dart:ffi';

import '../support/isolate.dart';
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
  static Pointer<cblite.CBLBlob> createWithData(
    String? contentType,
    Data content,
  ) {
    ensureInitializedForCurrentIsolate();
    final sliceResult = content.toSliceResult();
    if (contentType == null) {
      return cblitedart.CBLDart_CBLBlob_CreateWithData(
        nullptr,
        0,
        sliceResult.buf,
        sliceResult.size,
      );
    }
    final ctEncoded = utf8.encode(contentType);
    return cblitedart.CBLDart_CBLBlob_CreateWithData(
      ctEncoded.address.cast(),
      ctEncoded.length,
      sliceResult.buf,
      sliceResult.size,
    );
  }

  static bool isBlob(cblite.FLDict dict) => cblite.FLDict_IsBlob(dict);

  static Pointer<cblite.CBLBlob>? getBlob(cblite.FLDict dict) =>
      cblite.FLDict_GetBlob(dict).toNullable();

  static void setBlob(cblite.FLSlot slot, Pointer<cblite.CBLBlob> blob) =>
      cblite.FLSlot_SetBlob(slot, blob);

  static int length(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_Length(blob);

  static String digest(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_Digest(blob).toDartString()!;

  static Data content(Pointer<cblite.CBLBlob> blob) => cblite.CBLBlob_Content(
    blob,
    globalCBLError,
  ).checkError().let(SliceResult.fromFLSliceResult)!.toData();

  static String? contentType(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_ContentType(blob).toDartString();

  static cblite.FLDict properties(Pointer<cblite.CBLBlob> blob) =>
      cblite.CBLBlob_Properties(blob);
}

// === CBLBlobReadStream =======================================================

final class BlobReadStreamBindings {
  static final _finalizer = NativeFinalizer(
    cblite.addresses.CBLBlobReader_Close.cast(),
  );

  static Pointer<cblite.CBLBlobReadStream> openContentStream(
    Pointer<cblite.CBLBlob> blob,
  ) => cblite.CBLBlob_OpenContentStream(blob, globalCBLError).checkError();

  static void bindToDartObject(
    Finalizable object,
    Pointer<cblite.CBLBlobReadStream> pointer,
  ) {
    _finalizer.attach(object, pointer.cast());
  }

  static Data? read(Pointer<cblite.CBLBlobReadStream> stream, int bufferSize) {
    final buffer = cblitedart.CBLDart_CBLBlobReader_Read(
      stream,
      bufferSize,
      globalCBLError,
    );

    // A null slice signals an error.
    if (buffer.buf == nullptr) {
      throwError();
    }

    // Empty buffer means stream has been fully read, but it's important to
    // create a SliceResult to ensure the FLSliceResult is freed.
    final sliceResult = SliceResult.fromFLSliceResult(buffer)!;
    return sliceResult.size == 0 ? null : sliceResult.toData();
  }
}

// === CBLBlobWriteStream ======================================================

final class BlobWriteStreamBindings {
  static Pointer<cblite.CBLBlobWriteStream> create(
    Pointer<cblite.CBLDatabase> db,
  ) => cblite.CBLBlobWriter_Create(db, globalCBLError).checkError();

  static void close(Pointer<cblite.CBLBlobWriteStream> stream) {
    cblite.CBLBlobWriter_Close(stream);
  }

  static bool write(Pointer<cblite.CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return cblite.CBLBlobWriter_Write(
      stream,
      slice.buf,
      slice.size,
      globalCBLError,
    ).checkError();
  }

  static Pointer<cblite.CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<cblite.CBLBlobWriteStream> stream,
  ) {
    if (contentType == null) {
      return cblitedart.CBLDart_CBLBlob_CreateWithStream(nullptr, 0, stream);
    }
    final ctEncoded = utf8.encode(contentType);
    return cblitedart.CBLDart_CBLBlob_CreateWithStream(
      ctEncoded.address.cast(),
      ctEncoded.length,
      stream,
    );
  }
}
