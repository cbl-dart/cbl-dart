// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// This script symbolicates Crashlytics stack traces that come from Android
/// devices.
///
/// It requires as its input:
///
/// - path to a Android NDK.
/// - path to the directory which contains unstripped libraries to use when
///   symbolicating frames.
/// - path to a file containing the stack trace to symbolicate.
/// - path to a file to write the symbolicated stack trace to.
void main(List<String> args) {
  if (args.length != 4) {
    print(
      'Usage: dart tools/android_crashlytics_stack.dart '
      '<ndk-dir> <lib-dir> <input> <output>',
    );
    exit(1);
  }

  final ndkDir = args[0];
  final libDir = args[1];
  final inputFile = File(args[2]);
  final outputFile = File(args[3]);

  final output = _symbolicateStackTrace(
    inputFile.readAsStringSync(),
    addressSymbolizer: _createAddressSymbolizer(
      ndkDir: ndkDir,
      libDir: libDir,
    ),
  );

  outputFile
    ..createSync(recursive: true)
    ..writeAsStringSync(output);
}

final _frameRegex =
    RegExp(r'^#\d+\s+pc\s+(?<addr>0x[0-9a-fA-F]+)\s+(?<lib>\S+)\s+$');

String _symbolicateStackTrace(
  String stackTrace, {
  required _AddressSymbolizer addressSymbolizer,
}) {
  final lines = stackTrace.split('\n');
  final output = <String>[];

  for (final line in lines) {
    output.add(line);

    final match = _frameRegex.firstMatch(line);
    if (match == null) {
      continue;
    }

    final addr = match.namedGroup('addr')!;
    final lib = match.namedGroup('lib')!;
    final symbol = addressSymbolizer(addr, lib);
    if (symbol != null) {
      output.add(symbol);
      continue;
    }
  }

  return output.join('\n');
}

typedef _AddressSymbolizer = String? Function(String address, String lib);

_AddressSymbolizer _createAddressSymbolizer({
  required String ndkDir,
  required String libDir,
}) {
  final addr2LineBin = _addr2lineBin(ndkDir);
  return (address, lib) {
    final libPath = p.join(libDir, lib);
    final libFile = File(libPath);
    if (!libFile.existsSync()) {
      return null;
    }

    final result = Process.runSync(
      addr2LineBin,
      ['-C', '--functions', '-e', libPath, address],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      throw Exception(
        'addr2line failed (${result.exitCode}):\n'
        '${result.stdout}\n'
        '${result.stderr}',
      );
    }

    return (result.stdout as String).trim();
  };
}

String _addr2lineBin(String ndkDir) {
  final buildForHostDir = _llvmToolchainDir(ndkDir);
  return p.join(buildForHostDir, 'bin', 'llvm-addr2line');
}

String _llvmToolchainDir(String ndkDir) {
  final llvmPrebuiltToolchainsDir =
      Directory(p.join(ndkDir, 'toolchains', 'llvm', 'prebuilt'));
  // The dir only contains one directory with the name of the host platform.
  return llvmPrebuiltToolchainsDir.listSync().first.path;
}
