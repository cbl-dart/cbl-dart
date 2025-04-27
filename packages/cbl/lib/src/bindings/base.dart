import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../errors.dart';
import 'bindings.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
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
      cblitedart.CBLDartInitializeResult.CBLDartInitializeResult_kCBLInitError),
  incompatibleDartVM(cblitedart
      .CBLDartInitializeResult.CBLDartInitializeResult_kIncompatibleDartVM),
  cblInitError(
      cblitedart.CBLDartInitializeResult.CBLDartInitializeResult_kCBLInitError);

  const CBLDartInitializeResult(this.value);

  static CBLDartInitializeResult fromValue(int value) => switch (value) {
        cblitedart.CBLDartInitializeResult.CBLDartInitializeResult_kSuccess =>
          success,
        cblitedart.CBLDartInitializeResult
              .CBLDartInitializeResult_kIncompatibleDartVM =>
          incompatibleDartVM,
        cblitedart
              .CBLDartInitializeResult.CBLDartInitializeResult_kCBLInitError =>
          cblInitError,
        _ => throw ArgumentError(
            'Unknown value for CBLDartInitializeResult: $value'),
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
  couchbaseLite(cblite.kCBLDomain),
  posix(cblite.kCBLPOSIXDomain),
  sqLite(cblite.kCBLSQLiteDomain),
  fleece(cblite.kCBLFleeceDomain),
  network(cblite.kCBLNetworkDomain),
  webSocket(cblite.kCBLWebSocketDomain);

  const CBLErrorDomain(this.value);

  factory CBLErrorDomain.fromValue(int value) => switch (value) {
        cblite.kCBLDomain => couchbaseLite,
        cblite.kCBLPOSIXDomain => posix,
        cblite.kCBLSQLiteDomain => sqLite,
        cblite.kCBLFleeceDomain => fleece,
        cblite.kCBLNetworkDomain => network,
        cblite.kCBLWebSocketDomain => webSocket,
        _ => throw ArgumentError('Unknown error domain: $value'),
      };

  final int value;
}

enum CBLErrorCode {
  assertionFailed(cblite.kCBLErrorAssertionFailed),
  unimplemented(cblite.kCBLErrorUnimplemented),
  unsupportedEncryption(cblite.kCBLErrorUnsupportedEncryption),
  badRevisionId(cblite.kCBLErrorBadRevisionID),
  corruptRevisionData(cblite.kCBLErrorCorruptRevisionData),
  notOpen(cblite.kCBLErrorNotOpen),
  notFound(cblite.kCBLErrorNotFound),
  conflict(cblite.kCBLErrorConflict),
  invalidParameter(cblite.kCBLErrorInvalidParameter),
  unexpectedError(cblite.kCBLErrorUnexpectedError),
  cantOpenFile(cblite.kCBLErrorCantOpenFile),
  iOError(cblite.kCBLErrorIOError),
  memoryError(cblite.kCBLErrorMemoryError),
  notWriteable(cblite.kCBLErrorNotWriteable),
  corruptData(cblite.kCBLErrorCorruptData),
  busy(cblite.kCBLErrorBusy),
  notInTransaction(cblite.kCBLErrorNotInTransaction),
  transactionNotClosed(cblite.kCBLErrorTransactionNotClosed),
  unsupported(cblite.kCBLErrorUnsupported),
  notADatabaseFile(cblite.kCBLErrorNotADatabaseFile),
  wrongFormat(cblite.kCBLErrorWrongFormat),
  crypto(cblite.kCBLErrorCrypto),
  invalidQuery(cblite.kCBLErrorInvalidQuery),
  missingIndex(cblite.kCBLErrorMissingIndex),
  invalidQueryParam(cblite.kCBLErrorInvalidQueryParam),
  remoteError(cblite.kCBLErrorRemoteError),
  databaseTooOld(cblite.kCBLErrorDatabaseTooOld),
  databaseTooNew(cblite.kCBLErrorDatabaseTooNew),
  badDocId(cblite.kCBLErrorBadDocID),
  cantUpgradeDatabase(cblite.kCBLErrorCantUpgradeDatabase);

