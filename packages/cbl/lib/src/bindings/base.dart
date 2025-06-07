import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../errors.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'fleece.dart';
import 'global.dart';
import 'utils.dart';

export 'cblite.dart' show CBLListenerToken;
export 'cblitedart.dart' show CBLDart_Completer;

final _baseBinds = CBLBindings.instance.base;

// === Option ==================================================================

abstract interface class Option {
  int get bit;
}

extension OptionExt on Option {
  int get bitMask => 1 << bit;
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

enum CBLDartInitializeResult {
  success(
    cblitedart_lib
        .CBLDartInitializeResult
        .CBLDartInitializeResult_kCBLInitError,
  ),
  incompatibleDartVM(
    cblitedart_lib
        .CBLDartInitializeResult
        .CBLDartInitializeResult_kIncompatibleDartVM,
  ),
  cblInitError(
    cblitedart_lib
        .CBLDartInitializeResult
        .CBLDartInitializeResult_kCBLInitError,
  );

  const CBLDartInitializeResult(this.value);

  static CBLDartInitializeResult fromValue(int value) => switch (value) {
    cblitedart_lib.CBLDartInitializeResult.CBLDartInitializeResult_kSuccess =>
      success,
    cblitedart_lib
        .CBLDartInitializeResult
        .CBLDartInitializeResult_kIncompatibleDartVM =>
      incompatibleDartVM,
    cblitedart_lib
        .CBLDartInitializeResult
        .CBLDartInitializeResult_kCBLInitError =>
      cblInitError,
    _ => throw ArgumentError(
      'Unknown value for CBLDartInitializeResult: $value',
    ),
  };

  final int value;
}

final class CBLInitContext {
  CBLInitContext({required this.filesDir, required this.tempDir});

  final String filesDir;
  final String tempDir;
}

final class _CBLInitContext extends Struct {
  external Pointer<Utf8> filesDir;
  external Pointer<Utf8> tempDir;
}

// === CBLError ================================================================

enum CBLErrorDomain {
  couchbaseLite(cblite_lib.kCBLDomain),
  posix(cblite_lib.kCBLPOSIXDomain),
  sqLite(cblite_lib.kCBLSQLiteDomain),
  fleece(cblite_lib.kCBLFleeceDomain),
  network(cblite_lib.kCBLNetworkDomain),
  webSocket(cblite_lib.kCBLWebSocketDomain),
  mbedTls(cblite_lib.kCBLWebSocketDomain);

  const CBLErrorDomain(this.value);

  factory CBLErrorDomain.fromValue(int value) => switch (value) {
    cblite_lib.kCBLDomain => couchbaseLite,
    cblite_lib.kCBLPOSIXDomain => posix,
    cblite_lib.kCBLSQLiteDomain => sqLite,
    cblite_lib.kCBLFleeceDomain => fleece,
    cblite_lib.kCBLNetworkDomain => network,
    cblite_lib.kCBLWebSocketDomain => webSocket,
    // TODO(blaugold): use constant from library once fixed in CBL C SDK
    7 => mbedTls,
    _ => throw ArgumentError('Unknown error domain: $value'),
  };

