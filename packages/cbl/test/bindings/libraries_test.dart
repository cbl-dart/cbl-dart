import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings/libraries.dart';
import 'package:test/test.dart';

void main() {
  group('resolveLibraryPathFromAddress', () {
    test('returns the containing library path for a known symbol', () {
      final libraryPath = resolveLibraryPathFromAddress(_knownSymbolAddress());

      expect(libraryPath, isNotEmpty);
    });

    test('throws a notFound database exception for an unknown address', () {
      final messageFragment = Platform.isWindows
          ? 'GetModuleHandleExA'
          : 'dladdr';

      expect(
        () => resolveLibraryPathFromAddress(ffi.Pointer.fromAddress(1)),
        throwsA(
          isA<DatabaseException>()
              .having((e) => e.code, 'code', DatabaseErrorCode.notFound)
              .having((e) => e.message, 'message', contains(messageFragment)),
        ),
      );
    });
  });
}

ffi.Pointer<ffi.Void> _knownSymbolAddress() {
  if (Platform.isWindows) {
    final kernel32 = ffi.DynamicLibrary.open('kernel32.dll');
    return kernel32
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('GetModuleFileNameA')
        .cast();
  }

  return ffi.DynamicLibrary.process()
      .lookup<ffi.NativeFunction<ffi.Void Function()>>('dladdr')
      .cast();
}
