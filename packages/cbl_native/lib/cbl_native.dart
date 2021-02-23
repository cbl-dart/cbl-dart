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

  /// The url.
  late final Uri url = repo.releasesUrl.resolve('$tag/');

  /// The url for downloads of assets.
  late final Uri downloadUrl = url.resolve('download/');
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

/// Binaries for `cbl_native` for one [Platform].
class CblNativeBinaries {
  CblNativeBinaries({required this.platform});

  /// The name of the `cbl_native` package.
  final String packageName = 'cbl_native';

  /// The current version of `cbl_native`.
  final String version = '1.0.1'; // cbl_native: version

  /// The target platform of the binaries.
  final Platform platform;

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
}
