// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Resolves the file path of a loaded native library from the address of one of
/// its symbols.
///
/// Uses `dladdr` on POSIX platforms and `GetModuleHandleEx` +
/// `GetModuleFileName` on Windows.
///
/// Returns `null` if the path cannot be resolved. Logs errors via [print] since
/// Couchbase Lite logging may not be initialized at this point.
String? resolveLibraryPathFromAddress(Pointer<Void> address) {
  if (Platform.isAndroid ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isIOS) {
    final info = calloc<_Dl_info>();
    try {
      if (_dladdr(address, info) == 0) {
        _logResolveLibraryPathWarning(
          'dladdr failed to resolve address $address.',
        );
        return null;
      }

      final libraryPath = info.ref.dli_fname;
      if (libraryPath == nullptr) {
        _logResolveLibraryPathWarning(
          'dladdr returned a null library path for address $address.',
        );
        return null;
      }

      return libraryPath.toDartString();
    } on Object catch (error) {
      _logResolveLibraryPathWarning(
        'Unexpected POSIX error while resolving address $address: $error',
      );
      return null;
    } finally {
      calloc.free(info);
    }
  }

  if (Platform.isWindows) {
    final hModule = calloc<Pointer<Void>>();
    try {
      if (_GetModuleHandleExA(
            _GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                _GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            address.cast(),
            hModule,
          ) ==
          0) {
        _logResolveLibraryPathWarning(
          'GetModuleHandleExA failed to resolve address $address.',
        );
        return null;
      }

      const maxPath = 4096;
      final path = calloc<Uint8>(maxPath);
      try {
        if (_GetModuleFileNameA(hModule.value, path.cast(), maxPath) == 0) {
          _logResolveLibraryPathWarning(
            'GetModuleFileNameA failed to resolve the module path for '
            'address $address.',
          );
          return null;
        }

        return path.cast<Utf8>().toDartString();
      } on Object catch (error) {
        _logResolveLibraryPathWarning(
          'Unexpected Windows error while resolving address $address: $error',
        );
        return null;
      } finally {
        calloc.free(path);
      }
    } finally {
      calloc.free(hModule);
    }
  }

  _logResolveLibraryPathWarning(
    'resolveLibraryPathFromAddress is not supported on this platform.',
  );
  return null;
}

void _logResolveLibraryPathWarning(String message) {
  // ignore: avoid_print
  print('[cbl] Warning: $message');
}

// === POSIX Dynamic Linking ===================================================

final _process = DynamicLibrary.process();

// ignore: camel_case_types
final class _Dl_info extends Struct {
  external Pointer<Utf8> dli_fname;
  external Pointer<Utf8> dli_fbase;
  external Pointer<Utf8> dli_sname;
  external Pointer<Utf8> dli_saddr;
}

final _dladdr = _process
    .lookupFunction<
      Int Function(Pointer<Void>, Pointer<_Dl_info>),
      int Function(Pointer<Void>, Pointer<_Dl_info>)
    >('dladdr');

// === Windows Dynamic Linking =================================================

final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _GetModuleHandleExA = _kernel32
    .lookupFunction<
      Int Function(Uint32, Pointer<Utf8>, Pointer<Pointer<Void>>),
      int Function(int, Pointer<Utf8>, Pointer<Pointer<Void>>)
    >('GetModuleHandleExA');

const _GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = 0x00000004;
const _GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = 0x00000002;

final _GetModuleFileNameA = _kernel32
    .lookupFunction<
      UnsignedLong Function(Pointer<Void>, Pointer<Utf8>, Uint32),
      int Function(Pointer<Void>, Pointer<Utf8>, int)
    >('GetModuleFileNameA');
