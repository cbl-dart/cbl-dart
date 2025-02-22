// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/install.dart';
import 'package:cbl/src/support/isolate.dart';
import 'package:cbl/src/support/tracing.dart';

import 'src/acquire_libraries.dart';

export 'package:cbl/src/install.dart' show Edition;

// ignore: avoid_classes_with_only_static_members
/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite in pure Dart apps.
abstract final class CouchbaseLiteDart {
  /// Initializes the `cbl` package, for the main isolate.
  ///
  /// If specified, [filesDir] is used to store files created by Couchbase Lite
  /// by default. For example if a [Database] is opened or copied without
  /// specifying a [DatabaseConfiguration.directory], a subdirectory in the
  /// directory specified here will be used. If no [filesDir] directory is
  /// provided, the working directory is used when opening and copying
  /// databases.
  ///
  /// If the native libraries have not been downloaded yet, this method will
  /// download them and store them in [nativeLibrariesDir]. If no directory is
  /// provided, a system-wide default directory will be used.
  /// [nativeLibrariesDir] should be within the directory where apps should
  /// store cached data on the current platform.
  static Future<void> init({
    required Edition edition,
    String? filesDir,
    String? nativeLibrariesDir,
    bool autoEnableVectorSearch = true,
  }) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        final context = filesDir == null ? null : await _initContext(filesDir);

        final libraries = await acquireLibraries(
          edition: edition,
          mergedNativeLibrariesDir: nativeLibrariesDir,
        );

        await initPrimaryIsolate(
          IsolateContext(
            initContext: context,
            libraries: libraries,
          ),
          autoEnableVectorSearch: autoEnableVectorSearch,
        );
      });

  /// Initializes the `cbl` package for the main isolate using pre-bundled
  /// libraries from local assets.
  ///
  /// This initialization method is designed for environments where downloading
  /// native libraries at runtime is not desired or possible. Instead, it expects
  /// the required native libraries to be pre-bundled with the application.
  ///
  /// The [binaryDependencies] parameter specifies the root directory containing
  /// the pre-bundled native libraries. These libraries must be organized in a
  /// platform-specific directory structure that matches what Couchbase Lite
  /// expects.
  ///
  /// The [edition] parameter determines which edition of Couchbase Lite to
  /// initialize (Enterprise or Community).
  ///
  /// If specified, [filesDir] is used to store files created by Couchbase Lite
  /// by default. For example, if a [Database] is opened or copied without
  /// specifying a [DatabaseConfiguration.directory], a subdirectory in the
  /// directory specified here will be used. If no [filesDir] directory is
  /// provided, the working directory is used when opening and copying databases.
  ///
  /// The [skipVectorSearch] parameter allows disabling vector search
  /// capabilities. By default, vector search is enabled (skipVectorSearch =
  /// false). Set to true to disable vector search functionality.
  ///
  /// Throws an exception if the required native libraries are not found in the
  /// expected locations within [binaryDependencies].
  static Future<void> initWithLocalBinaryDependencies({
    required Directory binaryDependencies,
    required Edition edition,
    String? filesDir,
    bool skipVectorSearch = false,
  }) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        final context = filesDir == null ? null : await _initContext(filesDir);

        final config = LocalAssetsConfiguration(
          binaryDependencies: binaryDependencies,
          edition: edition,
          skipVectorSearch: skipVectorSearch,
        )..verifyLibrariesExist();

        await initPrimaryIsolate(
          IsolateContext(
            initContext: context,
            libraries: config.toLibrariesConfiguration(),
          ),
          autoEnableVectorSearch: !skipVectorSearch,
        );
      });
}

Future<InitContext> _initContext(String filesDir) async {
  await Directory(filesDir).create(recursive: true);
  return InitContext(filesDir: filesDir, tempDir: filesDir);
}
