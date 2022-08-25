import 'package:cbl_dart/cbl_dart.dart';
import 'package:cbl_dart/src/acquire_libraries.dart';

Future<void> initCouchbaseLiteForTest() async {
  await setupDevelopmentLibraries();
  await CouchbaseLiteDart.init(edition: Edition.enterprise);
}
