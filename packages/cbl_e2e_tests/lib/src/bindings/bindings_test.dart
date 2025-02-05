import 'package:cbl/src/bindings.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('CBLBindings', () {
    test('find vector search library', () {
      expect(CBLBindings.instance.vectorSearchLibraryPath, isNotNull);
    });
  });
}