  const CBLErrorCode(this.value);

  factory CBLErrorCode.fromValue(int value) => switch (value) {
        cblite.kCBLErrorAssertionFailed => assertionFailed,
        cblite.kCBLErrorUnimplemented => unimplemented,
        cblite.kCBLErrorUnsupportedEncryption => unsupportedEncryption,
        cblite.kCBLErrorBadRevisionID => badRevisionId,
        cblite.kCBLErrorCorruptRevisionData => corruptRevisionData,
        cblite.kCBLErrorNotOpen => notOpen,
        cblite.kCBLErrorNotFound => notFound,
        cblite.kCBLErrorConflict => conflict,
        cblite.kCBLErrorInvalidParameter => invalidParameter,
        cblite.kCBLErrorUnexpectedError => unexpectedError,
        cblite.kCBLErrorCantOpenFile => cantOpenFile,
        cblite.kCBLErrorIOError => iOError,
        cblite.kCBLErrorMemoryError => memoryError,
        cblite.kCBLErrorNotWriteable => notWriteable,
        cblite.kCBLErrorCorruptData => corruptData,
        cblite.kCBLErrorBusy => busy,
        cblite.kCBLErrorNotInTransaction => notInTransaction,
        cblite.kCBLErrorTransactionNotClosed => transactionNotClosed,
        cblite.kCBLErrorUnsupported => unsupported,
        cblite.kCBLErrorNotADatabaseFile => notADatabaseFile,
        cblite.kCBLErrorWrongFormat => wrongFormat,
        cblite.kCBLErrorCrypto => crypto,
        cblite.kCBLErrorInvalidQuery => invalidQuery,
        cblite.kCBLErrorMissingIndex => missingIndex,
        cblite.kCBLErrorInvalidQueryParam => invalidQueryParam,
        cblite.kCBLErrorRemoteError => remoteError,
        cblite.kCBLErrorDatabaseTooOld => databaseTooOld,
        cblite.kCBLErrorDatabaseTooNew => databaseTooNew,
        cblite.kCBLErrorBadDocID => badDocId,
        cblite.kCBLErrorCantUpgradeDatabase => cantUpgradeDatabase,
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
  dnsFailure(cblite.kCBLNetErrDNSFailure),
  unknownHost(cblite.kCBLNetErrUnknownHost),
  timeout(cblite.kCBLNetErrTimeout),
  invalidURL(cblite.kCBLNetErrInvalidURL),
  tooManyRedirects(cblite.kCBLNetErrTooManyRedirects),
  tlsHandshakeFailed(cblite.kCBLNetErrTLSHandshakeFailed),
  tlsCertExpired(cblite.kCBLNetErrTLSCertExpired),
  tlsCertUntrusted(cblite.kCBLNetErrTLSCertUntrusted),
  tlsClientCertRequired(cblite.kCBLNetErrTLSClientCertRequired),
  tlsClientCertRejected(cblite.kCBLNetErrTLSClientCertRejected),
  tlsCertUnknownRoot(cblite.kCBLNetErrTLSCertUnknownRoot),
  invalidRedirect(cblite.kCBLNetErrInvalidRedirect),
  unknown(cblite.kCBLNetErrUnknown),
  tlsCertRevoked(cblite.kCBLNetErrTLSCertRevoked),
  tlsCertNameMismatch(cblite.kCBLNetErrTLSCertNameMismatch);

  const CBLNetworkErrorCode(this.value);

  factory CBLNetworkErrorCode.fromValue(int value) => switch (value) {
        cblite.kCBLNetErrDNSFailure => dnsFailure,
        cblite.kCBLNetErrUnknownHost => unknownHost,
        cblite.kCBLNetErrTimeout => timeout,
        cblite.kCBLNetErrInvalidURL => invalidURL,
        cblite.kCBLNetErrTooManyRedirects => tooManyRedirects,
        cblite.kCBLNetErrTLSHandshakeFailed => tlsHandshakeFailed,
        cblite.kCBLNetErrTLSCertExpired => tlsCertExpired,
        cblite.kCBLNetErrTLSCertUntrusted => tlsCertUntrusted,
        cblite.kCBLNetErrTLSClientCertRequired => tlsClientCertRequired,
        cblite.kCBLNetErrTLSClientCertRejected => tlsClientCertRejected,
        cblite.kCBLNetErrTLSCertUnknownRoot => tlsCertUnknownRoot,
        cblite.kCBLNetErrInvalidRedirect => invalidRedirect,
        cblite.kCBLNetErrUnknown => unknown,
        cblite.kCBLNetErrTLSCertRevoked => tlsCertRevoked,
        cblite.kCBLNetErrTLSCertNameMismatch => tlsCertNameMismatch,
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
        CBLErrorDomain.webSocket => this
      };
}

extension CBLErrorExt on cblite.CBLError {
  /// `true` if there is no error stored in this [cblite.CBLError].
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

extension CBLErrorPointerExt on Pointer<cblite.CBLError> {
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

extension CheckErrorFLSliceResultExt on cblite.FLSliceResult {
  cblite.FLSliceResult checkError({String? errorSource}) {
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

  late final isolateId = cblDart.CBLDart_AllocateIsolateId();

  late final _refCountedFinalizer =
      NativeFinalizer(cbl.addresses.CBL_Release.cast());

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
        Abi.windowsArm64 =>
          true,
        Abi.linuxX64 ||
        Abi.windowsX64 ||
        Abi.iosX64 ||
        Abi.macosX64 ||
        Abi.androidX64 =>
          cblDart.CBLDart_CpuSupportsAVX2(),
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
      final error = zoneArena<cblite.CBLError>();

      final initializeResult = cblDart.CBLDart_Initialize(
        NativeApi.initializeApiDLData,
        contextStruct.cast(),
        error,
      );

      switch (initializeResult) {
        case cblitedart
              .CBLDartInitializeResult.CBLDartInitializeResult_kSuccess:
          break;
        case cblitedart.CBLDartInitializeResult
              .CBLDartInitializeResult_kIncompatibleDartVM:
          throw createCouchbaseLiteException(
            domain: CBLErrorDomain.couchbaseLite,
            code: CBLErrorCode.unsupported,
            message: 'The current Dart VM is incompatible.',
          );
        case cblitedart
              .CBLDartInitializeResult.CBLDartInitializeResult_kCBLInitError:
          throw error.toCouchbaseLiteException();
      }
    });
  }

