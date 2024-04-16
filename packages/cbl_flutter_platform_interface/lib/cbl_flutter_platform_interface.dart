import 'package:cbl/cbl.dart';

/// Plugin platform interface for `cbl_flutter`.
///
/// Platform implementations must bundle the native libraries (`cblite` and
/// `cblitedart`) and return the configuration to access them from [libraries].
abstract base class CblFlutterPlatform {
  static CblFlutterPlatform? _instance;

  static CblFlutterPlatform get instance {
    final instance = _instance;

    if (instance == null) {
      throw StateError(
        'No cbl_flutter platform implementation has been registered. '
        'Ensure you have added cbl_flutter_ce or cbl_flutter_ee as a '
        'dependency.',
      );
    }

    return instance;
  }

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [CblFlutterPlatform] when they register themselves.
  static set instance(CblFlutterPlatform instance) => _instance = instance;

  /// Returns the [LibrariesConfiguration] provided by this plugin for the
  /// current platform.
  LibrariesConfiguration libraries();
}
