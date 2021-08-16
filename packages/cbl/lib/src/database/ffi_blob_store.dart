import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../document/blob.dart';
import '../fleece/fleece.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
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
    final blob = CblObject(
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
  Data? readBlobSync(Map<String, Object?> properties) =>
      _getBlob(properties)?.let((it) => it.native.call(_blobBindings.content));

  @override
  Stream<Data>? readBlob(Map<String, Object?> properties) =>
      _getBlob(properties)
          ?.let((it) => _BlobReadStreamController(database, it).stream);

  void _saveBlob(CblObject<CBLBlob> blob) {
    runNativeCalls(() {
      _databaseBindings.saveBlob(database.native.pointer, blob.native.pointer);
    });
  }

  Map<String, Object?> _createBlobProperties(CblObject<CBLBlob> blob) => {
        cblObjectTypeProperty: cblObjectTypeBlob,
        blobDigestProperty: blob.native.call(_blobBindings.digest),
        blobLengthProperty: blob.native.call(_blobBindings.length),
        blobContentTypeProperty: blob.native.call(_blobBindings.contentType),
      };

  CblObject<CBLBlob>? _getBlob(Map<String, Object?> properties) {
    final dict = MutableDict(properties);
    final blobPointer = runNativeCalls(() => _databaseBindings.getBlob(
          database.native.pointer,
          dict.native.pointer.cast(),
        ));

    return blobPointer?.let((it) => CblObject(
          it,
          debugName: 'NativeBlobStore._getBlob',
        ));
  }
}

late final _writeStreamBindings = cblBindings.blobs.writeStream;

Future<CblObject<CBLBlob>> _createBlobFromStream(
  FfiDatabase database,
  Stream<Data> stream,
  String contentType,
) async {
  final writeStream = database.native.call(_writeStreamBindings.create);

  try {
    await stream
        .forEach((data) => _writeStreamBindings.write(writeStream, data));

    return CblObject(
      _writeStreamBindings.createBlobWithStream(contentType, writeStream),
      debugName: '_createBlobFromStream',
    );
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    _writeStreamBindings.close(writeStream);
    rethrow;
  }
}

class _BlobReadStreamController extends ClosableResourceStreamController<Data> {
  _BlobReadStreamController(FfiDatabase database, this.blob)
      : super(parent: database);

  /// Size of the chunks which a blob read stream emits.
  static const _readStreamChunkSize = 8 * 1024;

  static late final _readStreamBindings = cblBindings.blobs.readStream;

  final CblObject<CBLBlob> blob;

  late final _stream = CBLBlobReadStreamObject(
    blob.native.call(_readStreamBindings.openContentStream),
  );

  var _isPaused = false;

  @override
  void onListen() => _start();

  @override
  void onPause() => _pause();

  @override
  void onResume() => _start();

  @override
  void onCancel() => _pause();

  void _start() {
    try {
      _isPaused = false;

      while (!_isPaused) {
        final buffer = _stream.call((pointer) =>
            _readStreamBindings.read(pointer, _readStreamChunkSize));

        // The read stream is done (EOF).
        if (buffer == null) {
          controller.close();
          break;
        }

        controller.add(buffer);
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      controller
        ..addError(error, stackTrace)
        ..close();
    }
  }

  void _pause() => _isPaused = true;
}
