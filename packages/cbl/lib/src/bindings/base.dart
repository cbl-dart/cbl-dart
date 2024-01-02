// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_redundant_argument_values, camel_case_types, avoid_private_typedef_functions

import 'dart:ffi';
import 'dart:io' as io;

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'fleece.dart';
import 'global.dart';

final _baseBinds = CBLBindings.instance.base;

// === Option ==================================================================

abstract class Option {
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

class CBLInitContext {
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

typedef _CBLDart_Initialize_C = Uint8 Function(
  Pointer<Void> dartInitializeDlData,
  Pointer<Void> cblInitContext,
  Pointer<CBLError> errorOut,
);
typedef _CBLDart_Initialize = int Function(
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

final class CBLError extends Struct {
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

  void reset() {
    _code = 0;
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

final class CBLRefCounted extends Opaque {}

typedef _CBL_Retain = Pointer<CBLRefCounted> Function(
  Pointer<CBLRefCounted> refCounted,
);

typedef _CBL_Release = Pointer<CBLRefCounted> Function(
  Pointer<CBLRefCounted> refCounted,
);

// === CBLListener =============================================================

final class CBLListenerToken extends Opaque {}

typedef _CBLListener_Remove_C = Void Function(
  Pointer<CBLListenerToken> listenerToken,
);
typedef _CBLListener_Remove = void Function(
  Pointer<CBLListenerToken> listenerToken,
);

// === BaseBindings ============================================================

class BaseBindings extends Bindings {
  BaseBindings(super.parent) {
    _initialize =
        libs.cblDart.lookupFunction<_CBLDart_Initialize_C, _CBLDart_Initialize>(
      'CBLDart_Initialize',
      isLeaf: useIsLeaf,
    );

    _retainRefCounted = libs.cbl.lookupFunction<_CBL_Retain, _CBL_Retain>(
      'CBL_Retain',
      isLeaf: useIsLeaf,
    );
    _releaseRefCountedPtr =
        libs.cbl.lookup<NativeFunction<_CBL_Release>>('CBL_Release');
    _releaseRefCounted = _releaseRefCountedPtr.asFunction(isLeaf: useIsLeaf);
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
  late final _CBL_Retain _retainRefCounted;
  late final Pointer<NativeFunction<_CBL_Release>> _releaseRefCountedPtr;
  late final _CBL_Release _releaseRefCounted;
  late final _CBLError_Message _getErrorMessage;
  late final _CBLListener_Remove _removeListener;

  late final _refCountedFinalizer =
      NativeFinalizer(_releaseRefCountedPtr.cast());

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

      final initializeResult = _initialize(
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
    _retainRefCounted(refCounted);
  }

  void releaseRefCounted(Pointer<CBLRefCounted> refCounted) {
    _releaseRefCounted(refCounted);
  }

  String? getErrorMessage(Pointer<CBLError> error) =>
      _getErrorMessage(error).toDartStringAndRelease(allowMalformed: true);

  void removeListener(Pointer<CBLListenerToken> token) {
    _removeListener(token);
  }
}
