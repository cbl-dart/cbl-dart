import 'database/database_change_test.dart' as database_database_change;
import 'database/database_configuration_test.dart'
    as database_database_configuration;
import 'database/database_test.dart' as database_database;
import 'database/document_change_test.dart' as database_document_change;
import 'document/array_test.dart' as document_array_test;
import 'document/blob_test.dart' as document_blob_test;
import 'document/dictionary_test.dart' as document_dictionary_test;
import 'document/document_test.dart' as document_document_test;
import 'document/fragment_test.dart' as document_fragment_test;
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
import 'service/cbl_service_api_test.dart' as service_cbl_service_api;
import 'service/cbl_worker_test.dart' as service_cbl_worker;
import 'service/channel_test.dart' as service_channel;
import 'service/isolate_worker_test.dart' as service_isolate_worker;
import 'support/async_callback_test.dart' as support_async_callback;
import 'support/dart_finalizer_test.dart' as support_dart_finalizer;

final tests = [
  database_database_change.main,
  database_database_configuration.main,
  database_database.main,
  database_document_change.main,
  document_array_test.main,
  document_blob_test.main,
  document_dictionary_test.main,
  document_document_test.main,
  document_fragment_test.main,
  fleece_coding.main,
  fleece_containers.main,
  fleece_integration.main,
  fleece_slice.main,
  log_console_logger.main,
  log_file_logger.main,
  log_logger.main,
  query_index_index_configuration.main,
  query_parameters.main,
  query_builder.main,
  query_query.main,
  query_result.main,
  replication_authenticator.main,
  replication_configuration.main,
  replication_conflict.main,
  replication_document_replication.main,
  replication_endpoint.main,
  replication_replicator_change.main,
  replication_replicator.main,
  service_cbl_service_api.main,
  service_cbl_worker.main,
  service_isolate_worker.main,
  service_channel.main,
  support_async_callback.main,
  support_dart_finalizer.main,
];

void main() {
  for (final main in tests) {
    main();
  }
}
