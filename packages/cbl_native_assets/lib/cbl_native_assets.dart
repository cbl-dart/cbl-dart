// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/bindings/cblite_native_assets_bridge.dart';
import 'package:cbl/src/bindings/cblitedart_native_assets_bridge.dart';
import 'package:cbl/src/support/isolate.dart';
import 'package:cbl/src/support/tracing.dart';

// ignore: avoid_classes_with_only_static_members
/// Initializes global resources and configures global settings, such as
/// logging, for usage of Couchbase Lite..
abstract final class CouchbaseLiteNativeAssets {
  /// Initializes the `cbl` package, for the main isolate.
  ///
  /// If specified, [filesDir] is used to store files created by Couchbase Lite
  /// by default. For example if a [Database] is opened or copied without
  /// specifying a [DatabaseConfiguration.directory], a subdirectory in the
  /// directory specified here will be used. If no [filesDir] directory is
  /// provided, the working directory is used when opening and copying
  /// databases.
  static Future<void> init({String? filesDir}) =>
      asyncOperationTracePoint(InitializeOp.new, () async {
        final context = filesDir == null ? null : await _initContext(filesDir);

        await initPrimaryIsolate(
          IsolateContext(
            initContext: context,
            bindings: CBLBindings(
              BindingsLibraries(
                enterpriseEdition: true,
                cblite: const cbliteNativeAssetsBridge(),
                cblitedart: const cblitedartNativeAssetsBridge(),
              ),
            ),
          ),
          autoEnableVectorSearch: false,
        );
      });
}

Future<InitContext> _initContext(String filesDir) async {
  await Directory(filesDir).create(recursive: true);
  return InitContext(filesDir: filesDir, tempDir: filesDir);
}
