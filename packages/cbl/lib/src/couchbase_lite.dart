import 'dart:isolate';

import 'database/database.dart';
import 'log.dart';
import 'support/ffi.dart';
import 'support/isolate.dart';

export 'support/ffi.dart' show Libraries, LibraryConfiguration;
export 'support/listener_token.dart' show ListenerToken;
export 'support/resource.dart' show Resource, ClosableResource;
export 'support/streams.dart' show AsyncListenStream;

/// Initializes global resources and configures global settings, such as
/// logging.
class CouchbaseLite {
  /// Private constructor to allow control over instance creation.
  CouchbaseLite._();

  /// Initializes the `cbl` package, for the main isolate.
  static void init({required Libraries libraries}) {
    initMainIsolate(IsolateContext(libraries: libraries));

    _setupLogging();
  }

  /// Context object to pass to [initSecondary], when initializing a secondary
  /// [Isolate].
  ///
  /// This object can be safely passed from one [Isolate] to another.
  Object get context => IsolateContext.instance;

  /// Initializes the `cbl` package, for a secondary isolate.
  ///
  /// A value for [context] can be obtained from [CouchbaseLite.context].
  static void initSecondary(Object context) {
    if (context is! IsolateContext) {
      throw ArgumentError.value(context, 'context', 'is invalid');
    }

    initIsolate(context);
  }
}

void _setupLogging() {
  Database.log.console.level = LogLevel.warning;
}
