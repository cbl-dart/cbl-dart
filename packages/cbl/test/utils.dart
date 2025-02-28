import 'dart:io';

import 'package:test/test.dart';

Directory tempTestDirectory() {
  final directory = Directory.systemTemp.createTempSync();
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}
