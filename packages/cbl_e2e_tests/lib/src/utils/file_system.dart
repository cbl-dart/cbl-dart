import 'dart:io';

import 'package:collection/collection.dart';

extension DirectoryExt on Directory {
  Future<String?> findAndReadFile(bool Function(File) fn) async {
    final entries = await list().toList();
    final file = entries.whereType<File>().firstWhereOrNull(fn);
    if (file is File) {
      return file.readAsString();
    }
    return null;
  }

  Future<void> reset() async {
    if (await exists()) {
      await delete(recursive: true);
    }
    await create(recursive: true);
  }
}