  final int value;
}

enum CBLErrorCode {
  assertionFailed(cblite_lib.kCBLErrorAssertionFailed),
  unimplemented(cblite_lib.kCBLErrorUnimplemented),
  unsupportedEncryption(cblite_lib.kCBLErrorUnsupportedEncryption),
  badRevisionId(cblite_lib.kCBLErrorBadRevisionID),
  corruptRevisionData(cblite_lib.kCBLErrorCorruptRevisionData),
  notOpen(cblite_lib.kCBLErrorNotOpen),
  notFound(cblite_lib.kCBLErrorNotFound),
  conflict(cblite_lib.kCBLErrorConflict),
  invalidParameter(cblite_lib.kCBLErrorInvalidParameter),
  unexpectedError(cblite_lib.kCBLErrorUnexpectedError),
  cantOpenFile(cblite_lib.kCBLErrorCantOpenFile),
  iOError(cblite_lib.kCBLErrorIOError),
  memoryError(cblite_lib.kCBLErrorMemoryError),
  notWriteable(cblite_lib.kCBLErrorNotWriteable),
  corruptData(cblite_lib.kCBLErrorCorruptData),
  busy(cblite_lib.kCBLErrorBusy),
  notInTransaction(cblite_lib.kCBLErrorNotInTransaction),
  transactionNotClosed(cblite_lib.kCBLErrorTransactionNotClosed),
  unsupported(cblite_lib.kCBLErrorUnsupported),
  notADatabaseFile(cblite_lib.kCBLErrorNotADatabaseFile),
  wrongFormat(cblite_lib.kCBLErrorWrongFormat),
  crypto(cblite_lib.kCBLErrorCrypto),
  invalidQuery(cblite_lib.kCBLErrorInvalidQuery),
  missingIndex(cblite_lib.kCBLErrorMissingIndex),
  invalidQueryParam(cblite_lib.kCBLErrorInvalidQueryParam),
  remoteError(cblite_lib.kCBLErrorRemoteError),
  databaseTooOld(cblite_lib.kCBLErrorDatabaseTooOld),
  databaseTooNew(cblite_lib.kCBLErrorDatabaseTooNew),
  badDocId(cblite_lib.kCBLErrorBadDocID),
  cantUpgradeDatabase(cblite_lib.kCBLErrorCantUpgradeDatabase);

  const CBLErrorCode(this.value);

  factory CBLErrorCode.fromValue(int value) => switch (value) {
    cblite_lib.kCBLErrorAssertionFailed => assertionFailed,
    cblite_lib.kCBLErrorUnimplemented => unimplemented,
    cblite_lib.kCBLErrorUnsupportedEncryption => unsupportedEncryption,
    cblite_lib.kCBLErrorBadRevisionID => badRevisionId,
    cblite_lib.kCBLErrorCorruptRevisionData => corruptRevisionData,
    cblite_lib.kCBLErrorNotOpen => notOpen,
    cblite_lib.kCBLErrorNotFound => notFound,
    cblite_lib.kCBLErrorConflict => conflict,
    cblite_lib.kCBLErrorInvalidParameter => invalidParameter,
    cblite_lib.kCBLErrorUnexpectedError => unexpectedError,
    cblite_lib.kCBLErrorCantOpenFile => cantOpenFile,
    cblite_lib.kCBLErrorIOError => iOError,
    cblite_lib.kCBLErrorMemoryError => memoryError,
    cblite_lib.kCBLErrorNotWriteable => notWriteable,
    cblite_lib.kCBLErrorCorruptData => corruptData,
    cblite_lib.kCBLErrorBusy => busy,
    cblite_lib.kCBLErrorNotInTransaction => notInTransaction,
    cblite_lib.kCBLErrorTransactionNotClosed => transactionNotClosed,
    cblite_lib.kCBLErrorUnsupported => unsupported,
    cblite_lib.kCBLErrorNotADatabaseFile => notADatabaseFile,
    cblite_lib.kCBLErrorWrongFormat => wrongFormat,
    cblite_lib.kCBLErrorCrypto => crypto,
    cblite_lib.kCBLErrorInvalidQuery => invalidQuery,
    cblite_lib.kCBLErrorMissingIndex => missingIndex,
    cblite_lib.kCBLErrorInvalidQueryParam => invalidQueryParam,
    cblite_lib.kCBLErrorRemoteError => remoteError,
    cblite_lib.kCBLErrorDatabaseTooOld => databaseTooOld,
    cblite_lib.kCBLErrorDatabaseTooNew => databaseTooNew,
    cblite_lib.kCBLErrorBadDocID => badDocId,
    cblite_lib.kCBLErrorCantUpgradeDatabase => cantUpgradeDatabase,
    _ => throw ArgumentError('Unknown error code: $value'),
  };

  final int value;

