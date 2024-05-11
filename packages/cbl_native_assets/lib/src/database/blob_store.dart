import 'dart:async';

import '../bindings.dart';

abstract interface class BlobStore {
  Future<Map<String, Object?>> saveBlobFromData(String contentType, Data data);

  Future<Map<String, Object?>> saveBlobFromStream(
    String contentType,
    Stream<Data> stream,
  );

  FutureOr<bool> blobExists(Map<String, Object?> properties);

  Stream<Data>? readBlob(Map<String, Object?> properties);
}

abstract interface class SyncBlobStore extends BlobStore {
  Map<String, Object?> saveBlobFromDataSync(String contentType, Data data);

  @override
  bool blobExists(Map<String, Object?> properties);

  Data? readBlobSync(Map<String, Object?> properties);
}

abstract interface class BlobStoreHolder {
  BlobStore get blobStore;
}
