import 'dart:io';

import 'package:cbl/src/support/app_directory.dart';
import 'package:path/path.dart' as p;

import '../../test_binding_impl.dart';
import '../test_binding.dart';

void main() {
  setupTestBinding();

  group('isFlutterApp', () {
    test('uses explicit override when set', () {
      expect(
        isFlutterApp(
          context: const PlatformContext(
            resolvedExecutable: '/path/to/dart',
            os: OperatingSystem.linux,
            isFlutterApp: true,
          ),
        ),
        isTrue,
      );

      expect(
        isFlutterApp(
          context: const PlatformContext(
            resolvedExecutable: '/path/to/my_app',
            os: OperatingSystem.ios,
            isFlutterApp: false,
          ),
        ),
        isFalse,
      );
    });

    test('auto-detects based on dart:ui availability', () {
      // When isFlutterApp is not set, detection falls back to the
      // compile-time constant `bool.fromEnvironment('dart.library.ui')`,
      // but also filters out the `flutter_tester` executable used by
      // `flutter test`.
      // ignore: do_not_use_environment
      const kIsFlutter = bool.fromEnvironment('dart.library.ui');
      final exe = p.basenameWithoutExtension(Platform.resolvedExecutable);
      final expected = kIsFlutter && exe != 'flutter_tester';
      expect(isFlutterApp(), expected);
    });

    test('returns false for flutter_tester even with dart:ui available', () {
      expect(
        isFlutterApp(
          context: const PlatformContext(
            resolvedExecutable: '/flutter/bin/cache/flutter_tester',
            os: OperatingSystem.linux,
          ),
        ),
        isFalse,
      );
    });
  });

  group('resolveAppFilesDirectory', () {
    test('returns null when not a Flutter app', () {
      final result = resolveAppFilesDirectory(
        context: const PlatformContext(
          resolvedExecutable: '/usr/bin/my_dart_cli',
          os: OperatingSystem.linux,
          isFlutterApp: false,
          environment: {'HOME': '/home/user'},
        ),
      );

      expect(result, isNull);
    });

    group('iOS', () {
      test('returns the Application Support directory', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/path/to/Runner',
            os: OperatingSystem.ios,
            isFlutterApp: true,
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
            isFlutterApp: true,
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
    });

    group('Android', () {
      test('returns /data/user/<userId>/<packageName>/files', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/system/bin/app_process',
            os: OperatingSystem.android,
            isFlutterApp: true,
            androidPackageName: 'com.example.myapp',
            androidUserId: 0,
          ),
        );

        expect(result, '/data/user/0/com.example.myapp/files');
      });

      test('uses correct path for secondary user profiles', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/system/bin/app_process',
            os: OperatingSystem.android,
            isFlutterApp: true,
            androidPackageName: 'com.example.myapp',
            androidUserId: 10,
          ),
        );

        expect(result, '/data/user/10/com.example.myapp/files');
      });
    });

    group('Linux', () {
      test('uses SNAP_USER_DATA for snap apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/snap/my-app/current/bin/my_app',
            isFlutterApp: true,
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
            isFlutterApp: true,
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

      test('uses XDG_DATA_HOME/<appName> for Flutter apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/usr/bin/my_flutter_app',
            isFlutterApp: true,
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
            isFlutterApp: true,
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
            isFlutterApp: true,
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
            isFlutterApp: true,
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
      test('returns appDataDir/<appName> for Flutter apps', () {
        final result = resolveAppFilesDirectory(
          context: const PlatformContext(
            resolvedExecutable: '/Program Files/MyApp/my_app.exe',
            isFlutterApp: true,
            os: OperatingSystem.windows,
            windowsAppDataDir: '/Users/user/AppData/Local',
          ),
        );

        expect(result, p.join('/Users/user/AppData/Local', 'my_app'));
      });
    });

    test('returns null for unknown OS', () {
      final result = resolveAppFilesDirectory(
        context: const PlatformContext(
          resolvedExecutable: '/usr/bin/my_app',
          isFlutterApp: true,
          os: OperatingSystem.unknown,
        ),
      );

      expect(result, isNull);
    });
  });

  group('resolveAndroidCacheDirectory', () {
    test('returns /data/user/<userId>/<packageName>/cache', () {
      final result = resolveAndroidCacheDirectory(
        context: const PlatformContext(
          resolvedExecutable: '/system/bin/app_process',
          os: OperatingSystem.android,
          androidPackageName: 'com.example.myapp',
          androidUserId: 0,
        ),
      );

      expect(result, '/data/user/0/com.example.myapp/cache');
    });
  });

  group('platform integration', () {
    group('macOS', () {
      test(
        'in a Flutter app, resolves to Application Support/<bundleId>',
        () {
          final result = resolveAppFilesDirectory();

          expect(result, isNotNull);
          expect(result, contains('/Library/Application Support'));
        },
        skip: isFlutterApp() ? null : 'Only in a Flutter app',
      );

      test(
        'outside a Flutter app, returns null',
        () {
          final result = resolveAppFilesDirectory();

          expect(result, isNull);
        },
        skip: !isFlutterApp() ? null : 'Only outside a Flutter app',
      );
    }, skip: Platform.isMacOS ? null : 'Requires macOS');

    group('iOS', () {
      test('resolves to Application Support directory', () {
        final result = resolveAppFilesDirectory();

        expect(result, isNotNull);
        expect(result, contains('/Library/Application Support'));
      });
    }, skip: Platform.isIOS ? null : 'Requires iOS');

    group('Android', () {
      test('resolves to /data/user/<userId>/<packageName>/files', () {
        final result = resolveAppFilesDirectory();

        expect(result, isNotNull);
        expect(result, startsWith('/data/user/'));
        expect(result, endsWith('/files'));
      });

      test('resolveAndroidCacheDirectory resolves to cache directory', () {
        final result = resolveAndroidCacheDirectory();

        expect(result, startsWith('/data/user/'));
        expect(result, endsWith('/cache'));
      });
    }, skip: Platform.isAndroid ? null : 'Requires Android');

    group('Linux', () {
      test(
        'in a Flutter app, resolves to a non-null path',
        () {
          final result = resolveAppFilesDirectory();

          expect(result, isNotNull);
        },
        skip: isFlutterApp() ? null : 'Only in a Flutter app',
      );

      test(
        'outside a Flutter app, returns null',
        () {
          final result = resolveAppFilesDirectory();

          expect(result, isNull);
        },
        skip: !isFlutterApp() ? null : 'Only outside a Flutter app',
      );
    }, skip: Platform.isLinux ? null : 'Requires Linux');

    group('Windows', () {
      test(
        'in a Flutter app, resolves to a non-null path',
        () {
          final result = resolveAppFilesDirectory();

          expect(result, isNotNull);
        },
        skip: isFlutterApp() ? null : 'Only in a Flutter app',
      );

      test(
        'outside a Flutter app, returns null',
        () {
          final result = resolveAppFilesDirectory();

          expect(result, isNull);
        },
        skip: !isFlutterApp() ? null : 'Only outside a Flutter app',
      );
    }, skip: Platform.isWindows ? null : 'Requires Windows');
  });
}
