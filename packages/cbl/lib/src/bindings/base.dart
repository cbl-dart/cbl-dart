// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, camel_case_types, avoid_private_typedef_functions

import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';

import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'fleece.dart';
import 'global.dart';

const _bindings = BaseBindings();

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

enum _CBLDartInitializeResult {
  success,
  incompatibleDartVM,
  cblInitError,
}

extension on int {
  _CBLDartInitializeResult toCBLDartInitializeResult() {
    assert(this >= 0 || this <= 2);
    return _CBLDartInitializeResult.values[this];
  }
}

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

typedef CBLError = cblite.CBLError;

extension CBLErrorExt on CBLError {
  CBLErrorDomain get dartDomain => domain.toErrorDomain();

  Object get dartCode => code.toErrorCode(dartDomain);

  /// `true` if there is no error stored in this [CBLError].
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

  CBLErrorException.fromCBLError(Pointer<CBLError> error)
      : this(
          error.ref.dartDomain,
          error.ref.dartCode,
          _bindings.getErrorMessage(globalCBLError)!,
        );

  CBLErrorException.fromCBLErrorWithSource(
    Pointer<CBLError> error, {
    required String errorSource,
    required int errorPosition,
  }) : this(
          error.ref.dartDomain,
          error.ref.dartCode,
          _bindings.getErrorMessage(globalCBLError)!,
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

typedef CBLRefCounted = cblite.CBLRefCounted;

// === CBLListener =============================================================

typedef CBLListenerToken = cblitedart.CBLListenerToken;

// === BaseBindings ============================================================

final class BaseBindings {
  const BaseBindings();

  static final _refCountedFinalizer = NativeFinalizer(
      Native.addressOf<NativeFunction<cblite.NativeCBL_Release>>(
              cblite.CBL_Release)
          .cast());

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
      final error = zoneArena<CBLError>();

      final initializeResult = cblitedart.CBLDart_Initialize(
        NativeApi.initializeApiDLData,
        contextStruct.cast(),
        error,
      ).toCBLDartInitializeResult();

      switch (initializeResult) {
        case _CBLDartInitializeResult.success:
          return;
        case _CBLDartInitializeResult.incompatibleDartVM:
          throw CBLErrorException(
            CBLErrorDomain.couchbaseLite,
            CBLErrorCode.unsupported,
            'The current Dart VM is incompatible.',
          );
        case _CBLDartInitializeResult.cblInitError:
          throw CBLErrorException.fromCBLError(error);
      }
    });
  }

  void bindCBLRefCountedToDartObject(
    Finalizable object,
    Pointer<CBLRefCounted> refCounted,
  ) {
    _refCountedFinalizer.attach(object, refCounted.cast());
  }

  void retainRefCounted(Pointer<CBLRefCounted> refCounted) {
    cblite.CBL_Retain(refCounted);
  }

  void releaseRefCounted(Pointer<CBLRefCounted> refCounted) {
    cblite.CBL_Release(refCounted);
  }

  String? getErrorMessage(Pointer<CBLError> error) =>
      cblite.CBLError_Message(error)
          .toDartStringAndRelease(allowMalformed: true);

  void removeListener(Pointer<CBLListenerToken> token) {
    cblite.CBLListener_Remove(token);
  }
}
