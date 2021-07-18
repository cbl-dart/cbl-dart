import 'database_test.dart' as database;
import 'document/array_test.dart' as document_array_test;
import 'document/blob_test.dart' as document_blob_test;
import 'document/dictionary_test.dart' as document_dictionary_test;
import 'document/document_test.dart' as document_document_test;
import 'fleece/coding_test.dart' as fleece_coding;
import 'fleece/containers_test.dart' as fleece_containers;
import 'fleece/integration_test.dart' as fleece_integration;
import 'fleece/slice_test.dart' as fleece_slice;
import 'logging_test.dart' as logging;
import 'native_callback_test.dart' as native_callback;
import 'replicator_test.dart' as replicator;

final tests = {
  'database': database.main,
  'document_array': document_array_test.main,
  'document_blob': document_blob_test.main,
  'document_dictionary': document_dictionary_test.main,
  'document_document': document_document_test.main,
  'fleece_coding': fleece_coding.main,
  'fleece_integration': fleece_integration.main,
  'fleece_slice': fleece_slice.main,
  'fleece_containers': fleece_containers.main,
  'logging': logging.main,
  'native_callback': native_callback.main,
  'replicator': replicator.main,
};

void main() {
  for (final main in tests.values) {
    main();
  }
}
