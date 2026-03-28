import 'package:args/args.dart';
import 'package:cbl/src/native_libraries.dart';
import 'package:test/test.dart';

void main() {
  group('resolveNativeLibrariesPlan', () {
    test('defaults to the current platform '
        'and all supported architectures', () {
      final plan = resolveNativeLibrariesPlan(
        NativeLibraryRequest(
          editions: {Edition.community},
          vectorSearch: false,
          outputDirectory: 'build/cbl-native-libraries',
        ),
      );

      expect(plan.targets.map((it) => it.target.os).toSet(), {currentHostOS()});
      expect(
        plan.targets.map((it) => it.target.architecture).toSet(),
        supportedArchitecturesForAssembly(currentHostOS()),
      );
    });

    test('allows vector search when both editions are requested', () {
      final parser = ArgParser()
        ..addMultiOption('edition')
        ..addMultiOption('platform')
        ..addMultiOption('architecture')
        ..addFlag('vector-search', negatable: true)
        ..addOption('output', defaultsTo: 'build/cbl-native-libraries');
      final defaults = NativeLibraryDefaults(
        editions: {Edition.community},
        vectorSearch: false,
        baseDirectory: null,
      );

      final request = applyCliOverrides(
        defaults,
        parser.parse([
          '--edition=community',
          '--edition=enterprise',
          '--vector-search',
        ]),
      );

      expect(() => resolveNativeLibrariesPlan(request), returnsNormally);
    });
  });
}
