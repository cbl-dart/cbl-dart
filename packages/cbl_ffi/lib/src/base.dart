import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'fleece.dart';
import 'global.dart';

late final _baseBinds = CBLBindings.instance.base;

// === Option ==================================================================

class Option {
  const Option(int bit) : bitMask = 1 << bit;

  final int bitMask;
}

extension OptionIterable<T extends Option> on Iterable<T> {
  int toCFlags() {
    var result = 0;
    for (final option in this) {
      result |= option.bitMask;
    }
    return result;
  }

  Set<T> parseCFlags(int flags) =>
      where((option) => (flags & option.bitMask) == option.bitMask).toSet();
}

// === Init ====================================================================

class CBLInitContext {
  CBLInitContext({required this.filesDir, required this.tempDir});

  final String filesDir;
  final String tempDir;
}

class _CBLInitContext extends Struct {
  external Pointer<Utf8> filesDir;
  external Pointer<Utf8> tempDir;
}

typedef _CBLDart_Initialize_C = Bool Function(
  Pointer<Void> dartInitializeDlData,
  Pointer<Void> cblInitContext,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_Initialize = bool Function(
  Pointer<Void> dartInitializeDlData,
  Pointer<Void> cblInitContext,
  Pointer<CBLError> errorOut,
);

// === CBLError ================================================================

enum CBLErrorDomain {
  couchbaseLite,
  posix,
  sqLite,
  fleece,
  network,
  webSocket,
}

extension IntCBLErrorDomainExt on int {
  CBLErrorDomain toErrorDomain() {
    assert(this >= 1 || this <= 6);
    return CBLErrorDomain.values[this - 1];
  }
}

enum CBLErrorCode {
  assertionFailed,
  unimplemented,
  unsupportedEncryption,
  badRevisionId,
  corruptRevisionData,
  notOpen,
  notFound,
  conflict,
  invalidParameter,
  unexpectedError,
  cantOpenFile,
  iOError,
  memoryError,
  notWriteable,
  corruptData,
  busy,
  notInTransaction,
  transactionNotClosed,
  unsupported,
  notADatabaseFile,
  wrongFormat,
  crypto,
  invalidQuery,
  missingIndex,
  invalidQueryParam,
  remoteError,
  databaseTooOld,
  databaseTooNew,
  badDocId,
  cantUpgradeDatabase,
}

extension on int {
  CBLErrorCode toCouchbaseLiteErrorCode() {
    assert(this >= 1 || this <= 30);
    return CBLErrorCode.values[this - 1];
  }
}

enum CBLNetworkErrorCode {
  dnsFailure,
  unknownHost,
  timeout,
  invalidURL,
  tooManyRedirects,
  tlsHandshakeFailed,
  tlsCertExpired,
  tlsCertUntrusted,
  tlsClientCertRequired,
  tlsClientCertRejected,
  tlsCertUnknownRoot,
  invalidRedirect,
  unknown,
  tlsCertRevoked,
  tlsCertNameMismatch,
}

extension on int {
  CBLNetworkErrorCode toNetworkErrorCode() {
    assert(this >= 1 || this <= 15);
    return CBLNetworkErrorCode.values[this - 1];
  }
}

extension IntErrorCodeExt on int {
  Object toErrorCode(CBLErrorDomain domain) {
    switch (domain) {
      case CBLErrorDomain.couchbaseLite:
        return toCouchbaseLiteErrorCode();
      case CBLErrorDomain.posix:
        return this;
      case CBLErrorDomain.sqLite:
        return this;
      case CBLErrorDomain.fleece:
        return toFleeceErrorCode();
      case CBLErrorDomain.network:
        return toNetworkErrorCode();
      case CBLErrorDomain.webSocket:
        return this;
    }
  }
}

class CBLError extends Struct {
  @Uint8()
  external int _domain;

  @Int32()
  external int _code;

  @Uint32()
  // ignore: unused_field, non_constant_identifier_names
  external int _internal_info;
}

typedef _CBLError_Message = FLStringResult Function(
  Pointer<CBLError> error,
);

extension CBLErrorExt on CBLError {
  CBLErrorDomain get domain => _domain.toErrorDomain();

  Object get code => _code.toErrorCode(domain);

  /// `true` if there is no error stored in this [CBLError].
  bool get isOk => _code == 0;

  void copyToGlobal() {
    globalCBLError.ref._domain = _domain;
    globalCBLError.ref._code = _code;
    globalCBLError.ref._internal_info = _internal_info;
  }
}

class CBLErrorException implements Exception {
  CBLErrorException(
    this.domain,
    this.code,
    this.message, {
    this.errorPosition,
    this.errorSource,
  });

  CBLErrorException.fromCBLError(Pointer<CBLError> error)
      : this(
          error.ref.domain,
          error.ref.code,
          _baseBinds.getErrorMessage(globalCBLError)!,
        );

  CBLErrorException.fromCBLErrorWithSource(
    Pointer<CBLError> error, {
    required String errorSource,
    required int errorPosition,
  }) : this(
          error.ref.domain,
          error.ref.code,
          _baseBinds.getErrorMessage(globalCBLError)!,
          errorSource: errorSource,
          errorPosition: errorPosition == -1 ? null : errorPosition,
        );

  final String message;
  final CBLErrorDomain domain;
  final Object? code;
  final String? errorSource;
  final int? errorPosition;
}

void checkCBLError({String? errorSource}) {
  if (!globalCBLError.ref.isOk) {
    throwCBLError(errorSource: errorSource);
  }
}

Never throwCBLError({String? errorSource}) {
  if (errorSource == null) {
    throw CBLErrorException.fromCBLError(globalCBLError);
  } else {
    throw CBLErrorException.fromCBLErrorWithSource(
      globalCBLError,
      errorSource: errorSource,
      errorPosition: globalErrorPosition.value,
    );
  }
}

const _checkCBLError = checkCBLError;

extension CheckCBLErrorPointerExt<T extends Pointer> on T {
  T checkCBLError({String? errorSource}) {
    if (this == nullptr) {
      _checkCBLError(errorSource: errorSource);
    }
    return this;
  }
}

extension CheckCBLErrorFLSliceResultExt on FLSliceResult {
  FLSliceResult checkCBLError({String? errorSource}) {
    if (buf == nullptr) {
      _checkCBLError(errorSource: errorSource);
    }
    return this;
  }
}

extension CheckCBLErrorIntExt on int {
  int checkCBLError({String? errorSource}) {
    assert(this == 0 || this == 1);
    if (this == 0) {
      _checkCBLError(errorSource: errorSource);
    }
    return this;
  }
}

extension CheckCBLErrorBoolExt on bool {
  bool checkCBLError({String? errorSource}) {
    if (!this) {
      _checkCBLError(errorSource: errorSource);
    }
    return this;
  }
}

// === CBLRefCounted ===========================================================

class CBLRefCounted extends Opaque {}

typedef _CBLDart_BindCBLRefCountedToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLRefCounted> refCounted,
  Bool retain,
  Pointer<Utf8> debugName,
);
typedef _CBLDart_BindCBLRefCountedToDartObject = void Function(
  Object object,
  Pointer<CBLRefCounted> refCounted,
  bool retain,
  Pointer<Utf8> debugName,
);

