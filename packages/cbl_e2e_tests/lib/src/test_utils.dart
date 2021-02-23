/// Delays async execution by [ms] milliseconds.
Future<void> delay({required int ms}) =>
    Future<void>.delayed(Duration(microseconds: ms));

/// Change streams are created asynchronously on the native side and need some
/// time before changes can be observed.
Future<void> waitForChangeStream() => delay(ms: 50);
