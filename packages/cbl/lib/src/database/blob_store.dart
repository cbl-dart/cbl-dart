import 'dart:async';

import 'package:cbl_ffi/cbl_ffi.dart';

abstract class BlobStore {
  Future<Map<String, Object?>> saveBlobFromData(String contentType, Data data);

  Future<Map<String, Object?>> saveBlobFromStream(
    String contentType,
    Stream<Data> stream,
  );

  Stream<Data>? readBlob(Map<String, Object?> properties);
}

abstract class SyncBlobStore extends BlobStore {
  Map<String, Object?> saveBlobFromDataSync(String contentType, Data data);

  Data? readBlobSync(Map<String, Object?> properties);
}

abstract class BlobStoreHolder {
  BlobStore get blobStore;
}
