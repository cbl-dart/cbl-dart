import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'fleece.dart';
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

// === Dart ====================================================================

typedef CBLDart_InitDartApiDL_C = Void Function(
  Pointer<Void> data,
);
typedef CBLDart_InitDartApiDL = void Function(
  Pointer<Void> data,
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

extension on int {
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

late final globalCBLError = _baseBinds._globalCBLError;
late final globalErrorPosition = _baseBinds._globalErrorPosition;

class CBLError extends Struct {
  @Uint8()
  external int _domain;

  @Int32()
  external int _code;

  @Uint32()
  // ignore: unused_field
  external int _internal_info;
}

typedef CBLDart_CBLError_Message = FLStringResult Function(
  Pointer<CBLError> error,
);

extension CBLErrorExt on CBLError {
  CBLErrorDomain get domain => _domain.toErrorDomain();

  Object get code {
    switch (domain) {
      case CBLErrorDomain.couchbaseLite:
        return _code.toCouchbaseLiteErrorCode();
      case CBLErrorDomain.posix:
        return _code;
      case CBLErrorDomain.sqLite:
        return _code;
      case CBLErrorDomain.fleece:
        return _code.toFleeceErrorCode();
      case CBLErrorDomain.network:
        return _code.toNetworkErrorCode();
      case CBLErrorDomain.webSocket:
        return _code;
      default:
        throw UnimplementedError();
    }
  }

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

  CBLErrorException.fromCBLError(
    Pointer<CBLError> error, {
    String? errorSource,
    int? errorPosition,
  }) : this(
          error.ref.domain,
          error.ref.code,
          _baseBinds.CBLErrorMessage(globalCBLError)!,
          errorSource: errorSource,
          errorPosition:
              error.ref.code == CBLErrorCode.invalidQuery && errorPosition != -1
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
      'errorPosition: $errorPosition'
      ')';
}

void checkCBLError({String? errorSource}) {
  if (!globalCBLError.ref.isOk) {
    throw CBLErrorException.fromCBLError(
      globalCBLError,
      errorSource: errorSource,
      errorPosition: globalErrorPosition.value,
    );
  }
}

final _checkCBLError = checkCBLError;

extension CheckCBLErrorPointerExt<T extends Pointer> on T {
  T checkCBLError({String? errorSource}) {
    if (this == nullptr) {
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

typedef CBLDart_BindCBLRefCountedToDartObject_C = Void Function(
  Handle object,
  Pointer<CBLRefCounted> refCounted,
  Uint8 retain,
  Pointer<Utf8> debugName,
);
typedef CBLDart_BindCBLRefCountedToDartObject = void Function(
  Object object,
  Pointer<CBLRefCounted> refCounted,
  int retain,
  Pointer<Utf8> debugName,
);

typedef CBLDart_SetDebugRefCounted_C = Void Function(Uint8 enabled);
typedef CBLDart_SetDebugRefCounted = void Function(int enabled);

typedef CBL_Retain = Pointer<CBLRefCounted> Function(
  Pointer<CBLRefCounted> refCounted,
);

// === CBLListener =============================================================

class CBLListenerToken extends Opaque {}

typedef CBLListener_Remove_C = Void Function(
  Pointer<CBLListenerToken> listenerToken,
);
typedef CBLListener_Remove = void Function(
  Pointer<CBLListenerToken> listenerToken,
);

// === BaseBindings ============================================================

class BaseBindings extends Bindings {
  BaseBindings(Bindings parent) : super(parent) {
    _initDartApiDL = libs.cblDart
        .lookupFunction<CBLDart_InitDartApiDL_C, CBLDart_InitDartApiDL>(
      'CBLDart_InitDartApiDL',
    );
    _bindCBLRefCountedToDartObject = libs.cblDart.lookupFunction<
        CBLDart_BindCBLRefCountedToDartObject_C,
        CBLDart_BindCBLRefCountedToDartObject>(
      'CBLDart_BindCBLRefCountedToDartObject',
    );
    _setDebugRefCounted = libs.cblDart.lookupFunction<
        CBLDart_SetDebugRefCounted_C, CBLDart_SetDebugRefCounted>(
      'CBLDart_SetDebugRefCounted',
    );
    _retainRefCounted = libs.cblDart.lookupFunction<CBL_Retain, CBL_Retain>(
      'CBL_Retain',
    );
    _Error_Message = libs.cblDart
        .lookupFunction<CBLDart_CBLError_Message, CBLDart_CBLError_Message>(
      'CBLDart_CBLError_Message',
    );
    _Listener_Remove =
        libs.cbl.lookupFunction<CBLListener_Remove_C, CBLListener_Remove>(
      'CBLListener_Remove',
    );
  }

  late final Pointer<CBLError> _globalCBLError = malloc();
  late final Pointer<Int32> _globalErrorPosition = malloc();

  late final CBLDart_InitDartApiDL _initDartApiDL;
  late final CBLDart_BindCBLRefCountedToDartObject
      _bindCBLRefCountedToDartObject;
  late final CBLDart_SetDebugRefCounted _setDebugRefCounted;
  late final CBL_Retain _retainRefCounted;
  late final CBLDart_CBLError_Message _Error_Message;
  late final CBLListener_Remove _Listener_Remove;

  void initDartApiDL() {
    _initDartApiDL(NativeApi.initializeApiDLData);
  }

  void bindCBLRefCountedToDartObject(
    Object handle,
    Pointer<CBLRefCounted> refCounted,
    bool retain,
    String? debugName,
  ) {
    _bindCBLRefCountedToDartObject(
      handle,
      refCounted,
      retain.toInt(),
      debugName?.toNativeUtf8() ?? nullptr,
    );
  }

  set debugRefCounted(bool enabled) => _setDebugRefCounted(enabled.toInt());

  void retainRefCounted(Pointer<CBLRefCounted> refCounted) {
    _retainRefCounted(refCounted);
  }

  String? CBLErrorMessage(Pointer<CBLError> error) =>
      _Error_Message(error).toDartStringAndRelease();

  void removeListener(Pointer<CBLListenerToken> token) {
    _Listener_Remove(token);
  }

  @override
  void dispose() {
    malloc.free(_globalCBLError);
    malloc.free(_globalErrorPosition);
    super.dispose();
  }
}
