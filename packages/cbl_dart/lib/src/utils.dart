import 'dart:async';

import 'package:logging/logging.dart';

/// Whether to enable logging to debug issues specific to `cbl_dart`.
bool get debugLoggingEnabled => _debugLoggingSubscription != null;

// ignore: avoid_positional_boolean_parameters
set debugLoggingEnabled(bool value) {
  if (debugLoggingEnabled == value) {
    return;
  }
  if (value) {
    _enableDebugLogging();
  } else {
    _disableDebugLogging();
  }
}

StreamSubscription? _debugLoggingSubscription;

void _enableDebugLogging() {
  logger.level = Level.FINE;
  _debugLoggingSubscription = logger.onRecord.listen((record) {
    // ignore: avoid_print
    print(record.message);
  });
}

void _disableDebugLogging() {
  logger.level = Level.OFF;
  _debugLoggingSubscription?.cancel();
  _debugLoggingSubscription = null;
}

final logger = Logger.detached('cbl_dart');

extension EnumNameExt on Enum {
  String get name => toString().split('.').last;
}
