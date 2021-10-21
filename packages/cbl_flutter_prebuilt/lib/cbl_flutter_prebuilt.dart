import 'src/build_package.dart';
import 'src/configuration.dart';

Future<void> buildPackages() =>
    Future.wait(packageConfigurations.map(buildPackage));
