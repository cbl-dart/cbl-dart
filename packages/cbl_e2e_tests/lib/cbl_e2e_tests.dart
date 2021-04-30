import 'src/blob_test.dart' as blob;
import 'src/containers_test.dart' as containers;
import 'src/database_test.dart' as database;
import 'src/fleece_test.dart' as fleece;
import 'src/logging_test.dart' as logging;
import 'src/native_callback_test.dart' as native_callback;
import 'src/replicator_test.dart' as replicator;

export 'src/test_binding.dart';

final tests = {
  'blob': blob.main,
  'containers': containers.main,
  'database': database.main,
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
