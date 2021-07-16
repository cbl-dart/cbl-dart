import 'src/blob_test.dart' as blob;
import 'src/database_test.dart' as database;
import 'src/document/array_test.dart' as document_array_test;
import 'src/document/blob_test.dart' as document_blob_test;
import 'src/document/dictionary_test.dart' as document_dictionary_test;
import 'src/document/document_test.dart' as document_document_test;
import 'src/fleece/coding_test.dart' as fleece_coding;
import 'src/fleece/containers_test.dart' as fleece;
import 'src/fleece/integration_test.dart' as fleece_integration;
import 'src/fleece/slice_test.dart' as fleece_slice;
import 'src/logging_test.dart' as logging;
import 'src/native_callback_test.dart' as native_callback;
import 'src/replicator_test.dart' as replicator;

export 'src/test_binding.dart';

final tests = {
  'blob': blob.main,
  'database': database.main,
  'document_array': document_array_test.main,
  'document_blob': document_blob_test.main,
  'document_dictionary': document_dictionary_test.main,
  'document_document': document_document_test.main,
  'fleece_coding': fleece_coding.main,
  'fleece_integration': fleece_integration.main,
  'fleece_slice': fleece_slice.main,
  'fleece': fleece.main,
  'logging': logging.main,
  'native_callback': native_callback.main,
  'replicator': replicator.main,
};

void cblE2eTests() {
  for (final main in tests.values) {
    main();
  }
}
