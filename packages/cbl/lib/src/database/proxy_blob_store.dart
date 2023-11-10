import '../bindings.dart';
import '../service/cbl_service_api.dart';
import 'blob_store.dart';
import 'proxy_database.dart';

class ProxyBlobStore implements BlobStore {
  ProxyBlobStore(this.database);

  final ProxyDatabase database;

  @override
  Future<bool> blobExists(Map<String, Object?> properties) =>
      database.channel.call(BlobExists(
        databaseId: database.objectId,
        properties: properties,
      ));

  @override
  Stream<Data>? readBlob(Map<String, Object?> properties) => database.channel
      .stream(ReadBlob(
        databaseId: database.objectId,
        properties: properties,
      ))
      .map((event) => event.data);

  @override
  Future<Map<String, Object?>> saveBlobFromData(
    String contentType,
    Data data,
  ) =>
      saveBlobFromStream(contentType, Stream.value(data));

  @override
  Future<Map<String, Object?>> saveBlobFromStream(
    String contentType,
    Stream<Data> stream,
  ) =>
      database.channel
          .call(SaveBlob(
            databaseId: database.objectId,
            contentType: contentType,
            uploadId: database.client.registerBlobUpload(stream),
          ))
          .then((response) => response.properties);
}
