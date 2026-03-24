import 'dart:io';

import 'package:cbl/src/support/app_directory.dart';
import 'package:path/path.dart' as p;

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('resolveAppFilesDirectory', () {
    group('iOS', () {
      test('returns the Application Support directory', () {
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

      // When macOSBundleId is not provided, the strategy falls through to FFI
      // which only works on macOS. On standalone Dart (no .app bundle) the FFI
      // call returns null.
      if (Platform.isMacOS) {
        test('returns null when no bundle ID is available', () {
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

    group('Linux', () {
      test('uses SNAP_USER_DATA for snap apps', () {
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

      test('uses XDG_DATA_HOME for flatpak apps', () {
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

      test('uses XDG_DATA_HOME/<appName> for compiled apps', () {
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

      test('falls back to HOME/.local/share when XDG_DATA_HOME is not set', () {
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

      test('prefers SNAP_USER_DATA over flatpak detection', () {
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

      test('returns null when HOME is missing and no XDG_DATA_HOME', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/bin/my_app',
            os: OperatingSystem.linux,
          ),
        );

        expect(result, isNull);
      });
    });

    // Note: These tests use forward-slash paths because `package:path` uses
    // POSIX semantics on macOS/Linux where these tests run. On actual
    // Windows, `p.basenameWithoutExtension` correctly handles backslash paths.
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
    });

    group('returns null for development executables', () {
      const devExecutables = {
        'dart': '/usr/lib/dart/bin/dart',
        'dart.exe': '/dart-sdk/bin/dart.exe',
        'flutter_tester': '/flutter/bin/cache/flutter_tester',
        'flutter_tester.exe': '/flutter/bin/cache/flutter_tester.exe',
      };

      const platformContexts = {
        'Linux': (OperatingSystem.linux, {'HOME': '/home/user'}),
        'Windows': (OperatingSystem.windows, <String, String>{}),
      };

      for (final MapEntry(key: exeName, value: exePath)
          in devExecutables.entries) {
        for (final MapEntry(key: osName, value: (os, env))
            in platformContexts.entries) {
          test('$exeName on $osName', () {
            final result = resolveAppFilesDirectory(
              context: PlatformContext(
                resolvedExecutable: exePath,
                environment: env,
                os: os,
                windowsAppDataDir: os == OperatingSystem.windows
                    ? '/Users/user/AppData/Roaming'
                    : null,
              ),
            );

            expect(result, isNull);
          });
        }
      }
    });

    test('returns null for unknown OS', () {
      final result = resolveAppFilesDirectory(
        context: const PlatformContext(
          resolvedExecutable: '/usr/bin/my_app',
          os: OperatingSystem.unknown,
        ),
      );

      expect(result, isNull);
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

  // Integration tests that exercise the real platform FFI calls. Each test
  // only registers on the platform where its FFI is available.
  group('platform integration', () {
    if (Platform.isMacOS || Platform.isIOS) {
      test('resolveAppFilesDirectory returns a path on Apple platforms', () {
        final result = resolveAppFilesDirectory();

        // On iOS and Flutter macOS apps we always get a path. On standalone
        // Dart on macOS there is no bundle ID so the result is null.
        if (Platform.isIOS) {
          expect(result, isNotNull);
          expect(result, contains('/Library/Application Support'));
        }
      });
    }

    if (Platform.isAndroid) {
      test('resolveAppFilesDirectory returns a path on Android', () {
        final result = resolveAppFilesDirectory();

        expect(result, isNotNull);
        expect(result, startsWith('/data/data/'));
        expect(result, endsWith('/files'));
      });

      test('resolveAndroidCacheDirectory returns a path', () {
        final result = resolveAndroidCacheDirectory();

        expect(result, startsWith('/data/data/'));
        expect(result, endsWith('/cache'));
      });
    }

    if (Platform.isLinux) {
      // On Linux with a compiled app this returns a path; with `dart test`
      // it returns null. Either is acceptable — the important thing is that
      // the FFI / environment lookup doesn't throw.
      test(
        'resolveAppFilesDirectory returns a result on Linux',
        resolveAppFilesDirectory,
      );
    }

    if (Platform.isWindows) {
      test(
        'resolveAppFilesDirectory returns a result on Windows',
        resolveAppFilesDirectory,
      );
    }
  });
}