  DatabaseErrorCode get databaseErrorCode => switch (this) {
    assertionFailed => DatabaseErrorCode.assertionFailed,
    unimplemented => DatabaseErrorCode.unimplemented,
    unsupportedEncryption => DatabaseErrorCode.unsupportedEncryption,
    badRevisionId => DatabaseErrorCode.badRevisionId,
    corruptRevisionData => DatabaseErrorCode.corruptRevisionData,
    notOpen => DatabaseErrorCode.notOpen,
    notFound => DatabaseErrorCode.notFound,
    conflict => DatabaseErrorCode.conflict,
    invalidParameter => DatabaseErrorCode.invalidParameter,
    unexpectedError => DatabaseErrorCode.unexpectedError,
    cantOpenFile => DatabaseErrorCode.cantOpenFile,
    iOError => DatabaseErrorCode.iOError,
    memoryError => DatabaseErrorCode.memoryError,
    notWriteable => DatabaseErrorCode.notWriteable,
    corruptData => DatabaseErrorCode.corruptData,
    busy => DatabaseErrorCode.busy,
    notInTransaction => DatabaseErrorCode.notInTransaction,
    transactionNotClosed => DatabaseErrorCode.transactionNotClosed,
    unsupported => DatabaseErrorCode.unsupported,
    notADatabaseFile => DatabaseErrorCode.notADatabaseFile,
    wrongFormat => DatabaseErrorCode.wrongFormat,
    crypto => DatabaseErrorCode.crypto,
    invalidQuery => DatabaseErrorCode.invalidQuery,
    missingIndex => DatabaseErrorCode.missingIndex,
    invalidQueryParam => DatabaseErrorCode.invalidQueryParam,
    remoteError => DatabaseErrorCode.remoteError,
    databaseTooOld => DatabaseErrorCode.databaseTooOld,
    databaseTooNew => DatabaseErrorCode.databaseTooNew,
    badDocId => DatabaseErrorCode.badDocId,
    cantUpgradeDatabase => DatabaseErrorCode.cantUpgradeDatabase,
  };
}

enum CBLNetworkErrorCode {
  dnsFailure(cblite_lib.kCBLNetErrDNSFailure),
  unknownHost(cblite_lib.kCBLNetErrUnknownHost),
  timeout(cblite_lib.kCBLNetErrTimeout),
  invalidURL(cblite_lib.kCBLNetErrInvalidURL),
  tooManyRedirects(cblite_lib.kCBLNetErrTooManyRedirects),
  tlsHandshakeFailed(cblite_lib.kCBLNetErrTLSHandshakeFailed),
  tlsCertExpired(cblite_lib.kCBLNetErrTLSCertExpired),
  tlsCertUntrusted(cblite_lib.kCBLNetErrTLSCertUntrusted),
  tlsClientCertRequired(cblite_lib.kCBLNetErrTLSClientCertRequired),
  tlsClientCertRejected(cblite_lib.kCBLNetErrTLSClientCertRejected),
  tlsCertUnknownRoot(cblite_lib.kCBLNetErrTLSCertUnknownRoot),
  invalidRedirect(cblite_lib.kCBLNetErrInvalidRedirect),
  unknown(cblite_lib.kCBLNetErrUnknown),
  tlsCertRevoked(cblite_lib.kCBLNetErrTLSCertRevoked),
  tlsCertNameMismatch(cblite_lib.kCBLNetErrTLSCertNameMismatch);

  const CBLNetworkErrorCode(this.value);

