import 'package:cbl/src/native_libraries.dart';
import 'package:test/test.dart';

void main() {
  test('vectorSearchSupported rejects 32-bit architectures', () {
    expect(vectorSearchSupported(Architecture.arm), isFalse);
    expect(vectorSearchSupported(Architecture.ia32), isFalse);
    expect(vectorSearchSupported(Architecture.arm64), isTrue);
    expect(vectorSearchSupported(Architecture.x64), isTrue);
  });

  test('supportedArchitecturesForAssembly returns full platform defaults', () {
    expect(supportedArchitecturesForAssembly(OS.macOS), {
      Architecture.arm64,
      Architecture.x64,
    });
    expect(supportedArchitecturesForAssembly(OS.iOS), {
      Architecture.arm64,
      Architecture.x64,
    });
    expect(supportedArchitecturesForAssembly(OS.android), {
      Architecture.arm,
      Architecture.arm64,
      Architecture.ia32,
      Architecture.x64,
    });
  });
}
