import 'dart:io';

import 'package:cbl/src/support/app_directory.dart';
import 'package:path/path.dart' as p;

import '../../test_binding_impl.dart';
import '../test_binding.dart';

/// Whether we are running as a compiled Flutter app (as opposed to via the
/// `dart` CLI in standalone Dart tests).
final _isFlutter = detectAppName(Platform.resolvedExecutable) != null;

void main() {
  setupTestBinding();

  group('resolveAppFilesDirectory', () {
    group('iOS', () {
      test('returns the provided Application Support directory', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/path/to/Runner',
            os: OperatingSystem.ios,
            appleAppSupportDir:
                '/var/mobile/Containers/Data/Application/ABC123'
                '/Library/Application Support',
          ),
        );

        expect(
          result,
          '/var/mobile/Containers/Data/Application/ABC123'
          '/Library/Application Support',
        );
      });
    });

    group('macOS', () {
      test('returns Application Support/<bundleId> when bundle ID is set', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/path/to/MyApp',
            os: OperatingSystem.macos,
            macOSBundleId: 'com.example.myapp',
            appleAppSupportDir: '/Users/testuser/Library/Application Support',
          ),
        );

        expect(
          result,
          p.join(
            '/Users/testuser/Library/Application Support',
            'com.example.myapp',
          ),
        );
      });

      // This test calls _cfBundleIdentifier() via FFI, so it can only run on
      // macOS. When running via `dart test`, the main bundle has no identifier,
      // so the function returns null.
      if (Platform.isMacOS && !_isFlutter) {
        test('returns null when no bundle ID is found', () {
          final result = resolveAppFilesDirectory(
            context: const PlatformContext(
              resolvedExecutable: '/usr/local/bin/my_tool',
              os: OperatingSystem.macos,
              appleAppSupportDir: '/Users/testuser/Library/Application Support',
            ),
          );

          expect(result, isNull);
        });
      }
    });

    group('Linux', () {
      test('returns SNAP_USER_DATA for snap apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/snap/my-app/current/bin/my_app',
            environment: {
              'SNAP_USER_DATA': '/home/user/snap/my-app/current',
              'HOME': '/home/user',
            },
            os: OperatingSystem.linux,
          ),
        );

        expect(result, '/home/user/snap/my-app/current');
      });

      test('returns XDG_DATA_HOME for flatpak apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/app/bin/my_app',
            environment: {
              'FLATPAK_ID': 'com.example.MyApp',
              'XDG_DATA_HOME': '/home/user/.var/app/com.example.MyApp/data',
              'HOME': '/home/user',
            },
            os: OperatingSystem.linux,
          ),
        );

        expect(result, '/home/user/.var/app/com.example.MyApp/data');
      });

      test('returns XDG_DATA_HOME/<appName> for compiled apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/bin/my_flutter_app',
            environment: {
              'XDG_DATA_HOME': '/home/user/.local/share',
              'HOME': '/home/user',
            },
            os: OperatingSystem.linux,
          ),
        );

        expect(result, p.join('/home/user/.local/share', 'my_flutter_app'));
      });

      test('uses default XDG_DATA_HOME when not explicitly set', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/bin/my_flutter_app',
            environment: {'HOME': '/home/user'},
            os: OperatingSystem.linux,
          ),
        );

        expect(
          result,
          p.join('/home/user', '.local', 'share', 'my_flutter_app'),
        );
      });

      test('uses XDG_DATA_HOME from environment', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/bin/my_flutter_app',
            environment: {'XDG_DATA_HOME': '/custom/data/home'},
            os: OperatingSystem.linux,
          ),
        );

        expect(result, p.join('/custom/data/home', 'my_flutter_app'));
      });

      test('returns null for dart executable', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/lib/dart/bin/dart',
            environment: {'HOME': '/home/user'},
            os: OperatingSystem.linux,
          ),
        );

        expect(result, isNull);
      });

      test('returns null for flutter_tester', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/flutter/bin/cache/flutter_tester',
            environment: {'HOME': '/home/user'},
            os: OperatingSystem.linux,
          ),
        );

        expect(result, isNull);
      });

      test('returns null when HOME is not set and no XDG_DATA_HOME', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/bin/my_app',
            os: OperatingSystem.linux,
          ),
        );

        expect(result, isNull);
      });

      test('prefers SNAP_USER_DATA over other detection', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/snap/my-app/current/bin/my_app',
            environment: {
              'SNAP_USER_DATA': '/home/user/snap/my-app/current',
              'FLATPAK_ID': 'com.example.ignored',
              'HOME': '/home/user',
            },
            os: OperatingSystem.linux,
          ),
        );

        expect(result, '/home/user/snap/my-app/current');
      });
    });

    // Note: These tests use forward-slash paths because `package:path` uses
    // POSIX semantics on macOS/Linux where these tests run. On actual
    // Windows, `p.basenameWithoutExtension` correctly handles backslash
    // paths.
    group('Windows', () {
      test('returns appDataDir/<appName> for compiled apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/Program Files/MyApp/my_app.exe',
            os: OperatingSystem.windows,
            windowsAppDataDir: '/Users/user/AppData/Roaming',
          ),
        );

        expect(result, p.join('/Users/user/AppData/Roaming', 'my_app'));
      });

      test('returns null for dart.exe', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/dart-sdk/bin/dart.exe',
            os: OperatingSystem.windows,
            windowsAppDataDir: '/Users/user/AppData/Roaming',
          ),
        );

        expect(result, isNull);
      });

      test('returns null for flutter_tester.exe', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/flutter/bin/cache/flutter_tester.exe',
            os: OperatingSystem.windows,
            windowsAppDataDir: '/Users/user/AppData/Roaming',
          ),
        );

        expect(result, isNull);
      });
    });

    group('Android', () {
      test('returns /data/data/<packageName>/files', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/system/bin/app_process',
            os: OperatingSystem.android,
            androidPackageName: 'com.example.myapp',
          ),
        );

        expect(result, '/data/data/com.example.myapp/files');
      });
    });
  });

  group('resolveAndroidCacheDirectory', () {
    test('returns /data/data/<packageName>/cache', () {
      final result = resolveAndroidCacheDirectory(
        context: const PlatformContext(
          resolvedExecutable: '/system/bin/app_process',
          os: OperatingSystem.android,
          androidPackageName: 'com.example.myapp',
        ),
      );

      expect(result, '/data/data/com.example.myapp/cache');
    });
  });

  group('xdgDataHome', () {
    test('returns XDG_DATA_HOME when set', () {
      final result = xdgDataHome(
        environment: {'XDG_DATA_HOME': '/custom/data', 'HOME': '/home/user'},
      );

      expect(result, '/custom/data');
    });

    test('falls back to HOME/.local/share', () {
      final result = xdgDataHome(environment: {'HOME': '/home/user'});

      expect(result, p.join('/home/user', '.local', 'share'));
    });

    test('returns null when neither XDG_DATA_HOME nor HOME is set', () {
      final result = xdgDataHome(environment: {});

      expect(result, isNull);
    });
  });

  group('detectAppName', () {
    test('returns app name from executable path', () {
      expect(detectAppName('/usr/bin/my_app'), 'my_app');
    });

    test('strips .exe extension', () {
      expect(detectAppName('/Program Files/my_app.exe'), 'my_app');
    });

    test('returns null for dart executable', () {
      expect(detectAppName('/usr/lib/dart/bin/dart'), isNull);
    });

    test('returns null for dart.exe', () {
      expect(detectAppName('/dart-sdk/bin/dart.exe'), isNull);
    });

    test('returns null for flutter_tester', () {
      expect(detectAppName('/flutter/bin/cache/flutter_tester'), isNull);
    });

    test('returns null for flutter_tester.exe', () {
      expect(detectAppName('/flutter/bin/cache/flutter_tester.exe'), isNull);
    });
  });

  group('Platform app directory APIs', () {
    if (Platform.isIOS || Platform.isMacOS) {
      test('nsSearchPathForApplicationSupport returns Application '
          'Support path', () {
        final path = nsSearchPathForApplicationSupport();
        expect(path, isNotEmpty);
        expect(path, endsWith('/Library/Application Support'));
      });
    }

    if (Platform.isIOS) {
      test('cfBundleIdentifier returns bundle ID on iOS', () {
        final bundleId = cfBundleIdentifier();
        expect(bundleId, isNotNull);
        expect(bundleId, isNotEmpty);
      });
    }

    if (Platform.isMacOS) {
      if (_isFlutter) {
        test('cfBundleIdentifier returns bundle ID on Flutter', () {
          final bundleId = cfBundleIdentifier();
          expect(bundleId, isNotNull);
          expect(bundleId, isNotEmpty);
        });
      } else {
        test('cfBundleIdentifier returns null for standalone Dart', () {
          final bundleId = cfBundleIdentifier();
          expect(bundleId, isNull);
        });
      }
    }

    if (Platform.isAndroid) {
      test('readAndroidPackageName returns a package name', () {
        final packageName = readAndroidPackageName();
        expect(packageName, isNotEmpty);
      });
    }

    if (Platform.isLinux) {
      test('xdgDataHome returns a path', () {
        final path = xdgDataHome();
        expect(path, isNotNull);
        expect(path, isNotEmpty);
      });
    }

    if (Platform.isWindows) {
      test('windowsRoamingAppDataPath returns a path', () {
        final path = windowsRoamingAppDataPath();
        expect(path, isNotNull);
        expect(path, isNotEmpty);
      });
    }
  });
}
