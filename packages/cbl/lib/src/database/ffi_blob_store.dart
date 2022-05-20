import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/blob.dart';
import '../fleece/containers.dart';
import '../support/errors.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'blob_store.dart';
import 'ffi_database.dart';

class FfiBlobStore implements BlobStore, SyncBlobStore {
  FfiBlobStore(this.database);

  static final _databaseBindings = cblBindings.database;
  static final _blobBindings = cblBindings.blobs.blob;

  final FfiDatabase database;

  @override
  Map<String, Object?> saveBlobFromDataSync(String contentType, Data data) {
    final blob = CBLObject(
      _blobBindings.createWithData(contentType, data),
      debugName: 'NativeBlobStore.saveBlobFromDataSync()',
    );
    _saveBlob(blob);
    return _createBlobProperties(blob);
  }

  @override
  Future<Map<String, Object?>> saveBlobFromData(
    String contentType,
    Data data,
  ) async =>
      saveBlobFromDataSync(contentType, data);

  @override
  Future<Map<String, Object?>> saveBlobFromStream(
    String contentType,
    Stream<Data> stream,
  ) async {
    final blob = await _createBlobFromStream(database, stream, contentType);
    _saveBlob(blob);
    return _createBlobProperties(blob);
  }

  @override
  bool blobExists(Map<String, Object?> properties) {
    final dict = MutableDict(properties);
    final cblBlob = runWithErrorTranslation(
      () => _databaseBindings.getBlob(database.pointer, dict.pointer.cast()),
    );
    cblReachabilityFence(database);

    if (cblBlob == null) {
      return false;
    }

    cblBindings.base.releaseRefCounted(cblBlob.cast());

    return true;
  }

  @override
  Data? readBlobSync(Map<String, Object?> properties) =>
      _getBlob(properties)?.let((it) {
        final result =
            runWithErrorTranslation(() => _blobBindings.content(it.pointer));
        cblReachabilityFence(it);
        return result;
      });

  @override
  Stream<Data>? readBlob(Map<String, Object?> properties) =>
      _getBlob(properties)?.let((it) => _BlobReadStream(database, it));

  void _saveBlob(CBLObject<CBLBlob> blob) {
    runWithErrorTranslation(
      () => _databaseBindings.saveBlob(database.pointer, blob.pointer),
    );
    cblReachabilityFence(database);
    cblReachabilityFence(blob);
  }

  Map<String, Object?> _createBlobProperties(CBLObject<CBLBlob> blob) {
    final result = <String, Object?>{
      cblObjectTypeProperty: cblObjectTypeBlob,
      blobDigestProperty: _blobBindings.digest(blob.pointer),
      blobLengthProperty: _blobBindings.length(blob.pointer),
      blobContentTypeProperty: _blobBindings.contentType(blob.pointer),
    };
    cblReachabilityFence(blob);
    return result;
  }

  CBLObject<CBLBlob>? _getBlob(Map<String, Object?> properties) {
    final dict = MutableDict(properties);
    final blobPointer = runWithErrorTranslation(
      () => _databaseBindings.getBlob(database.pointer, dict.pointer.cast()),
    );
    cblReachabilityFence(database);

    return blobPointer
        ?.let((it) => CBLObject(it, debugName: 'NativeBlobStore._getBlob'));
  }
}

final _writeStreamBindings = cblBindings.blobs.writeStream;

Future<CBLObject<CBLBlob>> _createBlobFromStream(
  FfiDatabase database,
  Stream<Data> stream,
  String contentType,
) async {
  final writeStream = runWithErrorTranslation(
    () => _writeStreamBindings.create(database.pointer),
  );
  cblReachabilityFence(database);

  try {
    await stream
        .forEach((data) => _writeStreamBindings.write(writeStream, data));

    return CBLObject(
      _writeStreamBindings.createBlobWithStream(contentType, writeStream),
      debugName: '_createBlobFromStream',
    );
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    _writeStreamBindings.close(writeStream);
    rethrow;
  }
}

class _BlobReadStream extends Stream<Data> {
  _BlobReadStream(this.parent, this.blob);

  /// Size of the chunks which a blob read stream emits.
  static const _readStreamChunkSize = 8 * 1024;

  static final _readStreamBindings = cblBindings.blobs.readStream;

  final ClosableResourceMixin parent;
  final CBLObject<CBLBlob> blob;

  late final _controller = StreamController<Data>(
    onListen: _start,
    onPause: _pause,
    onResume: _start,
    onCancel: _pause,
  );

  late final _stream = () {
    final result = CBLBlobReadStreamObject(
      _readStreamBindings.openContentStream(blob.pointer),
    );
    cblReachabilityFence(blob);
    return result;
  }();

  var _isPaused = false;

  void _start() {
    try {
      _isPaused = false;

      while (!_isPaused) {
        final buffer = runWithErrorTranslation(
          () => _readStreamBindings.read(_stream.pointer, _readStreamChunkSize),
        );
        cblReachabilityFence(_stream);

        // The read stream is done (EOF).
        if (buffer == null) {
          _controller.close();
          break;
        }

        _controller.add(buffer);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      _controller
        ..addError(error, stackTrace)
        ..close();
    }
  }

  void _pause() => _isPaused = true;

  @override
  StreamSubscription<Data> listen(
    void Function(Data event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _controller.stream
          .transform(ResourceStreamTransformer(parent: parent, blocking: true))
          .listen(
            onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
          );
}
