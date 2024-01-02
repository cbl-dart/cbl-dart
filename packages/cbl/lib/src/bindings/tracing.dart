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

enum TracedNativeCall {
  databaseOpen('CBLDart_CBLDatabase_Open'),
  databaseClose('CBLDart_CBLDatabase_Close'),
  databaseBeginTransaction('CBLDatabase_BeginTransaction'),
  databaseEndTransaction('CBLDatabase_EndTransaction'),
  collectionGetDocument('CBLCollection_GetDocument'),
  collectionSaveDocument('CBLCollection_SaveDocumentWithConcurrencyControl'),
  collectionDeleteDocument(
    'CBLCollection_DeleteDocumentWithConcurrencyControl',
  ),
  databaseGetBlob('CBLDatabase_GetBlob'),
  databaseSaveBlob('CBLDatabase_SaveBlob'),
  queryCreate('CBLDatabase_CreateQuery'),
  queryExecute('CBLQuery_Execute');

  const TracedNativeCall(this.symbol);

  final String symbol;
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
/// The given function is not be wrapped in a try-catch block and is expected to
/// return normally.
@pragma('vm:prefer-inline')
T nativeCallTracePoint<T>(TracedNativeCall call, T Function() execute) {
  if (!cblIncludeTracePoints) {
    return execute();
  }

  return onTracedCall(call, execute);
}
