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
import 'native_callback_test.dart' as native_callback;
import 'replication/replicator_test.dart' as replication_replicator;

final tests = {
  'database': database.main,
  'document/array': document_array_test.main,
  'document/blob': document_blob_test.main,
  'document/dictionary': document_dictionary_test.main,
  'document/document': document_document_test.main,
  'document/fragment': document_fragment_test.main,
  'fleece/coding': fleece_coding.main,
  'fleece/integration': fleece_integration.main,
  'fleece/slice': fleece_slice.main,
  'fleece/containers': fleece_containers.main,
  'logging': logging.main,
  'native_callback': native_callback.main,
  'replication/replicator': replication_replicator.main,
};

void main() {
  for (final main in tests.values) {
    main();
  }
}
