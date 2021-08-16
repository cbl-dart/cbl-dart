import 'support/utils.dart';

/// Base class for custom exceptions in the `cbl` package.
abstract class CouchbaseLiteException implements Exception {
  /// A description of this exception.
  String get message;

  /// An optional error code specifies the cause of this exception.
  Object? get code => null;

  String get _typeName;

  @override
  String toString() => [
        '$_typeName(',
        [
          message,
          if (code != null) 'code: ${describeEnum(code!)}',
        ].join(', '),
        ')'
      ].join();
}

/// A specification of the cause of a [DatabaseException].
enum DatabaseErrorCode {
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

/// Exception throw when there is a failure interacting with a Couchbase Lite
/// database.
class DatabaseException extends CouchbaseLiteException {
  /// Creates an exception which is thrown when there is a failure interacting
  /// with a Couchbase Lite database.
  DatabaseException(
    this.message,
    this.code, {
    this.queryString,
    this.errorPosition,
  });

  @override
  final String message;

  @override
  final DatabaseErrorCode code;

  /// If this is an query parsing exception the invalid query string.
  final String? queryString;

  /// If this is an query parsing exception the position of the error in the
  /// [queryString].
  final int? errorPosition;

  @override
  String toString() {
    var result = super.toString();

    if (queryString != null) {
      if (errorPosition != null) {
        result +=
            '\n${highlightPosition(queryString!, offset: errorPosition!)}';
      } else {
        result += '\n$queryString';
      }
    }

    return result;
  }

  @override
  final _typeName = 'DatabaseException';
}

/// A specification of the cause of a [NetworkException].
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

/// Exception thrown when there is a failure accessing the network.
class NetworkException extends CouchbaseLiteException {
  /// Creates an exception which is thrown when there is a failure accessing the
  /// network.
  NetworkException(this.message, this.code);

  @override
  final String message;

  @override
  final NetworkErrorCode code;

  @override
  final _typeName = 'NetworkException';
}

/// A specification of the cause of a [HttpException].
enum HttpErrorCode {
  /// Missing or incorrect user authentication.
  authRequired,

  /// User doesn't have permission to access resource.
  forbidden,

  /// Resource not found.
  notFound,

  /// Update conflict.
  conflict,

  /// HTTP proxy requires authentication.
  proxyAuthRequired,

  /// Data is too large to upload.
  entityTooLarge,

  /// HTCPCP/1.0 error (RFC 2324).
  imATeapot,

  /// Something's wrong with the server.
  internalServerError,

  /// Unimplemented server functionality.
  notImplemented,

  /// Service is down temporarily(?).
  serviceUnavailable,
}

/// Exception thrown when there is an HTTP error.
class HttpException extends CouchbaseLiteException {
  /// Creates an exception which is thrown when there is an HTTP error.
  HttpException(this.message, this.code);

  @override
  final String message;

  @override
  final HttpErrorCode? code;

  @override
  final _typeName = 'HttpException';
}

/// A specification of the cause of a [WebSocketException].
enum WebSocketErrorCode {
  /// Peer has to close, e.g. because host app is quitting.
  goingAway,

  /// Protocol violation: invalid framing data.
  protocolError,

  /// Message payload cannot be handled.
  dataError,

  /// TCP socket closed unexpectedly.
  abnormalClose,

  /// Unparseable WebSocket message.
  badMessageFormat,

  /// Message violated unspecified policy.
  policyError,

  /// Message is too large for peer to handle.
  messageTooBig,

  /// Peer doesn't provide a necessary extension.
  missingExtension,

  /// Can't fulfill request due to "unexpected condition".
  cantFulfill,
}

/// Exception thrown when there is an WebSocket error.
class WebSocketException extends CouchbaseLiteException {
  /// Creates an exception which is thrown when there is an WebSocket error.
  WebSocketException(this.message, this.code);

  @override
  final String message;

  @override
  final WebSocketErrorCode? code;

  @override
  final _typeName = 'WebSocketException';
}

/// Exception thrown when JSON data is invalid.
class InvalidJsonException extends CouchbaseLiteException {
  /// Creates an exception which is thrown when JSON data is invalid.
  InvalidJsonException(this.message);

  @override
  final String message;

  @override
  final _typeName = 'InvalidJsonException';
}
