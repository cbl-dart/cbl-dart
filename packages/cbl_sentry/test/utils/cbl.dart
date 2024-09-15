import 'package:cbl/cbl.dart';

Future<void> initCouchbaseLiteForTest() async {
  await CouchbaseLite.init();
}
