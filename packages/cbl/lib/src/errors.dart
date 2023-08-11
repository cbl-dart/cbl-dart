import 'package:meta/meta.dart';

import 'service/channel.dart' as channel;
import 'support/utils.dart';

/// Base class for custom exceptions in the `cbl` package.
abstract class CouchbaseLiteException implements Exception {
  /// A description of this exception.
  String get message;

  /// An optional error code specifies the cause of this exception.
  Object? get code => null;

  /// The [StackTrace] from the execution context where this exception
  /// originated from.
  ///
  /// When an exception originates in a different execution context than the
  /// current one, this property contains the original stack trace, if it is
  /// available.
  StackTrace? get remoteStackTrace => channel.remoteStackTrace(this);

  String get _typeName;

  @override
  String toString() {
    final code = this.code;
    return [
      '$_typeName(',
      [
        message,
        if (code != null) 'code: ${code is Enum ? code.name : code}',
      ].join(', '),
      ')'
    ].join();
  }
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
  String get _typeName => 'DatabaseException';
}

/// An exception that is thrown when a POSIX error code is received during
/// operation.
///
/// The error [code] is dependent on the OS being run on and is defined in the
/// `errno.h` header file.
class PosixException extends CouchbaseLiteException {
  PosixException(this.message, this.code);

  @override
  final String message;

  @override
  final int code;

  @override
  String get _typeName => 'PosixException';
}

/// An exception used to indicate a SQLite operation error.
///
/// The meaning of the error [code] is defined in the
/// [SQLite documentation](https://www.sqlite.org/rescode.html).
class SQLiteException extends CouchbaseLiteException {
  SQLiteException(this.message, this.code);

  @override
  final String message;

  @override
  final int code;

  @override
  String get _typeName => 'SQLiteException';
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
  String get _typeName => 'NetworkException';
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
  String get _typeName => 'HttpException';
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
  String get _typeName => 'WebSocketException';
}

/// Exception thrown when JSON data is invalid.
@Deprecated(
  'Use FleeceException instead. This class will be removed in the future.',
)
class InvalidJsonException extends CouchbaseLiteException {
  // ignore: deprecated_consistency
  /// Creates an exception which is thrown when JSON data is invalid.
  InvalidJsonException(this.message);

  @override
  final String message;

  @override
  String get _typeName => 'InvalidJsonException';
}

/// An exception that is thrown when a Fleece error is detected.
///
/// Fleece is the library used to serialize and deserialize data. This type of
/// exception should be reported.
// ignore: deprecated_member_use_from_same_package
class FleeceException extends InvalidJsonException {
  FleeceException(super.message);

  @override
  String get _typeName => 'FleeceException';
}

/// A specification of the cause of a [TypedDataException].
///
/// {@category Typed Data}
@experimental
enum TypedDataErrorCode {
  /// The database does not support typed data.
  typedDataNotSupported,

  /// The type is not a known typed data type.
  unknownType,

  /// There is a conflict matching raw data with known typed data types.
  typeMatchingConflict,

  /// A typed data type cannot be resolved for the raw data.
  unresolvableType,

  /// The raw data does not have the expected structure.
  dataMismatch,
}

/// Exception throw when there is a failure related to typed data.
///
/// {@category Typed Data}
@experimental
class TypedDataException extends CouchbaseLiteException {
  /// Creates an exception which is throw when there is a failure related to
  /// typed data.
  TypedDataException(this.message, this.code, [this.originalException]);

  @override
  final String message;

  @override
  final TypedDataErrorCode code;

  final Object? originalException;

  @override
  String get _typeName => 'TypedDataException';
}
