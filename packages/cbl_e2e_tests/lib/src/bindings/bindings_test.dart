import 'package:cbl/src/bindings/cblite_vector_search.dart' as vector_search;

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('CBLBindings', () {
    test('find vector search library', () {
      expect(vector_search.vectorSearchLibraryPath, isNotNull);
    });
  });
}
