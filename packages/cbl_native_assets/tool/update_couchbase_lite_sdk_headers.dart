import 'package:cbl_native_assets/src/version.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import '../hook/cblite_package.dart';

void main() async {
  final package = CblitePackage.forOS(
    OS.macOS,
    version: cbliteVersion,
    edition: CbliteEdition.community,
  ).single;

  await package.installHeaders(
    Uri.file('src/vendor/cblite/include'),
    Logger('')
      ..level = Level.ALL
      // ignore: avoid_print
      ..onRecord.listen((record) => print(record.message)),
  );
}
