import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../errors.dart';
import '../request_router.dart';
import 'shared.dart';

late final _readStreamBindings = CBLBindings.instance.blobs.readStream;

class OpenBlobReadStream extends ObjectRequest<CBLBlob, int> {
  OpenBlobReadStream(Pointer<CBLBlob> blob) : super(blob);
}

int openBlobReadStream(OpenBlobReadStream request) => _readStreamBindings
    .openContentStream(request.object, globalError)
    .checkResultAndError()
    .address;

class ReadFromBlobReadStream extends ObjectRequest<CBLBlobReadStream, int> {
  ReadFromBlobReadStream(
    Pointer<CBLBlobReadStream> stream,
    this._bufferAddress,
    this.bufferSize,
  ) : super(stream);

  final int _bufferAddress;

  final int bufferSize;

  Pointer<Uint8> get bufferPointer => _bufferAddress.toPointer().cast();
}

int readFromBlobReadStream(ReadFromBlobReadStream request) {
  final bytesRead = _readStreamBindings.read(
    request.object,
    request.bufferPointer,
    request.bufferSize,
    globalError,
  );

  if (bytesRead == -1) {
    checkError();
  }

  return bytesRead;
}

class CloseBlobReadStream extends ObjectRequest<CBLBlobReadStream, void> {
  CloseBlobReadStream(Pointer<CBLBlobReadStream> stream) : super(stream);
}

void closeBlobReadStream(CloseBlobReadStream request) =>
    _readStreamBindings.close(request.object);

late final _writeStreamBindings = CBLBindings.instance.blobs.writeStream;

class OpenBlobWriteStream extends ObjectRequest<CBLDatabase, int> {
  OpenBlobWriteStream(Pointer<CBLDatabase> db) : super(db);
}

int openBlobWriteStream(OpenBlobWriteStream request) => _writeStreamBindings
    .makeNew(request.object, globalError)
    .checkResultAndError()
    .address;

class WriteToBlobWriteStream extends ObjectRequest<CBLBlobWriteStream, void> {
  WriteToBlobWriteStream(
    Pointer<CBLBlobWriteStream> stream,
    this._chunkAddress,
    this.chunkSize,
  ) : super(stream);

  final int _chunkAddress;

  final int chunkSize;

  Pointer<Uint8> get chunkPointer => Pointer.fromAddress(_chunkAddress);
}

void writeToBlobWriteStream(WriteToBlobWriteStream request) =>
    _writeStreamBindings
        .write(
          request.object,
          request.chunkPointer,
          request.chunkSize,
          globalError,
        )
        .toBool()
        .checkResultAndError();

class CloseBlobWriteStream extends ObjectRequest<CBLBlobWriteStream, void> {
  CloseBlobWriteStream(Pointer<CBLBlobWriteStream> stream) : super(stream);
}

void closeBlobWriteStream(CloseBlobWriteStream request) =>
    _writeStreamBindings.close(request.object);

class CreateBlobWithWriteStream extends ObjectRequest<CBLBlobWriteStream, int> {
  CreateBlobWithWriteStream(
    Pointer<CBLBlobWriteStream> stream,
    this.contentType,
  ) : super(stream);

  final String? contentType;
}

int createBlobWithWriteStream(CreateBlobWithWriteStream request) =>
    _writeStreamBindings
        .createBlobWithStream(
          (request.contentType?.toNativeUtf8().withScoped()).elseNullptr(),
          request.object,
        )
        .address;

void addBlobHandlersToRouter(RequestRouter router) {
  router.addHandler(openBlobReadStream);
  router.addHandler(readFromBlobReadStream);
  router.addHandler(closeBlobReadStream);
  router.addHandler(openBlobWriteStream);
  router.addHandler(writeToBlobWriteStream);
  router.addHandler(closeBlobWriteStream);
  router.addHandler(createBlobWithWriteStream);
}
