import 'package:cbl_native_assets/src/support/edition.dart';
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

import '../hook/build.dart';
import '../hook/cblite_package.dart';

void main() async {
  final package = CblitePackage.database(
    os: OS.macOS,
    edition: Edition.community,
    loader: remoteDatabaseArchiveLoader,
  ).single;

  await package.installHeaders(
    Uri.file('src/vendor/cblite/include'),
    Logger('')
      ..level = Level.ALL
      // ignore: avoid_print
      ..onRecord.listen((record) => print(record.message)),
  );
}
