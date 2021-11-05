// ignore_for_file: avoid_classes_with_only_static_members

import 'package:cbl_flutter_platform_interface/cbl_flutter_platform_interface.dart';
import 'package:cbl_flutter_platform_interface/standard_cbl_flutter_platform.dart';

/// Platform implementation of `cbl_flutter` for the Community Edition.
class CblFlutterCe {
  /// Registers this platform implementation as the current implementation.
  static void registerWith() {
    CblFlutterPlatform.instance =
        StandardCblFlutterPlatform(enterpriseEdition: false);
  }
}
