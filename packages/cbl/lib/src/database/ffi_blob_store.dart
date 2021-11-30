import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/blob.dart';
import '../fleece/fleece.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/streams.dart';
import '../support/utils.dart';
import 'blob_store.dart';
import 'ffi_database.dart';

class FfiBlobStore implements BlobStore, SyncBlobStore {
  FfiBlobStore(this.database);

  static late final _databaseBindings = cblBindings.database;
  static late final _blobBindings = cblBindings.blobs.blob;

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
    final cblBlob = runNativeCalls(
        () => _databaseBindings.getBlob(database.pointer, dict.pointer.cast()));

    if (cblBlob == null) {
      return false;
    }

    cblBindings.base.releaseRefCounted(cblBlob.cast());

    return true;
  }

  @override
  Data? readBlobSync(Map<String, Object?> properties) =>
      _getBlob(properties)?.let((it) => it.native.call(_blobBindings.content));

  @override
  Stream<Data>? readBlob(Map<String, Object?> properties) =>
      _getBlob(properties)?.let((it) => _BlobReadStream(database, it));

  void _saveBlob(CBLObject<CBLBlob> blob) {
    runNativeCalls(() {
      _databaseBindings.saveBlob(database.native.pointer, blob.native.pointer);
    });
  }

  Map<String, Object?> _createBlobProperties(CBLObject<CBLBlob> blob) => {
        cblObjectTypeProperty: cblObjectTypeBlob,
        blobDigestProperty: blob.native.call(_blobBindings.digest),
        blobLengthProperty: blob.native.call(_blobBindings.length),
        blobContentTypeProperty: blob.native.call(_blobBindings.contentType),
      };

  CBLObject<CBLBlob>? _getBlob(Map<String, Object?> properties) {
    final dict = MutableDict(properties);
    final blobPointer = runNativeCalls(() => _databaseBindings.getBlob(
          database.native.pointer,
          dict.native.pointer.cast(),
        ));

    return blobPointer?.let((it) => CBLObject(
          it,
          debugName: 'NativeBlobStore._getBlob',
        ));
  }
}

late final _writeStreamBindings = cblBindings.blobs.writeStream;

Future<CBLObject<CBLBlob>> _createBlobFromStream(
  FfiDatabase database,
  Stream<Data> stream,
  String contentType,
) async {
  final writeStream = database.native.call(_writeStreamBindings.create);

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

  static late final _readStreamBindings = cblBindings.blobs.readStream;

  final ClosableResourceMixin parent;
  final CBLObject<CBLBlob> blob;

  late final _controller = StreamController<Data>(
    onListen: _start,
    onPause: _pause,
    onResume: _start,
    onCancel: _pause,
  );

  late final _stream = CBLBlobReadStreamObject(
    blob.native.call(_readStreamBindings.openContentStream),
  );

  var _isPaused = false;

  void _start() {
    try {
      _isPaused = false;

      while (!_isPaused) {
        final buffer = _stream.call((pointer) =>
            _readStreamBindings.read(pointer, _readStreamChunkSize));

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
