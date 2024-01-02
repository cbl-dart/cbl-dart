import 'dart:async';
import 'dart:ffi';

import '../bindings.dart';
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

class _FfiBlob implements Finalizable {
  _FfiBlob.fromPointer(this.pointer, {bool adopt = false}) {
    bindCBLRefCountedToDartObject(
      this,
      pointer: pointer,
      adopt: adopt,
    );
  }

  _FfiBlob.createWithData(String contentType, Data data)
      : this.fromPointer(
          _blobBindings.createWithData(contentType, data),
          adopt: true,
        );

  static final _blobBindings = cblBindings.blobs.blob;

  final Pointer<CBLBlob> pointer;

  Data content() =>
      runWithErrorTranslation(() => _blobBindings.content(pointer));

  Map<String, Object?> createBlobProperties() => {
        cblObjectTypeProperty: cblObjectTypeBlob,
        blobDigestProperty: _blobBindings.digest(pointer),
        blobLengthProperty: _blobBindings.length(pointer),
        blobContentTypeProperty: _blobBindings.contentType(pointer),
      };
}

class FfiBlobStore implements BlobStore, SyncBlobStore {
  FfiBlobStore(this.database);

  static final _databaseBindings = cblBindings.database;

  final FfiDatabase database;

  @override
  Map<String, Object?> saveBlobFromDataSync(String contentType, Data data) {
    final blob = _FfiBlob.createWithData(contentType, data);
    _saveBlob(blob);
    return blob.createBlobProperties();
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
    return blob.createBlobProperties();
  }

  @override
  bool blobExists(Map<String, Object?> properties) {
    final dict = MutableDict(properties);
    final cblBlob = runWithErrorTranslation(
      () => _databaseBindings.getBlob(database.pointer, dict.pointer.cast()),
    );

    if (cblBlob == null) {
      return false;
    }

    cblBindings.base.releaseRefCounted(cblBlob.cast());

    return true;
  }

  @override
  Data? readBlobSync(Map<String, Object?> properties) =>
      _getBlob(properties)?.content();

  @override
  Stream<Data>? readBlob(Map<String, Object?> properties) =>
      _getBlob(properties)?.let((it) => _BlobReadStream(database, it));

  void _saveBlob(_FfiBlob blob) {
    runWithErrorTranslation(
      () => _databaseBindings.saveBlob(database.pointer, blob.pointer),
    );
  }

  _FfiBlob? _getBlob(Map<String, Object?> properties) {
    final dict = MutableDict(properties);
    final pointer = runWithErrorTranslation(
      () => _databaseBindings.getBlob(database.pointer, dict.pointer.cast()),
    );

    return pointer
        ?.let((pointer) => _FfiBlob.fromPointer(pointer, adopt: true));
  }
}

final _writeStreamBindings = cblBindings.blobs.writeStream;

Future<_FfiBlob> _createBlobFromStream(
  FfiDatabase database,
  Stream<Data> stream,
  String contentType,
) async {
  final writeStream = runWithErrorTranslation(
    () => _writeStreamBindings.create(database.pointer),
  );

  try {
    await stream
        .forEach((data) => _writeStreamBindings.write(writeStream, data));

    return _FfiBlob.fromPointer(
      _writeStreamBindings.createBlobWithStream(contentType, writeStream),
      adopt: true,
    );
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    _writeStreamBindings.close(writeStream);
    rethrow;
  }
}

class _BlobReadStream extends Stream<Data> implements Finalizable {
  _BlobReadStream(this.parent, this.blob);

  /// Size of the chunks which a blob read stream emits.
  static const _readStreamChunkSize = 8 * 1024;

  static final _readStreamBindings = cblBindings.blobs.readStream;

  final ClosableResourceMixin parent;
  final _FfiBlob blob;

  late final _controller = StreamController<Data>(
    onListen: _start,
    onPause: _pause,
    onResume: _start,
    onCancel: _pause,
  );

  late final Pointer<CBLBlobReadStream> pointer = () {
    final pointer = _readStreamBindings.openContentStream(blob.pointer);
    _readStreamBindings.bindToDartObject(this, pointer);
    return pointer;
  }();

  var _isPaused = false;

  void _start() {
    try {
      _isPaused = false;

      while (!_isPaused) {
        final buffer = runWithErrorTranslation(
          () => _readStreamBindings.read(pointer, _readStreamChunkSize),
        );

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
