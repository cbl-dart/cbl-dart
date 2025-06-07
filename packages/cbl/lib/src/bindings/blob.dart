import 'dart:ffi';

import 'base.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'data.dart';
import 'fleece.dart';
import 'global.dart';
import 'slice.dart';
import 'utils.dart';

export 'cblite.dart' show CBLBlob, CBLBlobReadStream;

// === CBLBlob =================================================================

final class BlobBindings extends Bindings {
  BlobBindings(super.libraries);

  Pointer<cblite_lib.CBLBlob> createWithData(
    String? contentType,
    Data content,
  ) => runWithSingleFLString(contentType, (flContentType) {
    final sliceResult = content.toSliceResult();
    return cblite.CBLBlob_CreateWithData(
      flContentType,
      sliceResult.makeGlobal().ref,
    );
  });

  bool isBlob(cblite_lib.FLDict dict) => cblite.FLDict_IsBlob(dict);

  Pointer<cblite_lib.CBLBlob>? getBlob(cblite_lib.FLDict dict) =>
      cblite.FLDict_GetBlob(dict).toNullable();

  void setBlob(cblite_lib.FLSlot slot, Pointer<cblite_lib.CBLBlob> blob) =>
      cblite.FLSlot_SetBlob(slot, blob);

  int length(Pointer<cblite_lib.CBLBlob> blob) => cblite.CBLBlob_Length(blob);

  String digest(Pointer<cblite_lib.CBLBlob> blob) =>
      cblite.CBLBlob_Digest(blob).toDartString()!;

  Data content(Pointer<cblite_lib.CBLBlob> blob) => cblite.CBLBlob_Content(
    blob,
    globalCBLError,
  ).checkError().let(SliceResult.fromFLSliceResult)!.toData();

  String? contentType(Pointer<cblite_lib.CBLBlob> blob) =>
      cblite.CBLBlob_ContentType(blob).toDartString();

  cblite_lib.FLDict properties(Pointer<cblite_lib.CBLBlob> blob) =>
      cblite.CBLBlob_Properties(blob);
}

// === CBLBlobReadStream =======================================================

final class BlobReadStreamBindings extends Bindings {
  BlobReadStreamBindings(super.libraries);

  late final _finalizer = NativeFinalizer(
    cblite.addresses.CBLBlobReader_Close.cast(),
  );

  Pointer<cblite_lib.CBLBlobReadStream> openContentStream(
    Pointer<cblite_lib.CBLBlob> blob,
  ) => cblite.CBLBlob_OpenContentStream(blob, globalCBLError).checkError();

  void bindToDartObject(
    Finalizable object,
    Pointer<cblite_lib.CBLBlobReadStream> pointer,
  ) {
    _finalizer.attach(object, pointer.cast());
  }

  Data? read(Pointer<cblite_lib.CBLBlobReadStream> stream, int bufferSize) {
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

final class BlobWriteStreamBindings extends Bindings {
  BlobWriteStreamBindings(super.libraries);

  Pointer<cblite_lib.CBLBlobWriteStream> create(
    Pointer<cblite_lib.CBLDatabase> db,
  ) => cblite.CBLBlobWriter_Create(db, globalCBLError).checkError();

  void close(Pointer<cblite_lib.CBLBlobWriteStream> stream) {
    cblite.CBLBlobWriter_Close(stream);
  }

  bool write(Pointer<cblite_lib.CBLBlobWriteStream> stream, Data data) {
    final slice = data.toSliceResult();
    return cblite.CBLBlobWriter_Write(
      stream,
      slice.buf,
      slice.size,
      globalCBLError,
    ).checkError();
  }

  Pointer<cblite_lib.CBLBlob> createBlobWithStream(
    String? contentType,
    Pointer<cblite_lib.CBLBlobWriteStream> stream,
  ) => runWithSingleFLString(
    contentType,
    (flContentType) => cblite.CBLBlob_CreateWithStream(flContentType, stream),
  );
}

// === BlobsBindings ===========================================================

final class BlobsBindings extends Bindings {
  BlobsBindings(super.libraries)
    : blob = BlobBindings(libraries),
      readStream = BlobReadStreamBindings(libraries),
      writeStream = BlobWriteStreamBindings(libraries);

  final BlobBindings blob;
  final BlobReadStreamBindings readStream;
  final BlobWriteStreamBindings writeStream;
}