  factory CBLNetworkErrorCode.fromValue(int value) => switch (value) {
    cblite_lib.kCBLNetErrDNSFailure => dnsFailure,
    cblite_lib.kCBLNetErrUnknownHost => unknownHost,
    cblite_lib.kCBLNetErrTimeout => timeout,
    cblite_lib.kCBLNetErrInvalidURL => invalidURL,
    cblite_lib.kCBLNetErrTooManyRedirects => tooManyRedirects,
    cblite_lib.kCBLNetErrTLSHandshakeFailed => tlsHandshakeFailed,
    cblite_lib.kCBLNetErrTLSCertExpired => tlsCertExpired,
    cblite_lib.kCBLNetErrTLSCertUntrusted => tlsCertUntrusted,
    cblite_lib.kCBLNetErrTLSClientCertRequired => tlsClientCertRequired,
    cblite_lib.kCBLNetErrTLSClientCertRejected => tlsClientCertRejected,
    cblite_lib.kCBLNetErrTLSCertUnknownRoot => tlsCertUnknownRoot,
    cblite_lib.kCBLNetErrInvalidRedirect => invalidRedirect,
    cblite_lib.kCBLNetErrUnknown => unknown,
    cblite_lib.kCBLNetErrTLSCertRevoked => tlsCertRevoked,
    cblite_lib.kCBLNetErrTLSCertNameMismatch => tlsCertNameMismatch,
    _ => throw ArgumentError('Unknown network error code: $value'),
  };

  final int value;

  NetworkErrorCode get networkErrorCode => switch (this) {
    dnsFailure => NetworkErrorCode.dnsFailure,
    unknownHost => NetworkErrorCode.unknownHost,
    timeout => NetworkErrorCode.timeout,
    invalidURL => NetworkErrorCode.invalidURL,
    tooManyRedirects => NetworkErrorCode.tooManyRedirects,
    tlsHandshakeFailed => NetworkErrorCode.tlsHandshakeFailed,
    tlsCertExpired => NetworkErrorCode.tlsCertExpired,
    tlsCertUntrusted => NetworkErrorCode.tlsCertUntrusted,
    tlsClientCertRequired => NetworkErrorCode.tlsClientCertRequired,
    tlsClientCertRejected => NetworkErrorCode.tlsClientCertRejected,
    tlsCertUnknownRoot => NetworkErrorCode.tlsCertUnknownRoot,
    invalidRedirect => NetworkErrorCode.invalidRedirect,
    unknown => NetworkErrorCode.unknown,
    tlsCertRevoked => NetworkErrorCode.tlsCertRevoked,
    tlsCertNameMismatch => NetworkErrorCode.tlsCertNameMismatch,
  };
}

extension IntErrorCodeExt on int {
  Object toErrorCode(CBLErrorDomain domain) => switch (domain) {
    CBLErrorDomain.couchbaseLite => CBLErrorCode.fromValue(this),
    CBLErrorDomain.posix => this,
    CBLErrorDomain.sqLite => this,
    CBLErrorDomain.fleece => FLError.fromValue(this),
    CBLErrorDomain.network => CBLNetworkErrorCode.fromValue(this),
    CBLErrorDomain.webSocket => this,
    CBLErrorDomain.mbedTls => this,
  };
}

extension CBLErrorExt on cblite_lib.CBLError {
  /// `true` if there is no error stored in this [cblite_lib.CBLError].
  bool get isOk => code == 0;

  void copyToGlobal() {
    globalCBLError.ref.domain = domain;
    globalCBLError.ref.code = code;
    globalCBLError.ref.internal_info = internal_info;
  }

