import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _readStreamBindings = CBLBindings.instance.blobs.readStream;

class OpenBlobReadStream
    extends WorkerRequest<TransferablePointer<CBLBlobReadStream>> {
  OpenBlobReadStream(Pointer<CBLBlob> blob, this.bufferSize)
      : blob = blob.toTransferablePointer();

  final TransferablePointer<CBLBlob> blob;

  final int bufferSize;
}

TransferablePointer<CBLBlobReadStream> openBlobReadStream(
        OpenBlobReadStream request) =>
    _readStreamBindings
        .openContentStream(request.blob.pointer, request.bufferSize)
        .toTransferablePointer();

class ReadFromBlobReadStream extends WorkerRequest<BlobStreamBuffer?> {
  ReadFromBlobReadStream(Pointer<CBLBlobReadStream> stream)
      : stream = stream.toTransferablePointer();

  final TransferablePointer<CBLBlobReadStream> stream;
}

BlobStreamBuffer? readFromBlobReadStream(ReadFromBlobReadStream request) =>
    _readStreamBindings.read(request.stream.pointer);

class CloseBlobReadStream extends WorkerRequest<void> {
  CloseBlobReadStream(Pointer<CBLBlobReadStream> stream)
      : stream = stream.toTransferablePointer();

  final TransferablePointer<CBLBlobReadStream> stream;
}

void closeBlobReadStream(CloseBlobReadStream request) =>
    _readStreamBindings.close(request.stream.pointer);

late final _writeStreamBindings = CBLBindings.instance.blobs.writeStream;

class OpenBlobWriteStream
    extends WorkerRequest<TransferablePointer<CBLBlobWriteStream>> {
  OpenBlobWriteStream(Pointer<CBLDatabase> db)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
}

TransferablePointer<CBLBlobWriteStream> openBlobWriteStream(
        OpenBlobWriteStream request) =>
    _writeStreamBindings.create(request.db.pointer).toTransferablePointer();

class WriteToBlobWriteStream extends WorkerRequest<void> {
  WriteToBlobWriteStream(
    Pointer<CBLBlobWriteStream> stream,
    Uint8List chunk,
  )   : stream = stream.toTransferablePointer(),
        chunk = TransferableTypedData.fromList([chunk]);

  final TransferablePointer<CBLBlobWriteStream> stream;

  final TransferableTypedData chunk;
}

void writeToBlobWriteStream(WriteToBlobWriteStream request) =>
    _writeStreamBindings.write(
      request.stream.pointer,
      request.chunk.materialize().asUint8List(),
    );

class CloseBlobWriteStream extends WorkerRequest<void> {
  CloseBlobWriteStream(Pointer<CBLBlobWriteStream> stream)
      : stream = stream.toTransferablePointer();

  final TransferablePointer<CBLBlobWriteStream> stream;
}

void closeBlobWriteStream(CloseBlobWriteStream request) =>
    _writeStreamBindings.close(request.stream.pointer);

class CreateBlobWithWriteStream
    extends WorkerRequest<TransferablePointer<CBLBlob>> {
  CreateBlobWithWriteStream(
    Pointer<CBLBlobWriteStream> stream,
    this.contentType,
  ) : stream = stream.toTransferablePointer();

  final TransferablePointer<CBLBlobWriteStream> stream;

  final String? contentType;
}

TransferablePointer<CBLBlob> createBlobWithWriteStream(
  CreateBlobWithWriteStream request,
) =>
    _writeStreamBindings
        .createBlobWithStream(request.contentType, request.stream.pointer)
        .toTransferablePointer();

void addBlobHandlersToRouter(RequestRouter router) {
  router.addHandler(openBlobReadStream);
  router.addHandler(readFromBlobReadStream);
  router.addHandler(closeBlobReadStream);
  router.addHandler(openBlobWriteStream);
  router.addHandler(writeToBlobWriteStream);
  router.addHandler(closeBlobWriteStream);
  router.addHandler(createBlobWithWriteStream);
}
