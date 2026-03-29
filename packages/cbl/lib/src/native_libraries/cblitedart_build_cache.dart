import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:path/path.dart' as p;

import 'package.dart';

Future<void> buildCblitedartAsset({
  required BuildInput input,
  required BuildOutputBuilder output,
  required String cbliteIncludeDir,
  String? cbliteFrameworkSearchPath,
  required Edition edition,
}) async {
  final targetOS = input.config.code.targetOS;
  final builder = CBuilder.library(
    name: 'cblitedart',
    assetName: 'src/bindings/cblitedart.dart',
    sources: [
      'native/couchbase-lite-dart/src/CBL+Dart.cpp',
      'native/couchbase-lite-dart/src/Fleece+Dart.cpp',
      'native/couchbase-lite-dart/src/AsyncCallback.cpp',
      'native/couchbase-lite-dart/src/Utils.cpp',
      'native/couchbase-lite-dart/src/CpuSupport.cpp',
      'native/couchbase-lite-dart/src/dart_api_dl.cpp',
    ],
    includes: [
      'native/vendor/dart/include',
      'native/couchbase-lite-dart/include',
    ],
    libraries: [if (targetOS != OS.iOS) 'cblite'],
    libraryDirectories: [if (targetOS != OS.iOS) 'lib'],
    flags: [
      if (targetOS == OS.windows) '/Z7' else '-g',
      if (targetOS != OS.windows) '-fvisibility=hidden',
      '-I$cbliteIncludeDir',
      if (targetOS == OS.iOS) ...[
        '-F${cbliteFrameworkSearchPath!}',
        '-framework',
        'CouchbaseLite',
      ],
    ],
    defines: {if (edition == Edition.enterprise) 'COUCHBASE_ENTERPRISE': '1'},
    language: Language.cpp,
    std: 'c++17',
    cppLinkStdLib: targetOS == OS.android ? 'c++_static' : null,
  );
  await builder.run(input: input, output: output);
}

Iterable<FileSystemEntity> findDebugCompanions(File binaryFile) sync* {
  final dir = binaryFile.parent;
  final baseName = p.basenameWithoutExtension(binaryFile.path);
  for (final entity in dir.listSync()) {
    final name = p.basename(entity.path);
    if (name == p.basename(binaryFile.path)) {
      continue;
    }
    if (entity is File && name.startsWith(baseName)) {
      yield entity;
    }
    if (entity is Directory &&
        name.contains(baseName) &&
        name.endsWith('.dSYM')) {
      yield entity;
    }
  }
}
