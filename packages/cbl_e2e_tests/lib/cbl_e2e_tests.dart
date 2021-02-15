import 'src/blob_test.dart' as blob;
import 'src/database_test.dart' as database;
import 'src/fleece_test.dart' as fleece;
import 'src/log_test.dart' as log;
import 'src/native_callback_test.dart' as native_callback;
import 'src/replicator_test.dart' as replicator;
import 'src/test_bindings.dart';
import 'src/worker_test.dart' as worker;

export 'src/test_bindings.dart';

void cblE2eTests(CblE2eTestBindings binding) {
  CblE2eTestBindings.register(binding);

  blob.main();
  database.main();
  fleece.main();
  log.main();
  native_callback.main();
  replicator.main();
  worker.main();
}
