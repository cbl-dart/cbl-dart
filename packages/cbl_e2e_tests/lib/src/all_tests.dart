import 'bindings/bindings_test.dart' as bindings_bindings;
import 'database/collection_test.dart' as database_collection;
import 'database/database_change_test.dart' as database_database_change;
import 'database/database_configuration_test.dart'
    as database_database_configuration;
import 'database/database_test.dart' as database_database;
import 'database/document_change_test.dart' as database_document_change;
import 'database/typed_database_test.dart' as typed_database;
import 'document/array_test.dart' as document_array_test;
import 'document/blob_test.dart' as document_blob_test;
import 'document/dictionary_test.dart' as document_dictionary_test;
import 'document/document_test.dart' as document_document_test;
import 'document/fragment_test.dart' as document_fragment_test;
import 'errors_test.dart' as errors;
import 'fleece/coding_test.dart' as fleece_coding;
import 'fleece/containers_test.dart' as fleece_containers;
import 'fleece/integration_test.dart' as fleece_integration;
import 'fleece/slice_test.dart' as fleece_slice;
import 'log/consoler_logger_test.dart' as log_console_logger;
import 'log/file_logger_test.dart' as log_file_logger;
import 'log/logger_test.dart' as log_logger;
import 'query/index/index_configuration_test.dart'
    as query_index_index_configuration;
import 'query/parameters_test.dart' as query_parameters;
import 'query/query_builder_test.dart' as query_builder;
import 'query/query_test.dart' as query_query;
import 'query/result_test.dart' as query_result;
import 'replication/authenticator_test.dart' as replication_authenticator;
import 'replication/configuration_test.dart' as replication_configuration;
import 'replication/conflict_test.dart' as replication_conflict;
import 'replication/document_replication_test.dart'
    as replication_document_replication;
import 'replication/endpoint_test.dart' as replication_endpoint;
import 'replication/replicator_change_test.dart'
    as replication_replicator_change;
import 'replication/replicator_test.dart' as replication_replicator;
import 'replication/tls_identity_test.dart' as tls_identity;
import 'replication/url_endpoint_listener_test.dart' as url_endpoint_listener;
import 'service/cbl_worker_test.dart' as service_cbl_worker;
import 'service/channel_test.dart' as service_channel;
import 'service/isolate_worker_test.dart' as service_isolate_worker;
import 'support/async_callback_test.dart' as support_async_callback;
import 'tracing_test.dart' as tracing;
import 'typed_data/collection_test.dart' as typed_data_collection;
import 'typed_data/conversion_test.dart' as typed_data_conversion;
import 'typed_data/helpers_test.dart' as typed_data_helpers;
import 'typed_data/registry_test.dart' as typed_data_runtime_support;

final tests = [
  bindings_bindings.main,
  database_collection.main,
  database_database_change.main,
  database_database_configuration.main,
  database_database.main,
  database_document_change.main,
  document_array_test.main,
  document_blob_test.main,
  document_dictionary_test.main,
  document_document_test.main,
  document_fragment_test.main,
  errors.main,
  fleece_coding.main,
  fleece_containers.main,
  fleece_integration.main,
  fleece_slice.main,
  log_console_logger.main,
  log_file_logger.main,
  log_logger.main,
  query_builder.main,
  query_index_index_configuration.main,
  query_parameters.main,
  query_query.main,
  query_result.main,
  replication_authenticator.main,
  replication_configuration.main,
  replication_conflict.main,
  replication_document_replication.main,
  replication_endpoint.main,
  replication_replicator_change.main,
  replication_replicator.main,
  service_cbl_worker.main,
  service_channel.main,
  service_isolate_worker.main,
  support_async_callback.main,
  tls_identity.main,
  tracing.main,
  typed_data_collection.main,
  typed_data_conversion.main,
  typed_data_helpers.main,
  typed_data_runtime_support.main,
  typed_database.main,
  url_endpoint_listener.main,
];

void main() {
  for (final main in tests) {
    main();
  }
}
