import 'dart:ffi' as ffi;

import 'utils.dart';

String get vectorSearchExtensionPath =>
    resolveLibraryPathFromAddress(_extensionEntryPointAddress);

@ffi.Native<ffi.Void Function()>(
    symbol: 'sqlite3_couchbaselitevectorsearch_init')
external void _extensionEntryPoint();

ffi.Pointer<ffi.Void> get _extensionEntryPointAddress =>
    ffi.Native.addressOf<ffi.NativeFunction<ffi.Void Function()>>(
            _extensionEntryPoint)
        .cast();
