import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:cbl/cbl.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'cbl_e2e_tests/test_binding.dart';

void setupTestBinding() {
  StandaloneDartCblE2eTestBinding.ensureInitialized();
}

class StandaloneDartCblE2eTestBinding extends CblE2eTestBinding {
  static void ensureInitialized() {
    CblE2eTestBinding.ensureInitialized(
        () => StandaloneDartCblE2eTestBinding());
  }

  @override
  FutureOr<void> initCouchbaseLite() {
    CouchbaseLite.init(libraries: _libraries());
  }

  @override
  String resolveTmpDir() => p.absolute(p.join('test', '.tmp'));
}

Libraries _libraries() {
  const enterpriseEdition = true;
  final libDir = p.absolute('lib');
  final binDir = p.absolute('bin');
  final frameworksDir = p.absolute('Frameworks');

  String findLibInFrameworks(String name) =>
      '$frameworksDir/$name.framework/Versions/A/$name';

  late String cblLib;
  late String cblDartLib;
  var appendExtension = true;
  String? cblVersion;

  final isUnix = Platform.isLinux || Platform.isMacOS;

  if (isUnix && FileSystemEntity.isDirectorySync(libDir)) {
    cblLib = p.join(libDir, 'libcblite');
    cblDartLib = p.join(libDir, 'libcblitedart');
    // TODO(blaugold): remove version when symlinks in macOS release are fixed
    cblVersion = '3';
  } else if (Platform.isMacOS) {
    cblLib = findLibInFrameworks('CouchbaseLite');
    cblDartLib = findLibInFrameworks('CouchbaseLiteDart');
    appendExtension = false;
  } else if (Platform.isWindows) {
    final kernel32 = DynamicLibrary.open('Kernel32.dll');
    final SetDllDirectory = kernel32.lookupFunction<
        Uint8 Function(Pointer<Utf16>),
        int Function(Pointer<Utf16>)>('SetDllDirectoryW');
    if (SetDllDirectory(binDir.toNativeUtf16()) == 0) {
      throw Exception('Failed to set DLL directory to $binDir');
    }

    cblLib = p.join(binDir, 'cblite');
    cblDartLib = p.join(binDir, 'cblitedart');
  } else {
    throw StateError('Could not find libraries for current platform');
  }

  return Libraries(
    enterpriseEdition: enterpriseEdition,
    cbl: LibraryConfiguration.dynamic(
      cblLib,
      version: cblVersion,
      appendExtension: appendExtension,
    ),
    cblDart: LibraryConfiguration.dynamic(
      cblDartLib,
      appendExtension: appendExtension,
    ),
  );
}
