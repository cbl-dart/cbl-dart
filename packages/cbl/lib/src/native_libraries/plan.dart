import 'dart:io';

import 'package:args/args.dart';
import 'package:code_assets/code_assets.dart';
import 'package:path/path.dart' as p;

import 'hook_defaults.dart';
import 'package.dart';
import 'target_matrix.dart';

final class AssembledLibraryTarget {
  AssembledLibraryTarget({
    required this.os,
    required this.architecture,
    this.iOSSdk,
  });

  final OS os;
  final Architecture architecture;
  final IOSSdk? iOSSdk;
}

final class NativeLibraryRequest {
  NativeLibraryRequest({
    required this.editions,
    required this.vectorSearch,
    required this.outputDirectory,
    this.platforms,
    this.architectures,
    this.baseDirectory,
  });

  final Set<Edition> editions;
  final bool vectorSearch;
  final String outputDirectory;
  final Set<OS>? platforms;
  final Set<Architecture>? architectures;
  final Directory? baseDirectory;
}

final class ResolvedNativeLibraryTarget {
  ResolvedNativeLibraryTarget({required this.edition, required this.target});

  final Edition edition;
  final AssembledLibraryTarget target;

  String outputDirectory(String rootDirectory) => p.join(
    rootDirectory,
    edition.name,
    target.os.name,
    target.architecture.name,
  );
}

final class ResolvedNativeLibrariesPlan {
  ResolvedNativeLibrariesPlan({
    required this.outputDirectory,
    required this.vectorSearch,
    required this.targets,
  });

  final String outputDirectory;
  final bool vectorSearch;
  final List<ResolvedNativeLibraryTarget> targets;
}

NativeLibraryRequest applyCliOverrides(
  NativeLibraryDefaults defaults,
  ArgResults parsed,
) {
  final editionValues = parsed['edition'] as List<String>;
  final platformValues = parsed['platform'] as List<String>;
  final architectureValues = parsed['architecture'] as List<String>;

  return NativeLibraryRequest(
    editions: editionValues.isNotEmpty
        ? editionValues.map(parseEdition).toSet()
        : defaults.editions,
    vectorSearch: (parsed['vector-search'] as bool?) ?? defaults.vectorSearch,
    outputDirectory: Directory(parsed['output'] as String).absolute.path,
    platforms: platformValues.isEmpty
        ? null
        : platformValues
              .map(
                (value) => OS.values.firstWhere(
                  (candidate) => candidate.name == value,
                ),
              )
              .toSet(),
    architectures: architectureValues.isEmpty
        ? null
        : architectureValues
              .map(
                (value) => Architecture.values.firstWhere(
                  (candidate) => candidate.name == value,
                ),
              )
              .toSet(),
    baseDirectory: defaults.baseDirectory,
  );
}

ResolvedNativeLibrariesPlan resolveNativeLibrariesPlan(
  NativeLibraryRequest request,
) {
  final platforms = request.platforms ?? {currentHostOS()};
  _validateNativeLibraryRequest(request, platforms);

  final targets = <ResolvedNativeLibraryTarget>[];
  for (final edition in request.editions) {
    for (final platform in platforms) {
      final architectures =
          request.architectures ?? supportedArchitecturesForAssembly(platform);
      for (final architecture in architectures) {
        final iOSSdk = platform == OS.iOS
            ? _defaultIOSSdkForAssembly(architecture)
            : null;
        targets.add(
          ResolvedNativeLibraryTarget(
            edition: edition,
            target: AssembledLibraryTarget(
              os: platform,
              architecture: architecture,
              iOSSdk: iOSSdk,
            ),
          ),
        );
      }
    }
  }

  return ResolvedNativeLibrariesPlan(
    outputDirectory: request.outputDirectory,
    vectorSearch: request.vectorSearch,
    targets: targets,
  );
}

void _validateNativeLibraryRequest(
  NativeLibraryRequest request,
  Set<OS> platforms,
) {
  validateNativeLibraryConfiguration(
    editions: request.editions,
    vectorSearch: request.vectorSearch,
  );

  for (final platform in platforms) {
    final supportedArchitectures = supportedArchitecturesForAssembly(platform);
    final requestedArchitectures =
        request.architectures ?? supportedArchitectures;
    final unsupportedArchitectures = requestedArchitectures.difference(
      supportedArchitectures,
    );
    if (unsupportedArchitectures.isNotEmpty) {
      throw ArgumentError(
        'Unsupported architectures for ${platform.name}: '
        '${unsupportedArchitectures.map((it) => it.name).join(', ')}.',
      );
    }
  }
}

IOSSdk _defaultIOSSdkForAssembly(Architecture architecture) {
  if (architecture == Architecture.x64) {
    return IOSSdk.iPhoneSimulator;
  }
  return IOSSdk.iPhoneOS;
}
