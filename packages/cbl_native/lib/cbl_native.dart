class GitHubRepo {
  GitHubRepo({
    required this.owner,
    required this.repo,
  });

  final String owner;

  final String repo;

  late final Uri url = Uri.parse('https://github.com/$owner/$repo/');

  late final Uri releasesUrl = url.resolve('releases/');
}

class GitHubRelease {
  GitHubRelease({
    required this.repo,
    required this.tag,
  });

  final GitHubRepo repo;

  final String tag;

  late final Uri url = repo.releasesUrl.resolve('$tag/');

  late final Uri downloadUrl = url.resolve('download/');
}

enum Platform {
  linux,
  android,
  apple,
}

extension PlatformExt on Platform {
  String platformName() => toString().split('.')[1];
}

final cblDartRepo = GitHubRepo(
  owner: 'cofu-app',
  repo: 'cbl-dart',
);

class CblNativeBinary {
  CblNativeBinary({
    required this.packageName,
    required this.version,
    required this.platform,
  });

  final String packageName;

  final String version;

  final Platform platform;

  late final release = GitHubRelease(
    repo: cblDartRepo,
    tag: '$packageName-v$version',
  );

  late final String filename =
      '${release.tag}-${platform.platformName()}.tar.gz';

  late final Uri url = release.downloadUrl.resolve(filename);
}