typedef _CBLDart_SetDebugRefCounted_C = Void Function(Bool enabled);
typedef _CBLDart_SetDebugRefCounted = void Function(bool enabled);

typedef _CBL_Retain = Pointer<CBLRefCounted> Function(
  Pointer<CBLRefCounted> refCounted,
);

typedef _CBL_Release = Pointer<CBLRefCounted> Function(
  Pointer<CBLRefCounted> refCounted,
);

// === CBLListener =============================================================

class CBLListenerToken extends Opaque {}

typedef _CBLListener_Remove_C = Void Function(
  Pointer<CBLListenerToken> listenerToken,
);
typedef _CBLListener_Remove = void Function(
  Pointer<CBLListenerToken> listenerToken,
);

// === BaseBindings ============================================================

class BaseBindings extends Bindings {
  BaseBindings(Bindings parent) : super(parent) {
    _initialize =
        libs.cblDart.lookupFunction<_CBLDart_Initialize_C, _CBLDart_Initialize>(
      'CBLDart_Initialize',
      isLeaf: useIsLeaf,
    );

    _bindCBLRefCountedToDartObject = libs.cblDart.lookupFunction<
        _CBLDart_BindCBLRefCountedToDartObject_C,
        _CBLDart_BindCBLRefCountedToDartObject>(
      'CBLDart_BindCBLRefCountedToDartObject',
    );
    _setDebugRefCounted = libs.cblDart.lookupFunction<
        _CBLDart_SetDebugRefCounted_C, _CBLDart_SetDebugRefCounted>(
      'CBLDart_SetDebugRefCounted',
      isLeaf: useIsLeaf,
    );
    _retainRefCounted = libs.cbl.lookupFunction<_CBL_Retain, _CBL_Retain>(
      'CBL_Retain',
      isLeaf: useIsLeaf,
    );
    _releaseRefCounted = libs.cbl.lookupFunction<_CBL_Release, _CBL_Release>(
      'CBL_Release',
      isLeaf: useIsLeaf,
    );
    _getErrorMessage =
        libs.cbl.lookupFunction<_CBLError_Message, _CBLError_Message>(
      'CBLError_Message',
      isLeaf: useIsLeaf,
    );
    _removeListener =
        libs.cbl.lookupFunction<_CBLListener_Remove_C, _CBLListener_Remove>(
      'CBLListener_Remove',
      isLeaf: useIsLeaf,
    );
  }

