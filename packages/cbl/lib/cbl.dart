export 'src/blob.dart' hide blobSlotSetter, BlobManagerImpl;
export 'src/couchbase_lite.dart'
    hide debugCouchbaseLiteIsInitialized, workerFactory;
export 'src/database.dart' hide DatabaseImpl;
export 'src/document.dart' hide createDocument, createMutableDocument;
export 'src/errors.dart' hide translateCBLErrorException, CBLErrorExceptionExt;
export 'src/fleece.dart' hide SlotSetter;
export 'src/query.dart' hide QueryImpl;
export 'src/replicator.dart'
    hide ReplicatorImpl, createReplicator, CBLReplicatorStatusExt;
export 'src/resource.dart' show Resource, ClosableResource;
