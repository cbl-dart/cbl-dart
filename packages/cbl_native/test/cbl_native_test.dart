import 'dart:io' as io;

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
}
