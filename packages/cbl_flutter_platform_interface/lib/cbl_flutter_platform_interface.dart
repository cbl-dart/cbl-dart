import 'package:cbl/cbl.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Plugin platform interface for `cbl_flutter`.
///
/// Platform implementations must bundle the native libraries (`cblite` and
/// `cblitedart`) and return the configuration to access them from [libraries].
abstract class CblFlutterPlatform extends PlatformInterface {
  CblFlutterPlatform() : super(token: _token);

  static CblFlutterPlatform? _instance;

  static final Object _token = Object();

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
  static set instance(CblFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the [LibrariesConfiguration] provided by this plugin for the
  /// current platform.
  LibrariesConfiguration libraries();
}
