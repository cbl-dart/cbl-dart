import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

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
}

enum CBLNetworkErrorCode {
  dnsFailure(cblite.kCBLNetErrDNSFailure),
  unknownHost(cblite.kCBLNetErrUnknownHost),
  timeout(cblite.kCBLNetErrTimeout),
  invalidURL(cblite.kCBLNetErrInvalidURL),
  tooManyRedirects(cblite.kCBLNetErrTooManyRedirects),
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
}

extension IntErrorCodeExt on int {
  Object toErrorCode(CBLErrorDomain domain) => switch (domain) {
        CBLErrorDomain.couchbaseLite => CBLErrorCode.fromValue(this),
        CBLErrorDomain.posix => this,
        CBLErrorDomain.sqLite => this,
        CBLErrorDomain.fleece => cblite.FLError.fromValue(this),
        CBLErrorDomain.network => CBLNetworkErrorCode.fromValue(this),
        CBLErrorDomain.webSocket => this
      };
}

extension CBLErrorExt on cblite.CBLError {
  CBLErrorDomain get domainEnum => CBLErrorDomain.fromValue(domain);

  Object get codeEnum => code.toErrorCode(domainEnum);

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

final class CBLErrorException implements Exception {
  CBLErrorException(
    this.domain,
    this.code,
    this.message, {
    this.errorPosition,
    this.errorSource,
  });

  CBLErrorException.fromCBLError(Pointer<cblite.CBLError> error)
      : this(
          error.ref.domainEnum,
          error.ref.codeEnum,
          _baseBinds.getErrorMessage(globalCBLError)!,
        );

  CBLErrorException.fromCBLErrorWithSource(
    Pointer<cblite.CBLError> error, {
    required String errorSource,
    required int errorPosition,
  }) : this(
          error.ref.domainEnum,
          error.ref.codeEnum,
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

extension CheckCBLErrorFLSliceResultExt on cblite.FLSliceResult {
  cblite.FLSliceResult checkCBLError({String? errorSource}) {
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

// === BaseBindings ============================================================

final class BaseBindings extends Bindings {
  BaseBindings(super.parent);

  late final isolateId = cblDart.CBLDart_AllocateIsolateId();

  late final _refCountedFinalizer =
      NativeFinalizer(cbl.addresses.CBL_Release.cast());

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
          throw CBLErrorException(
            CBLErrorDomain.couchbaseLite,
            CBLErrorCode.unsupported,
            'The current Dart VM is incompatible.',
          );
        case cblitedart
              .CBLDartInitializeResult.CBLDartInitializeResult_kCBLInitError:
          throw CBLErrorException.fromCBLError(error);
      }

      if (libraries.vectorSearchLibraryPath case final libraryPath?) {
        final libraryDirectory = p.dirname(libraryPath);
        runWithSingleFLString(libraryDirectory, (flLibraryDirectory) {
          cbl.CBL_EnableVectorSearch(flLibraryDirectory, globalCBLError)
              .checkCBLError();
        });
      }
    });
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
