import 'dart:io';

import 'package:code_assets/code_assets.dart';

bool vectorSearchSupported(Architecture architecture) =>
    architecture != Architecture.arm && architecture != Architecture.ia32;

bool canBuildLocally(OS os, Architecture architecture) => switch (os) {
  OS.android => Platform.isMacOS || Platform.isLinux || Platform.isWindows,
  OS.iOS => Platform.isMacOS && architecture != Architecture.ia32,
  OS.macOS => Platform.isMacOS && architecture != Architecture.ia32,
  OS.linux => Platform.isLinux && architecture != Architecture.ia32,
  OS.windows => Platform.isWindows && architecture != Architecture.ia32,
  _ => false,
};

Set<Architecture> supportedArchitecturesForAssembly(OS os) => switch (os) {
  OS.android => {
    Architecture.arm,
    Architecture.arm64,
    Architecture.ia32,
    Architecture.x64,
  },
  OS.iOS => {Architecture.arm64, Architecture.x64},
  OS.macOS => {Architecture.arm64, Architecture.x64},
  OS.linux => {Architecture.arm64, Architecture.x64},
  OS.windows => {Architecture.arm64, Architecture.x64},
  _ => throw UnsupportedError('Unsupported OS: $os'),
};

OS currentHostOS() => OS.current;

Architecture currentHostArchitecture() => Architecture.current;

List<Architecture> cbliteArchitectures(OS os, Architecture architecture) =>
    switch (os) {
      OS.macOS || OS.iOS => [Architecture.x64, Architecture.arm64],
      OS.android => [
        architecture,
        if (architecture != Architecture.x64)
          Architecture.x64
        else
          Architecture.arm64,
      ],
      _ => [architecture],
    };

List<Architecture> vectorSearchArchitectures(
  OS os,
  Architecture architecture,
) => switch (os) {
  OS.iOS || OS.macOS => [Architecture.x64, Architecture.arm64],
  _ => [architecture],
};