  void reset() {
    code = 0;
  }
}

extension CBLErrorPointerExt on Pointer<cblite_lib.CBLError> {
  CouchbaseLiteException toCouchbaseLiteException({
    String? errorSource,
    int? errorPosition,
  }) {
    final domain = CBLErrorDomain.fromValue(ref.domain);
    final code = ref.code.toErrorCode(domain);
    final message = _baseBinds.getErrorMessage(this)!;
    return createCouchbaseLiteException(
      domain: domain,
      code: code,
      message: message,
      errorSource: errorSource,
      errorPosition: errorPosition,
    );
  }
}

CouchbaseLiteException createCouchbaseLiteException({
  required CBLErrorDomain domain,
  required Object code,
  required String message,
  String? errorSource,
  int? errorPosition,
}) {
  assert((errorSource == null) == (errorPosition == null));

  switch (domain) {
    case CBLErrorDomain.couchbaseLite:
      return DatabaseException(
        message,
        (code as CBLErrorCode).databaseErrorCode,
        errorPosition: errorPosition,
        queryString: errorSource,
      );
    case CBLErrorDomain.posix:
      return PosixException(message, code as int);
    case CBLErrorDomain.sqLite:
      return SQLiteException(message, code as int);
    case CBLErrorDomain.fleece:
      return FleeceException('$message (${(code as FLError).name}))');
    case CBLErrorDomain.network:
      return NetworkException(
        message,
        (code as CBLNetworkErrorCode).networkErrorCode,
      );
    case CBLErrorDomain.webSocket:
      String formatMessage(Object? enumCode) =>
          enumCode != null ? message : '$message ($code)';

      final statusCode = code as int;
      if (statusCode < 1000) {
        final code = _httpErrorCodeMap[statusCode];
        return HttpException(formatMessage(code), code);
      } else {
        final code = _webSocketErrorCodeMap[statusCode];
        return WebSocketException(formatMessage(code), code);
      }
    case CBLErrorDomain.mbedTls:
      return MbedTlsException(message, code as int);
  }
}

const _httpErrorCodeMap = {
  401: HttpErrorCode.authRequired,
  403: HttpErrorCode.forbidden,
  404: HttpErrorCode.notFound,
  409: HttpErrorCode.conflict,
  407: HttpErrorCode.proxyAuthRequired,
  413: HttpErrorCode.entityTooLarge,
  418: HttpErrorCode.imATeapot,
  500: HttpErrorCode.internalServerError,
  501: HttpErrorCode.notFound,
  503: HttpErrorCode.serviceUnavailable,
};

const _webSocketErrorCodeMap = {
  1001: WebSocketErrorCode.goingAway,
  1002: WebSocketErrorCode.protocolError,
  1003: WebSocketErrorCode.dataError,
  1006: WebSocketErrorCode.abnormalClose,
  1007: WebSocketErrorCode.badMessageFormat,
  1008: WebSocketErrorCode.policyError,
  1009: WebSocketErrorCode.messageTooBig,
  1010: WebSocketErrorCode.missingExtension,
  1011: WebSocketErrorCode.cantFulfill,
};

void checkError({String? errorSource}) {
  if (!globalCBLError.ref.isOk) {
    throwError(errorSource: errorSource);
  }
}

Never throwError({String? errorSource}) {
  throw globalCBLError.toCouchbaseLiteException(
    errorSource: errorSource,
    errorPosition: errorSource != null ? globalErrorPosition.value : null,
  );
}

const _checkError = checkError;

extension CheckErrorPointerExt<T extends Pointer> on T {
  T checkError({String? errorSource}) {
    if (this == nullptr) {
      _checkError(errorSource: errorSource);
    }
    return this;
  }
}

extension CheckErrorFLSliceResultExt on cblite_lib.FLSliceResult {
  cblite_lib.FLSliceResult checkError({String? errorSource}) {
    if (buf == nullptr) {
      _checkError(errorSource: errorSource);
    }
    return this;
  }
}

extension CheckErrorIntExt on int {
  int checkError({String? errorSource}) {
    assert(this == 0 || this == 1);
    if (this == 0) {
      _checkError(errorSource: errorSource);
    }
    return this;
  }
}

extension CheckErrorBoolExt on bool {
  bool checkError({String? errorSource}) {
    if (!this) {
      _checkError(errorSource: errorSource);
    }
    return this;
  }
}

// === BaseBindings ============================================================

final class BaseBindings extends Bindings {
  BaseBindings(super.libraries);

  late final isolateId = cblitedart.CBLDart_AllocateIsolateId();

  late final _refCountedFinalizer = NativeFinalizer(
    cblite.addresses.CBL_Release.cast(),
  );

  bool get vectorSearchLibraryAvailable =>
      libraries.vectorSearchLibraryPath != null;

