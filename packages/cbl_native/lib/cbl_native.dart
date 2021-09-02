// ignore_for_file: avoid_slow_async_io, avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';

/// GitHub repository data.
class GitHubRepo {
  GitHubRepo({
    required this.owner,
    required this.repo,
  });

  /// The username of the owner.
  final String owner;

  /// The repository name.
  final String repo;

  /// The url.
  late final Uri url = Uri.parse('https://github.com/$owner/$repo/');

  /// The url for releases.
  late final Uri releasesUrl = url.resolve('releases/');
}

/// GitHub release data.
class GitHubRelease {
  GitHubRelease({
    required this.repo,
    required this.tag,
  });

  /// The repository this release belongs to.
  final GitHubRepo repo;

  /// The git tag which identifies this release.
  final String tag;

  /// The url for downloads of assets.
  late final Uri downloadUrl = repo.releasesUrl.resolve('download/$tag/');
}

/// Platform for wich binaries are available.
enum Platform {
  linux,
  android,
  apple,
}

extension PlatformExt on Platform {
  String platformName() => toString().split('.')[1];
}

/// The `cbl-dart` GitHub repo.
final cblDartRepo = GitHubRepo(
  owner: 'cofu-app',
  repo: 'cbl-dart',
);

/// The current version of `cbl_native`.
const currentVersion = '5.0.0-beta.3'; // cbl_native: version

/// Binaries for `cbl_native` for one [Platform].
class CblNativeBinaries {
  CblNativeBinaries({
    required this.platform,
    this.version = currentVersion,
  });

  /// The name of the `cbl_native` package.
  final String packageName = 'cbl_native';

  /// The target platform of the binaries.
  final Platform platform;

  /// The version of the binaries.
  final String version;

  /// The release which contains the binaries
  late final release = GitHubRelease(
    repo: cblDartRepo,
    tag: '$packageName-v$version',
  );

  /// The filename of the binaries.
  late final String filename =
      '${release.tag}-${platform.platformName()}.tar.gz';

  /// The url to download the binaries.
  late final Uri url = release.downloadUrl.resolve(filename);

  /// Downloads and installs the binaries into [installDir].
  ///
  /// If the [installDir] already exists the method returns without doing
  /// anything. To removed it and installing the binaries, set [override] to
  /// `true`.
  Future<void> install({
    required Directory installDir,
    bool override = false,
  }) async {
    // Prepare install dir
    if (await installDir.exists()) {
      if (override) {
        await installDir.delete(recursive: true);
      } else {
        return;
      }
    }
    await installDir.create(recursive: true);

    // Download archive
    final archiveUri = await _downloadToTmpDir();

    // Extract archive to installDir
    final result = await Process.run(
      'tar',
      [
        '-xzf',
        fromUri(archiveUri),
        '-C',
        fromUri(installDir.uri),
      ],
    );

    if (result.exitCode != 0) {
      print('Could not extract contents of archive at $archiveUri');
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      exit(result.exitCode);
    }

    // Clean up downloaded archive
    await File.fromUri(archiveUri).delete();
  }

  Future<Uri> _downloadToTmpDir() async {
    final timestamp = DateTime.now();
    final downloadPath =
        File('./${timestamp.millisecondsSinceEpoch}-$filename').absolute.uri;

    await _retry<void>(
      () async {
        final response = await http.get(url);
        if (response.statusCode != 200) {
          throw HttpResponseException(response.statusCode, response.body);
        }

        await File.fromUri(downloadPath).writeAsBytes(response.bodyBytes);
      },
      retryIf: (e) =>
          e is SocketException ||
          (e is HttpResponseException &&
              [500, 503, 504].contains(e.statusCode)),
      onRetry: (error) {
        print('Retrying download of $filename: $error');
      },
    );

    return downloadPath;
  }
}

class HttpResponseException implements Exception {
  HttpResponseException(this.statusCode, this.body);

  final int statusCode;

  final String body;

  @override
  String toString() =>
      'HttpResponseException(statusCode: $statusCode, body: $body)';
}

Future<T> _retry<T>(
  FutureOr<T> Function() action, {
  required FutureOr<bool> Function(Object error) retryIf,
  required FutureOr<void> Function(Object error) onRetry,
  int maxAttempts = 8,
  double randomization = .25,
  int baseDelay = 250,
}) async {
  final random = Random();
  var attempts = 0;

  // ignore: literal_only_boolean_expressions
  while (true) {
    attempts++;
    try {
      return await action();
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      if (attempts >= maxAttempts || !(await retryIf(error))) {
        rethrow;
      } else {
        final randomizationFactor =
            (random.nextDouble() * randomization * 2) - randomization;
        final delay =
            (baseDelay * pow(2, attempts - 1) * randomizationFactor).toInt();

        await Future<void>.delayed(Duration(milliseconds: delay));
        await onRetry(error);
      }
    }
  }
}
