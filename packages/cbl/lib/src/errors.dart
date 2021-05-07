import 'package:cbl_ffi/cbl_ffi.dart';

enum CouchbaseLiteErrorCode {
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

extension on CBLErrorCode {
  CouchbaseLiteErrorCode toCouchbaseLiteErrorCode() =>
      CouchbaseLiteErrorCode.values[index];
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

extension on CBLNetworkErrorCode {
  NetworkErrorCode toNetworkErrorCode() => NetworkErrorCode.values[index];
}

/// Error codes returned from some API calls.
enum FleeceErrorCode {
  noError,

  /// Out of memory, or allocation failed.
  memoryError,

  /// Array index or iterator out of range.
  outOfRange,

  /// Bad input data (NaN, non-string key, etc.).
  invalidData,

  /// Structural error encoding (missing value, too many ends, etc.).
  encodeError,

  /// Error parsing JSON.
  jsonError,

  /// Unparseable data in a Value (corrupt? Or from some distant future?).
  unknownValue,

  /// Something that shouldn't happen.
  internalError,

  /// Key not found.
  notFound,

  /// Misuse of shared keys (not in transaction, etc.)
  sharedKeysStateError,
  posixError,

  /// Operation is unsupported
  unsupported,
}

extension on FLErrorCode {
  FleeceErrorCode toFleeceErrorCode() => FleeceErrorCode.values[index];
}

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
  int get hashCode => message.hashCode;
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
  String toString() {
    var result = 'CouchbaseLiteException(message: $message, code: $code)';

    if (queryString != null) {
      if (errorPosition != null) {
        result += '\n${_highlightErrorPosition(
          source: queryString!,
          offset: errorPosition!,
        )}';
      } else {
        result += '\n$queryString';
      }
    }

    return result;
  }
}

/// Highlights the position of an error in a [source] string at [offset].
///
/// Adapted from [FormatException.toString].
String _highlightErrorPosition({required String source, required int offset}) {
  var report = '';

  var lineStart = 0;
  var previousCharWasCR = false;
  for (var i = 0; i < offset; i++) {
    var char = source.codeUnitAt(i);
    if (char == 0x0a) {
      if (lineStart != i || !previousCharWasCR) {}
      lineStart = i + 1;
      previousCharWasCR = false;
    } else if (char == 0x0d) {
      lineStart = i + 1;
      previousCharWasCR = true;
    }
  }
  var lineEnd = source.length;
  for (var i = offset; i < source.length; i++) {
    var char = source.codeUnitAt(i);
    if (char == 0x0a || char == 0x0d) {
      lineEnd = i;
      break;
    }
  }
  var length = lineEnd - lineStart;
  var start = lineStart;
  var end = lineEnd;
  var prefix = '';
  var postfix = '';
  if (length > 78) {
    // Can't show entire line. Try to anchor at the nearest end, if
    // one is within reach.
    var index = offset - lineStart;
    if (index < 75) {
      end = start + 75;
      postfix = '...';
    } else if (end - offset < 75) {
      start = end - 75;
      prefix = '...';
    } else {
      // Neither end is near, just pick an area around the offset.
      start = offset - 36;
      end = offset + 36;
      prefix = postfix = '...';
    }
  }
  var slice = source.substring(start, end);
  var markOffset = offset - start + prefix.length;
  return "$report$prefix$slice$postfix\n${" " * markOffset}^\n";
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

BaseException translateCBLErrorException(CBLErrorException exception) {
  switch (exception.domain) {
    case CBLErrorDomain.couchbaseLite:
      return CouchbaseLiteException(
        exception.message,
        (exception.code as CBLErrorCode).toCouchbaseLiteErrorCode(),
        errorPosition: exception.errorPosition,
        queryString: exception.errorSource,
      );
    case CBLErrorDomain.posix:
      return PosixException(exception.message, exception.code as int);
    case CBLErrorDomain.sqLite:
      return SQLiteException(exception.message, exception.code as int);
    case CBLErrorDomain.fleece:
      return FleeceException(
        exception.message,
        (exception.code as FLErrorCode).toFleeceErrorCode(),
      );
    case CBLErrorDomain.network:
      return NetworkException(
        exception.message,
        (exception.code as CBLNetworkErrorCode).toNetworkErrorCode(),
      );
    case CBLErrorDomain.webSocket:
      return WebSocketException(exception.message, exception.code as int);
  }
}

extension CBLErrorExceptionExt on CBLErrorException {
  BaseException translate() => translateCBLErrorException(this);
}
