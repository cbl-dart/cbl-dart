// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../errors.dart';

/// Resolves the file path of a loaded native library from the address of one of
/// its symbols.
///
/// Uses `dladdr` on POSIX platforms and `GetModuleHandleExA` +
/// `GetModuleFileNameA` on Windows.
///
/// Throws a [DatabaseException] if the containing library path cannot be
/// resolved.
String resolveLibraryPathFromAddress(Pointer<Void> address) {
  if (Platform.isAndroid ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isIOS) {
    final info = calloc<_Dl_info>();
    try {
      if (_dladdr(address, info) == 0) {
        throw DatabaseException(
          'dladdr could not find the image containing address $address.',
          DatabaseErrorCode.notFound,
        );
      }

      final libraryPath = info.ref.dli_fname;
      if (libraryPath == nullptr) {
        throw DatabaseException(
          'dladdr resolved address $address but returned a null library path.',
          DatabaseErrorCode.unexpectedError,
        );
      }

      return libraryPath.toDartString();
    } on CouchbaseLiteException {
      rethrow;
    } on Object catch (error) {
      throw DatabaseException(
        'Unexpected POSIX error while resolving address $address: $error',
        DatabaseErrorCode.unexpectedError,
      );
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
        final errorCode = _GetLastError();
        throw DatabaseException(
          'GetModuleHandleExA could not resolve the module containing address '
          '$address${_win32ErrorSuffix(errorCode)}',
          DatabaseErrorCode.notFound,
        );
      }

      const maxPath = 32768;
      final path = calloc<Uint8>(maxPath);
      try {
        final pathLength = _GetModuleFileNameA(
          hModule.value,
          path.cast(),
          maxPath,
        );
        if (pathLength == 0) {
          final errorCode = _GetLastError();
          throw DatabaseException(
            'GetModuleFileNameA failed to resolve the module path for '
            'address $address${_win32ErrorSuffix(errorCode)}',
            DatabaseErrorCode.iOError,
          );
        }
        if (pathLength >= maxPath - 1 && path[maxPath - 1] != 0) {
          throw DatabaseException(
            'GetModuleFileNameA returned a truncated module path for '
            'address $address.',
            DatabaseErrorCode.memoryError,
          );
        }

        return path.cast<Utf8>().toDartString();
      } on CouchbaseLiteException {
        rethrow;
      } on Object catch (error) {
        throw DatabaseException(
          'Unexpected Windows error while resolving address $address: $error',
          DatabaseErrorCode.unexpectedError,
        );
      } finally {
        calloc.free(path);
      }
    } finally {
      calloc.free(hModule);
    }
  }

  throw DatabaseException(
    'Resolving a library path from an address is not supported on this '
    'platform.',
    DatabaseErrorCode.unsupported,
  );
}

String _win32ErrorSuffix(int errorCode) {
  if (errorCode == 0) {
    return '.';
  }

  return ' (Win32 error $errorCode).';
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

final _GetLastError = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetLastError');
