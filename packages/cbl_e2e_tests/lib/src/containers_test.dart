import 'package:cbl/src/containers/containers.dart';

import 'test_binding.dart';

void main() {
  group('Containers', () {
    test('smoke', () {
      final array = MutableArray([
        'foo',
        42,
        3.14,
        true,
        DateTime.now(),
        ['hey'],
        {'foo': 'bar'},
      ]);

      array[5][0].value = 'Whats up?';
      array[5]['foo'].value = 'Nothing';

      print(array);
    });
  });
}
