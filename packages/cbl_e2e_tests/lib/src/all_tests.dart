import 'database_test.dart' as database;
import 'document/array_test.dart' as document_array_test;
import 'document/blob_test.dart' as document_blob_test;
import 'document/dictionary_test.dart' as document_dictionary_test;
import 'document/document_test.dart' as document_document_test;
import 'document/fragment_test.dart' as document_fragment_test;
import 'fleece/coding_test.dart' as fleece_coding;
import 'fleece/containers_test.dart' as fleece_containers;
import 'fleece/integration_test.dart' as fleece_integration;
import 'fleece/slice_test.dart' as fleece_slice;
import 'logging_test.dart' as logging;
import 'support/native_callback_test.dart' as native_callback;
import 'replication/authenticator_test.dart' as replication_authenticator;
import 'replication/configuration_test.dart' as replication_configuration;
import 'replication/conflict_test.dart' as replication_conflict;
import 'replication/document_replication_test.dart'
    as replication_document_replication;
import 'replication/endpoint_test.dart' as replication_endpoint;
import 'replication/replicator_change_test.dart'
    as replication_replicator_change;
import 'replication/replicator_test.dart' as replication_replicator;

final tests = [
  database.main,
  document_array_test.main,
  document_blob_test.main,
  document_dictionary_test.main,
  document_document_test.main,
  document_fragment_test.main,
  fleece_coding.main,
  fleece_containers.main,
  fleece_integration.main,
  fleece_slice.main,
  logging.main,
  native_callback.main,
  replication_authenticator.main,
  replication_configuration.main,
  replication_conflict.main,
  replication_document_replication.main,
  replication_endpoint.main,
  replication_replicator_change.main,
  replication_replicator.main,
];

void main() {
  for (final main in tests) {
    main();
  }
}
