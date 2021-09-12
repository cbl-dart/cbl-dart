import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

late final _baseBinds = CBLBindings.instance.base;

// === Option ==================================================================

class Option {
  const Option(this.debugName, this.bits);

  final String debugName;

  final int bits;

  @override
  String toString() => debugName;
}

extension OptionIterable<T extends Option> on Iterable<T> {
  int toCFlags() {
    var result = 0;
    for (final option in this) {
      result |= option.bits;
    }
    return result;
  }

  Set<T> parseCFlags(int flags) =>
      where((option) => (flags & option.bits) == option.bits).toSet();
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

typedef _CBLDart_Initialize_C = Uint8 Function(
  Pointer<Void> dartInitializeDlData,
  Pointer<_CBLInitContext> cblInitContext,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_Initialize = int Function(
  Pointer<Void> dartInitializeDlData,
  Pointer<_CBLInitContext> cblInitContext,
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

typedef _CBLDart_CBLError_Message = FLStringResult Function(
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
          errorPosition:
              // This test should only need to check whether `errorPosition`
              // is `-1`. A regrission in the CBL C SDK leaves `errorPosition`
              // sometimes uninitialized.
              error.ref.code == CBLErrorCode.invalidQuery &&
                      errorPosition >= 0 &&
                      errorPosition < errorSource.length
                  ? errorPosition
                  : null,
        );

  final String message;
  final CBLErrorDomain domain;
  final Object? code;
  final String? errorSource;
  final int? errorPosition;

  @override
  String toString() => 'CBLErrorException('
      'domain: $domain, '
      'code: $code, '
      'message: $message, '
      'errorSource: $errorSource, '
      // ignore: missing_whitespace_between_adjacent_strings
      'errorPosition: $errorPosition'
      ')';
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

// === CBLRefCounted ===========================================================

class CBLRefCounted extends Opaque {}

typedef _CBLDart_BindCBLRefCountedToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLRefCounted> refCounted,
  Uint8 retain,
  Pointer<Utf8> debugName,
);
typedef _CBLDart_BindCBLRefCountedToDartObject = void Function(
  Object object,
  Pointer<CBLRefCounted> refCounted,
  int retain,
  Pointer<Utf8> debugName,
);

typedef _CBLDart_SetDebugRefCounted_C = Void Function(Uint8 enabled);
typedef _CBLDart_SetDebugRefCounted = void Function(int enabled);

typedef _CBL_Retain = Pointer<CBLRefCounted> Function(
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
    );

    _bindCBLRefCountedToDartObject = libs.cblDart.lookupFunction<
        _CBLDart_BindCBLRefCountedToDartObject_C,
        _CBLDart_BindCBLRefCountedToDartObject>(
      'CBLDart_BindCBLRefCountedToDartObject',
    );
    _setDebugRefCounted = libs.cblDart.lookupFunction<
        _CBLDart_SetDebugRefCounted_C, _CBLDart_SetDebugRefCounted>(
      'CBLDart_SetDebugRefCounted',
    );
    _retainRefCounted = libs.cblDart.lookupFunction<_CBL_Retain, _CBL_Retain>(
      'CBL_Retain',
    );
    _getErrorMessage = libs.cblDart
        .lookupFunction<_CBLDart_CBLError_Message, _CBLDart_CBLError_Message>(
      'CBLDart_CBLError_Message',
    );
    _removeListener =
        libs.cbl.lookupFunction<_CBLListener_Remove_C, _CBLListener_Remove>(
      'CBLListener_Remove',
    );
  }

  late final _CBLDart_Initialize _initialize;
  late final _CBLDart_BindCBLRefCountedToDartObject
      _bindCBLRefCountedToDartObject;
  late final _CBLDart_SetDebugRefCounted _setDebugRefCounted;
  late final _CBL_Retain _retainRefCounted;
  late final _CBLDart_CBLError_Message _getErrorMessage;
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

      _initialize(
        NativeApi.initializeApiDLData,
        _context,
        globalCBLError,
      ).checkCBLError();
    });
  }

  void bindCBLRefCountedToDartObject(
    Object handle, {
    required Pointer<CBLRefCounted> refCounted,
    required bool retain,
    String? debugName,
  }) {
    _bindCBLRefCountedToDartObject(
      handle,
      refCounted,
      retain.toInt(),
      debugName?.toNativeUtf8() ?? nullptr,
    );
  }

  // ignore: avoid_setters_without_getters
  set debugRefCounted(bool enabled) => _setDebugRefCounted(enabled.toInt());

  void retainRefCounted(Pointer<CBLRefCounted> refCounted) {
    _retainRefCounted(refCounted);
  }

  String? getErrorMessage(Pointer<CBLError> error) =>
      _getErrorMessage(error).toDartStringAndRelease();

  void removeListener(Pointer<CBLListenerToken> token) {
    _removeListener(token);
  }
}
