import 'package:meta/meta.dart';

/// Whether CBL Dart trace points should be included when compiling a Dart
/// program.
///
/// Since this value is a compile time constant, code branches based on this
/// value will be compiled out when not needed.
///
/// Functions which use this value should be annotated with
/// `@pragma('vm:prefer-inline')`, to make trace points a zero-cost abstraction
/// when `--define=cblIncludeTracePoints=false` is set.
///
/// This value is set to `true` by default.
const cblIncludeTracePoints =
    // ignore: do_not_use_environment
    bool.fromEnvironment('cblIncludeTracePoints', defaultValue: true);

@sealed
class TracedNativeCall {
  const TracedNativeCall(this.symbol);

  final String symbol;

  static const databaseOpen = TracedNativeCall('CBLDart_CBLDatabase_Open');
  static const databaseClose = TracedNativeCall('CBLDart_CBLDatabase_Close');
  static const databaseGetDocument =
      TracedNativeCall('CBLDart_CBLDatabase_GetDocument');
  static const databaseGetMutableDocument =
      TracedNativeCall('CBLDart_CBLDatabase_GetMutableDocument');
  static const databaseSaveDocument = TracedNativeCall(
    'CBLDart_CBLDatabase_SaveDocumentWithConcurrencyControl',
  );
  static const databaseDeleteDocument = TracedNativeCall(
    'CBLDatabase_DeleteDocumentWithConcurrencyControl',
  );
  static const databaseGetBlob = TracedNativeCall('CBLDatabase_GetBlob');
  static const databaseSaveBlob = TracedNativeCall('CBLDatabase_SaveBlob');
  static const queryCreate =
      TracedNativeCall('CBLDart_CBLDatabase_CreateQuery');
  static const queryExecute = TracedNativeCall('CBLQuery_Execute');
}

typedef TracedCallHandler = T Function<T>(
  TracedNativeCall call,
  T Function() execute,
);

T noopTracedCallHandler<T>(
  TracedNativeCall call,
  T Function() execute,
) =>
    execute();

TracedCallHandler onTracedCall = noopTracedCallHandler;

/// Traces a function as a [TracedNativeCall].
///
/// The given function is not be wrapped in a try-catch block and is
/// expected to return normally.
@pragma('vm:prefer-inline')
T nativeCallTracePoint<T>(TracedNativeCall call, T Function() execute) {
  if (!cblIncludeTracePoints) {
    return execute();
  }

  return onTracedCall(call, execute);
}
