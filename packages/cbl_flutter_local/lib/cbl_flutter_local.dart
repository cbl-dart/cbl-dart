import 'package:cbl_flutter_platform_interface/cbl_flutter_platform_interface.dart';
import 'package:cbl_flutter_platform_interface/standard_cbl_flutter_platform.dart';

abstract final class CblFlutterLocal {
  static void registerWith() {
    CblFlutterPlatform.instance = StandardCblFlutterPlatform(
      enterpriseEdition: true,
    );
  }
}