  bool get systemSupportsVectorSearch => switch (Abi.current()) {
    Abi.androidArm ||
    Abi.androidArm64 ||
    Abi.iosArm ||
    Abi.iosArm64 ||
    Abi.linuxArm ||
    Abi.linuxArm64 ||
    Abi.macosArm64 ||
    Abi.windowsArm64 => true,
    Abi.linuxX64 ||
    Abi.windowsX64 ||
    Abi.iosX64 ||
    Abi.macosX64 ||
    Abi.androidX64 => cblitedart.CBLDart_CpuSupportsAVX2(),
    _ => false,
  };

  void initializeNativeLibraries([CBLInitContext? context]) {
    assert(!io.Platform.isAndroid || context != null);

    withZoneArena(() {
      Pointer<_CBLInitContext> contextStruct = nullptr;

      if (context != null) {
        contextStruct = zoneArena<_CBLInitContext>()
          ..ref.filesDir = context.filesDir.toNativeUtf8(allocator: zoneArena)
          ..ref.tempDir = context.tempDir.toNativeUtf8(allocator: zoneArena);
      }

      // The `globalCBLError` cannot be used at this point because it requires
      // initialization to be completed.
      final error = zoneArena<cblite_lib.CBLError>();

      final initializeResult = cblitedart.CBLDart_Initialize(
        NativeApi.initializeApiDLData,
        contextStruct.cast(),
        error,
      );

      switch (initializeResult) {
        case cblitedart_lib
            .CBLDartInitializeResult
            .CBLDartInitializeResult_kSuccess:
          break;
        case cblitedart_lib
            .CBLDartInitializeResult
            .CBLDartInitializeResult_kIncompatibleDartVM:
          throw createCouchbaseLiteException(
            domain: CBLErrorDomain.couchbaseLite,
            code: CBLErrorCode.unsupported,
            message: 'The current Dart VM is incompatible.',
          );
        case cblitedart_lib
            .CBLDartInitializeResult
            .CBLDartInitializeResult_kCBLInitError:
          throw error.toCouchbaseLiteException();
      }
    });
  }

  void enableVectorSearch() {
    if (libraries.vectorSearchLibraryPath case final libraryPath?
        when systemSupportsVectorSearch) {
      final libraryDirectory = p.dirname(libraryPath);
      runWithSingleFLString(libraryDirectory, (flLibraryDirectory) {
        cblite.CBL_EnableVectorSearch(
          flLibraryDirectory,
          globalCBLError,
        ).checkError();
      });
    }
  }

  void bindCBLRefCountedToDartObject(
    Finalizable object,
    Pointer<cblite_lib.CBLRefCounted> refCounted,
  ) {
    _refCountedFinalizer.attach(object, refCounted.cast());
  }

  void retainRefCounted(Pointer<cblite_lib.CBLRefCounted> refCounted) {
    cblite.CBL_Retain(refCounted);
  }

  void releaseRefCounted(Pointer<cblite_lib.CBLRefCounted> refCounted) {
    cblite.CBL_Release(refCounted);
  }

  String? getErrorMessage(Pointer<cblite_lib.CBLError> error) =>
      cblite.CBLError_Message(
        error,
      ).toDartStringAndRelease(allowMalformed: true);

  void removeListener(Pointer<cblite_lib.CBLListenerToken> token) {
    cblite.CBLListener_Remove(token);
  }

  T runWithIsolateId<T>(T Function() body) {
    cblitedart.CBLDart_SetCurrentIsolateId(isolateId);
    try {
      return body();
    } finally {
      cblitedart.CBLDart_SetCurrentIsolateId(
        cblitedart_lib.kCBLDartInvalidIsolateId,
      );
    }
  }

  void completeCompleterWithPointer(
    cblitedart_lib.CBLDart_Completer completer,
    Pointer<Void> result,
  ) => cblitedart.CBLDart_Completer_Complete(completer, result.address);

  void completeCompleterWithBool(
    cblitedart_lib.CBLDart_Completer completer,
    // ignore: avoid_positional_boolean_parameters
    bool result,
  ) {
    cblitedart.CBLDart_Completer_Complete(completer, result ? 1 : 0);
  }
}
