import 'dart:isolate';

import 'bindings.dart';
import 'database/database.dart';
import 'log.dart';
import 'support/isolate.dart';
import 'support/tracing.dart';
import 'tracing.dart';

export 'bindings.dart' show LibrariesConfiguration, LibraryConfiguration;
export 'support/listener_token.dart' show ListenerToken;
export 'support/resource.dart' show Resource, ClosableResource;
export 'support/streams.dart' show AsyncListenStream;

// ignore: avoid_classes_with_only_static_members
/// Initializes global resources and configures global settings, such as
/// logging.
abstract final class CouchbaseLite {
  /// Initializes the `cbl` package, for the main isolate.
  static Future<void> init({
    required LibrariesConfiguration libraries,
    bool autoEnableVectorSearch = true,
  }) => asyncOperationTracePoint(InitializeOp.new, () async {
    await initPrimaryIsolate(
      IsolateContext(libraries: libraries),
      autoEnableVectorSearch: autoEnableVectorSearch,
    );

    _setupLogging();
  });

  /// Context object to pass to [initSecondary], when initializing a secondary
  /// [Isolate].
  ///
  /// This object can be safely passed from one [Isolate] to another.
  static Object get context => IsolateContext.instance;

  /// Initializes the `cbl` package, for a secondary isolate.
  ///
  /// A value for [context] can be obtained from [CouchbaseLite.context].
  static Future<void> initSecondary(Object context) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        if (context is! IsolateContext) {
          throw ArgumentError.value(context, 'context', 'is invalid');
        }

        await initSecondaryIsolate(context);
      });
}

void _setupLogging() {
  Database.log.console.level = LogLevel.warning;
}
