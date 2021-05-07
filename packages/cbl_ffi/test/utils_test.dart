import 'package:cbl_ffi/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('runArena', () {
    test('should run finalizers when sync body executes normally', () {
      runArena(() {
        registerFinalzier(expectAsync0(() {}));
      });
    });

    test('should run finalizers when sync body throws', () {
      expect(
        () => runArena(() {
          registerFinalzier(expectAsync0(() {}));
          throw Exception('body throws');
        }),
        throwsException,
      );
    });

    test('should run finalizers when async body executes normally', () {
      return runArena(() async {
        registerFinalzier(expectAsync0(() {}));
      });
    });

    test('should run finalizers when async body throws', () {
      expect(
        () => runArena(() async {
          registerFinalzier(expectAsync0(() {}));
          throw Exception('body throws');
        }),
        throwsException,
      );
    });
  });
}