  late final _CBLDart_Initialize _initialize;
  late final _CBLDart_BindCBLRefCountedToDartObject
      _bindCBLRefCountedToDartObject;
  late final _CBLDart_SetDebugRefCounted _setDebugRefCounted;
  late final _CBL_Retain _retainRefCounted;
  late final _CBL_Release _releaseRefCounted;
  late final _CBLError_Message _getErrorMessage;
  late final _CBLListener_Remove _removeListener;

  void initializeNativeLibraries([CBLInitContext? context]) {
    assert(!io.Platform.isAndroid || context != null);

    withZoneArena(() {
      Pointer<_CBLInitContext> _context = nullptr;

      if (context != null) {
        _context = zoneArena<_CBLInitContext>()
          ..ref.filesDir = context.filesDir.toNativeUtf8(allocator: zoneArena)
          ..ref.tempDir = context.tempDir.toNativeUtf8(allocator: zoneArena);
      }

      // The `globalCBLError` cannot be used at this point because it requires
      // initialization to be completed.
      final error = zoneArena<CBLError>();

      if (!_initialize(NativeApi.initializeApiDLData, _context.cast(), error)) {
        throw CBLErrorException.fromCBLError(error);
      }
    });
  }

  void bindCBLRefCountedToDartObject(
    Object handle, {
    required Pointer<CBLRefCounted> refCounted,
    required bool retain,
    String? debugName,
  }) {
    final debugNameCStr = debugName?.toNativeUtf8() ?? nullptr;

    _bindCBLRefCountedToDartObject(handle, refCounted, retain, debugNameCStr);

    if (debugNameCStr != nullptr) {
      malloc.free(debugNameCStr);
    }
  }

  // coverage:ignore-start

  // ignore: avoid_setters_without_getters
  set debugRefCounted(bool enabled) => _setDebugRefCounted(enabled);

  void retainRefCounted(Pointer<CBLRefCounted> refCounted) {
    _retainRefCounted(refCounted);
  }

  void releaseRefCounted(Pointer<CBLRefCounted> refCounted) {
    _releaseRefCounted(refCounted);
  }

  // coverage:ignore-end

  String? getErrorMessage(Pointer<CBLError> error) =>
      _getErrorMessage(error).toDartStringAndRelease();

  void removeListener(Pointer<CBLListenerToken> token) {
    _removeListener(token);
  }
}
