import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'libraries.dart';

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

enum ErrorDomain {
  couchbaseLite,
  posix,
  sqLite,
  fleece,
  network,
  webSocket,
}

ErrorDomain errorDomainFromCInt(int domain) {
  assert(domain >= 1 || domain <= 6);
  return ErrorDomain.values[domain - 1];
}

enum CouchbaseLiteErrorCode {
  assertionFailed,
  unimplemented,
  unsupportedEncryption,
  badRevisionID,
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
  badDocID,
  cantUpgradeDatabase,
}

CouchbaseLiteErrorCode couchbaseLiteErrorCodeFromCInt(int domain) {
  assert(domain >= 1 || domain <= 30);
  return CouchbaseLiteErrorCode.values[domain - 1];
}

enum NetworkErrorCode {
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

NetworkErrorCode networkErrorCodeFromCInt(int domain) {
  assert(domain >= 1 || domain <= 15);
  return NetworkErrorCode.values[domain - 1];
}

class CBLError extends Struct {
  @Uint32()
  external int domain;

  @Int32()
  external int code;

  @Int32()
  external int internal_info;
}

extension CBLErrorCopyToPointerExt on CBLError {
  Pointer<CBLError> copyToPointer() {
    final result = malloc<CBLError>();
    result.ref.domain = domain;
    result.ref.code = code;
    result.ref.internal_info = internal_info;
    return result;
  }
}

typedef CBLError_Message = Pointer<Utf8> Function(
  Pointer<CBLError> error,
);

extension CBLErrorPointerExt on Pointer<CBLError> {
  /// Whether [CBLError.code] == 0.
  bool get isOk => ref.code == 0;
}

// === CBLRefCounted ===========================================================

typedef CBLDart_BindCBLRefCountedToDartObject_C = Void Function(
  Handle handle,
  Pointer<Void> refCounted,
  Uint8 retain,
);
typedef CBLDart_BindCBLRefCountedToDartObject = void Function(
  Object handle,
  Pointer<Void> refCounted,
  int retain,
);

// === CBLListener =============================================================

typedef CBLListener_Remove_C = Void Function(Pointer<Void> listenerToken);
typedef CBLListener_Remove = void Function(Pointer<Void> listenerToken);

// === BaseBindings ============================================================

class BaseBindings {
  BaseBindings(Libraries libs)
      : initDartApiDL = libs.cblDart
            .lookupFunction<CBLDart_InitDartApiDL_C, CBLDart_InitDartApiDL>(
          'CBLDart_InitDartApiDL',
        ),
        bindCBLRefCountedToDartObject = libs.cblDart.lookupFunction<
            CBLDart_BindCBLRefCountedToDartObject_C,
            CBLDart_BindCBLRefCountedToDartObject>(
          'CBLDart_BindCBLRefCountedToDartObject',
        ),
        Error_Message =
            libs.cbl.lookupFunction<CBLError_Message, CBLError_Message>(
          'CBLError_Message',
        ),
        Listener_Remove =
            libs.cbl.lookupFunction<CBLListener_Remove_C, CBLListener_Remove>(
          'CBLListener_Remove',
        );

  final CBLDart_InitDartApiDL initDartApiDL;
  final CBLDart_BindCBLRefCountedToDartObject bindCBLRefCountedToDartObject;
  final CBLError_Message Error_Message;
  final CBLListener_Remove Listener_Remove;
}
