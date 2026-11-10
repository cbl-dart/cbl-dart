import 'dart:convert';
import 'dart:io';

import 'SOURCE_URI' as dl;

Future<void> main() async {
  final env = Platform.environment;
  if ((env['CACHE_HIT'] == 'true') != (env['BENCH_PHASE'] == 'warm')) {
    throw StateError('Unexpected cache state for ${env['BENCH_PHASE']}');
  }
  final target = env['BENCH_TARGET']!;
  final os = target == 'linux-x64' ? dl.OS.linux : dl.OS.android;
  final cblRelease = env['CBL_RELEASE']!;
  final vectorRelease = env['VS_RELEASE']!;
  final cacheRoot = env['SDK_CACHE_ROOT']!;
  final before = ProcessInfo.currentRss;
  final total = Stopwatch()..start();
  final rows = <Map<String, Object>>[];
  final configs = <(String, dl.PackageConfig)>[
    (
      'cblite-enterprise-${os.name}-x64-$cblRelease',
      dl.DatabasePackageConfig(
        os: os,
        architectures: os == dl.OS.android
            ? [dl.Architecture.x64, dl.Architecture.arm64]
            : [dl.Architecture.x64],
        release: cblRelease,
        archiveFormat: os == dl.OS.linux
            ? dl.ArchiveFormat.tarGz
            : dl.ArchiveFormat.zip,
        edition: dl.Edition.enterprise,
      ),
    ),
    (
      'vector-search-${os.name}-x64-$vectorRelease',
      dl.VectorSearchPackageConfig(
        os: os,
        architectures: [dl.Architecture.x64],
        release: vectorRelease,
      ),
    ),
  ];
  for (final (folder, config) in configs) {
    final timer = Stopwatch()..start();
    final package = await dl.RemotePackageLoader(cacheDir: '$cacheRoot/$folder')
        .load(config);
    timer.stop();
    final library = File(
      '${package.sharedLibrariesDir}/${package.libraryName}.so',
    );
    final bytes = await library
        .openRead(0, 20)
        .fold<List<int>>([], (buffer, next) => buffer..addAll(next));
    if (bytes.length < 20 || bytes[0] != 0x7f || bytes[18] != 62) {
      throw StateError('Wrong target library: ${library.path}');
    }
    rows.add({
      'library': config.library.name,
      'release': config.release,
      'seconds': timer.elapsedMicroseconds / 1000000,
      'libraryPath': library.path,
      'libraryBytes': await library.length(),
    });
  }
  total.stop();
  final result = {
    'target': target,
    'phase': env['BENCH_PHASE'],
    'cache_hit': env['CACHE_HIT'] == 'true',
    'dart': Platform.version,
    'production_loader_sha256': env['LOADER_SHA256'],
    'archive_version': env['ARCHIVE_VERSION'],
    'source_hook_sha256': env['HOOK_SHA256'],
    'total_seconds': total.elapsedMicroseconds / 1000000,
    'rss_before_bytes': before,
    'rss_after_bytes': ProcessInfo.currentRss,
    'maximum_rss_bytes': ProcessInfo.maxRss,
    'libraries': rows,
  };
  await File(env['RESULT_PATH']!)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln(jsonEncode(result));
}
