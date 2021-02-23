import 'dart:io' as io;
import 'dart:io';

import 'package:cbl_native/cbl_native.dart';
import 'package:test/test.dart';

void main() {
  test('CblNativeBinary.url returns the correct download url', () {
    final binary = CblNativeBinaries(platform: Platform.linux);
    final tag = '${binary.packageName}-v${binary.version}';

    expect(
      binary.url.toString(),
      'https://github.com/cofu-app/cbl-dart/releases'
      '/download/$tag/${binary.packageName}-v${binary.version}-linux.tar.gz',
    );
  });

  test('binary_url script returns the correct download url', () async {
    final result =
        await io.Process.run('dart', ['run', 'cbl_native:binary_url', 'linux']);

    final url = result.stdout as String;

    expect(
      url,
      matches(
        'https://github.com/cofu-app/cbl-dart/releases'
        '/download/cbl_native-v(.+)/cbl_native-v(.+)-linux.tar.gz',
      ),
    );
  });

  test('binary_url script downloads and installs binaries', () async {
    final tmpTestDir = 'test/.tmp';
    final installDir =
        '$tmpTestDir/${DateTime.now().millisecondsSinceEpoch}-linux/lib';

    final result = await io.Process.run('dart', [
      'run',
      'cbl_native:binary_url',
      'linux',
      '--install',
      installDir,
    ]);

    expect(result.exitCode, 0, reason: 'exit code');

    expect(
      Directory(installDir).list().toList(),
      completion(isNotEmpty),
      reason: 'installDir contents',
    );
  });
}
