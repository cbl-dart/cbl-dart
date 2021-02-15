import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:cbl_e2e_tests/cbl_e2e_tests.dart';
import 'package:path/path.dart' as p;

class StandaloneDartCblE2eTestBindings extends CblE2eTestBindings {
  @override
  Libraries get libraries => _isCi ? _ciLibraries() : _devLibraries();

  /// The [Libraries] to use when running tests during development.
  Libraries _devLibraries() {
    final buildDir = '../../build';
    final cblLib = '$buildDir/vendor/couchbase-lite-C/libCouchbaseLiteC';
    final cblDartLib = '$buildDir/cbl-dart/libCouchbaseLiteDart';
    return Libraries(
      cbl: LibraryConfiguration.dynamic(cblLib),
      cblDart: LibraryConfiguration.dynamic(cblDartLib),
    );
  }

  /// The [Libraries] to use when running tests as part of CI.
  Libraries _ciLibraries() {
    final libsDIr = p.absolute('../../libs');
    final frameworksDir = p.absolute('../../Frameworks');

    String findLibInFrameworks(String name) =>
        '$frameworksDir/$name.framework/Versions/A/$name';

    late String cblLib;
    late String cblDartLib;

    if (Platform.isLinux) {
      cblLib = '$libsDIr/libCouchbaseLiteC';
      cblDartLib = '$libsDIr/libCouchbaseLiteDart';

      return Libraries(
        cbl: LibraryConfiguration.dynamic(cblLib),
        cblDart: LibraryConfiguration.dynamic(cblDartLib),
      );
    } else if (Platform.isMacOS) {
      cblLib = findLibInFrameworks('CouchbaseLite');
      cblDartLib = findLibInFrameworks('CouchbaseLiteDart');

      return Libraries(
        cbl: LibraryConfiguration.dynamic(
          cblLib,
          appendExtension: false,
        ),
        cblDart: LibraryConfiguration.dynamic(
          cblDartLib,
          appendExtension: false,
        ),
      );
    } else {
      throw UnimplementedError();
    }
  }

  /// `true` if tests are running as part of CI.
  final _isCi = Platform.environment.containsKey('CI');

  @override
  String get tmpDirectory => './test/.tmp';
}

void main() {
  cblE2eTests(StandaloneDartCblE2eTestBindings());
}
