import 'src/blob_test.dart' as blob;
import 'src/database_test.dart' as database;
import 'src/fleece_test.dart' as fleece;
import 'src/log_test.dart' as log;
import 'src/native_callback_test.dart' as native_callback;
import 'src/replicator_test.dart' as replicator;
import 'src/worker_test.dart' as worker;

export 'src/test_binding.dart';

final tests = {
  'blob': blob.main,
  'database': database.main,
  'fleece': fleece.main,
  'log': log.main,
  'native_callback': native_callback.main,
  'replicator': replicator.main,
  'worker': worker.main,
};

void cblE2eTests() {
  for (final main in tests.values) {
    main();
  }
}
