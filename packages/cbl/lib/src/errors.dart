import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:ffi/ffi.dart';

import 'utils.dart';

export 'package:cbl_ffi/cbl_ffi.dart'
    show CouchbaseLiteErrorCode, NetworkErrorCode, FleeceErrorCode;

abstract class BaseException implements Exception {
  BaseException(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseException &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => super.hashCode ^ message.hashCode;
}

class CouchbaseLiteException extends BaseException {
  CouchbaseLiteException(
    String message,
    this.code, {
    this.queryString,
    this.errorPosition,
  }) : super(message);

  final CouchbaseLiteErrorCode code;

  /// If this is an query parsing exception the invalid query string.
  final String? queryString;

  /// If this is an query parsing exception the position of the error in the
  /// [queryString].
  final int? errorPosition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CouchbaseLiteException &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          queryString == other.queryString &&
          errorPosition == other.errorPosition;

  @override
  int get hashCode =>
      super.hashCode ^
      code.hashCode ^
      queryString.hashCode ^
      errorPosition.hashCode;

  @override
  String toString() => [
        'CouchbaseLiteException(message: $message, code: $code',
        if (queryString != null)
          ', queryString: $queryString, errorPosition: $errorPosition',
        ')'
      ].join();
}

class PosixException extends BaseException {
  PosixException(
    String message,
    this.errno,
  ) : super(message);

  final int errno;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosixException &&
          runtimeType == other.runtimeType &&
          errno == other.errno;

  @override
  int get hashCode => super.hashCode ^ errno.hashCode;

  @override
  String toString() => 'PosixException(message: $message, errno: $errno)';
}

class SQLiteException extends BaseException {
  SQLiteException(
    String message,
    this.code,
  ) : super(message);

  final int code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SQLiteException &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => super.hashCode ^ code.hashCode;

  @override
  String toString() => 'SQLiteExceptions(message: $message, code: $code)';
}

class FleeceException extends BaseException {
  FleeceException(
    String message,
    this.code,
  ) : super(message);

  final FleeceErrorCode code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FleeceException &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => super.hashCode ^ code.hashCode;

  @override
  String toString() => 'FleeceException(message: $message, code: $code)';
}

class NetworkException extends BaseException {
  NetworkException(
    String message,
    this.code,
  ) : super(message);

  final NetworkErrorCode code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkException &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => super.hashCode ^ code.hashCode;

  @override
  String toString() => 'NetworkException(message: $message, code: $code)';
}

class WebSocketException extends BaseException {
  WebSocketException(
    String message,
    this.code,
  ) : super(message);

  final int code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebSocketException &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => super.hashCode ^ code.hashCode;

  @override
  String toString() => 'WebSocketException(message: $message, code: $code)';
}

// TODO: free allocated memory when Isolate goes away
late final globalError = malloc<CBLError>();

BaseException exceptionFromCBLError({
  Pointer<CBLError>? error,
  String? queryString,
}) {
  error = error ?? globalError;
  assert(!error.isOk);

  // Caller must free memory of returned string.
  final messagePointer = CBLBindings.instance.base.Error_Message(error);
  final message = messagePointer.toDartString();
  malloc.free(messagePointer);

  final code = error.ref.code;

  switch (errorDomainFromCInt(error.ref.domain)) {
    case ErrorDomain.couchbaseLite:
      final cblCode = couchbaseLiteErrorCodeFromCInt(code);

      int? errorPosition;
      if (queryString != null) {
        errorPosition = CBLBindings.instance.query.globalErrorPosition.value
            .let((it) => it == -1 ? null : it);
      }

      return CouchbaseLiteException(
        message,
        cblCode,
        errorPosition: errorPosition,
        queryString: queryString,
      );
    case ErrorDomain.posix:
      return PosixException(message, code);
    case ErrorDomain.sqLite:
      return SQLiteException(message, code);
    case ErrorDomain.fleece:
      return FleeceException(message, code.toFleeceErrorCode());
    case ErrorDomain.network:
      return NetworkException(message, networkErrorCodeFromCInt(code));
    case ErrorDomain.webSocket:
      return WebSocketException(message, code);
  }
}

/// Throws an exception, built from [globalError] if it contains an error.
///
/// See:
/// - [CBLErrorPointerExt].isOk
void checkError() {
  if (globalError.isOk) return;

  throw exceptionFromCBLError();
}

/// Throws an exception, built from [globalError] if it contains an error and
/// [result] is `false` or [nullptr]. Otherwise [result] is returned.
///
/// [result] must be a [Pointer] or a [bool].
T checkResultAndError<T>(T result) {
  assert(result is Pointer || result is bool);

  if (result == false || result == nullptr) {
    checkError();
  }

  return result;
}

final _checkResultAndError = checkResultAndError;

extension CheckResultAndErrorExt<T> on T {
  /// Throws an exception, built from [globalError] if it contains an error and
  /// this is `false` or [nullptr]. Otherwise this is returned.
  ///
  /// This must be a [Pointer] or a [bool].
  T checkResultAndError() => _checkResultAndError(this);
}