  void enableVectorSearch() {
    if (libraries.vectorSearchLibraryPath case final libraryPath?
        when systemSupportsVectorSearch) {
      final libraryDirectory = p.dirname(libraryPath);
      runWithSingleFLString(libraryDirectory, (flLibraryDirectory) {
        cbl.CBL_EnableVectorSearch(flLibraryDirectory, globalCBLError)
            .checkError();
      });
    }
  }

  void bindCBLRefCountedToDartObject(
    Finalizable object,
    Pointer<cblite.CBLRefCounted> refCounted,
  ) {
    _refCountedFinalizer.attach(object, refCounted.cast());
  }

  void retainRefCounted(Pointer<cblite.CBLRefCounted> refCounted) {
    cbl.CBL_Retain(refCounted);
  }

  void releaseRefCounted(Pointer<cblite.CBLRefCounted> refCounted) {
    cbl.CBL_Release(refCounted);
  }

  String? getErrorMessage(Pointer<cblite.CBLError> error) =>
      cbl.CBLError_Message(error).toDartStringAndRelease(allowMalformed: true);

  void removeListener(Pointer<cblite.CBLListenerToken> token) {
    cbl.CBLListener_Remove(token);
  }

  T runWithIsolateId<T>(T Function() body) {
    cblDart.CBLDart_SetCurrentIsolateId(isolateId);
    try {
      return body();
    } finally {
      cblDart.CBLDart_SetCurrentIsolateId(cblitedart.kCBLDartInvalidIsolateId);
    }
  }

  void completeCompleter(
    cblitedart.CBLDart_Completer completer,
    Pointer<Void> result,
  ) =>
      cblDart.CBLDart_Completer_Complete(completer, result);
}
