import 'dart:async';
import 'dart:typed_data';

abstract class BlobStore {
  Future<Map<String, Object?>> saveBlobFromData(
    String contentType,
    Uint8List data,
  );

  Future<Map<String, Object?>> saveBlobFromStream(
    String contentType,
    Stream<Uint8List> stream,
  );

  Stream<Uint8List>? readBlob(Map<String, Object?> properties);
}

abstract class SyncBlobStore extends BlobStore {
  Map<String, Object?> saveBlobFromDataSync(
    String contentType,
    Uint8List data,
  );

  Uint8List? readBlobSync(Map<String, Object?> properties);
}

abstract class BlobStoreHolder {
  BlobStore get blobStore;
}
