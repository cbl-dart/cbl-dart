import 'package:cbl_flutter_platform_interface/cbl_flutter_platform_interface.dart';
import 'package:cbl_flutter_platform_interface/standard_cbl_flutter_platform.dart';

// ignore: avoid_classes_with_only_static_members
class CblFlutterLocal {
  static void registerWith() {
    CblFlutterPlatform.instance =
        StandardCblFlutterPlatform(enterpriseEdition: true);
  }
}
