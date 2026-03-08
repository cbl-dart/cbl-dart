import 'dart:io';

import 'package:cbl/src/support/app_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('resolveAppFilesDirectory', () {
    group('iOS', () {
      test('returns Application Support under sandbox home', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/path/to/Runner',
          environment: {},
          isIOS: true,
          isMacOS: false,
          isAndroid: false,
          isLinux: false,
          isWindows: false,
          iosHome: '/var/mobile/Containers/Data/Application/ABC123',
        );

        expect(
          result,
          p.join(
            '/var/mobile/Containers/Data/Application/ABC123',
            'Library',
            'Application Support',
          ),
        );
      });
    });

    group('macOS', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('app_directory_test_');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('returns Application Support/<bundleId> for .app bundle', () {
        // Create a fake .app bundle structure.
        final appDir = Directory(
          p.join(tempDir.path, 'MyApp.app', 'Contents', 'MacOS'),
        )..createSync(recursive: true);
        final plistPath = p.join(
          tempDir.path,
          'MyApp.app',
          'Contents',
          'Info.plist',
        );
        File(plistPath).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.example.myapp</string>
</dict>
</plist>
''');

        final exePath = p.join(appDir.path, 'MyApp');

        final result = resolveAppFilesDirectory(
          resolvedExecutable: exePath,
          environment: {'HOME': '/Users/testuser'},
          isIOS: false,
          isMacOS: true,
          isAndroid: false,
          isLinux: false,
          isWindows: false,
        );

        expect(
          result,
          p.join(
            '/Users/testuser',
            'Library',
            'Application Support',
            'com.example.myapp',
          ),
        );
      });

      test('returns null for a CLI tool (no .app bundle)', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/usr/local/bin/my_tool',
          environment: {'HOME': '/Users/testuser'},
          isIOS: false,
          isMacOS: true,
          isAndroid: false,
          isLinux: false,
          isWindows: false,
        );

        expect(result, isNull);
      });

      test('returns null for dart executable', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/usr/lib/dart/bin/dart',
          environment: {'HOME': '/Users/testuser'},
          isIOS: false,
          isMacOS: true,
          isAndroid: false,
          isLinux: false,
          isWindows: false,
        );

        expect(result, isNull);
      });

      test('returns null when HOME is not set', () {
        final appDir = Directory(
          p.join(tempDir.path, 'MyApp.app', 'Contents', 'MacOS'),
        )..createSync(recursive: true);
        final plistPath = p.join(
          tempDir.path,
          'MyApp.app',
          'Contents',
          'Info.plist',
        );
        File(plistPath).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.example.myapp</string>
</dict>
</plist>
''');

        final result = resolveAppFilesDirectory(
          resolvedExecutable: p.join(appDir.path, 'MyApp'),
          environment: {},
          isIOS: false,
          isMacOS: true,
          isAndroid: false,
          isLinux: false,
          isWindows: false,
        );

        expect(result, isNull);
      });
    });

    group('Linux', () {
      test('returns SNAP_USER_DATA for snap apps', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/snap/my-app/current/bin/my_app',
          environment: {
            'SNAP_USER_DATA': '/home/user/snap/my-app/current',
            'HOME': '/home/user',
          },
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(result, '/home/user/snap/my-app/current');
      });

      test('returns XDG_DATA_HOME/<flatpakId> for flatpak apps', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/app/bin/my_app',
          environment: {
            'FLATPAK_ID': 'com.example.MyApp',
            'XDG_DATA_HOME': '/home/user/.var/app/com.example.MyApp/data',
            'HOME': '/home/user',
          },
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(
          result,
          p.join(
            '/home/user/.var/app/com.example.MyApp/data',
            'com.example.MyApp',
          ),
        );
      });

      test('returns XDG_DATA_HOME/<appName> for compiled apps', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/usr/bin/my_flutter_app',
          environment: {
            'XDG_DATA_HOME': '/home/user/.local/share',
            'HOME': '/home/user',
          },
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(result, p.join('/home/user/.local/share', 'my_flutter_app'));
      });

      test('uses default XDG_DATA_HOME when not explicitly set', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/usr/bin/my_flutter_app',
          environment: {'HOME': '/home/user'},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(
          result,
          p.join('/home/user', '.local', 'share', 'my_flutter_app'),
        );
      });

      test('returns null for dart executable', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/usr/lib/dart/bin/dart',
          environment: {'HOME': '/home/user'},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(result, isNull);
      });

      test('returns null for flutter_tester', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/flutter/bin/cache/flutter_tester',
          environment: {'HOME': '/home/user'},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(result, isNull);
      });

      test('returns null when HOME is not set and no XDG_DATA_HOME', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/usr/bin/my_app',
          environment: {},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(result, isNull);
      });

      test('prefers SNAP_USER_DATA over other detection', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/snap/my-app/current/bin/my_app',
          environment: {
            'SNAP_USER_DATA': '/home/user/snap/my-app/current',
            'FLATPAK_ID': 'com.example.ignored',
            'HOME': '/home/user',
          },
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: true,
          isWindows: false,
        );

        expect(result, '/home/user/snap/my-app/current');
      });
    });

    // Note: These tests use forward-slash paths because `package:path` uses
    // POSIX semantics on macOS/Linux where these tests run. On actual Windows,
    // `p.basenameWithoutExtension` correctly handles backslash paths.
    group('Windows', () {
      test('returns APPDATA/<appName> for compiled apps', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/Program Files/MyApp/my_app.exe',
          environment: {'APPDATA': '/Users/user/AppData/Roaming'},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: false,
          isWindows: true,
        );

        expect(result, p.join('/Users/user/AppData/Roaming', 'my_app'));
      });

      test('returns null for dart.exe', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/dart-sdk/bin/dart.exe',
          environment: {'APPDATA': '/Users/user/AppData/Roaming'},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: false,
          isWindows: true,
        );

        expect(result, isNull);
      });

      test('returns null for flutter_tester.exe', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/flutter/bin/cache/flutter_tester.exe',
          environment: {'APPDATA': '/Users/user/AppData/Roaming'},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: false,
          isWindows: true,
        );

        expect(result, isNull);
      });

      test('returns null when APPDATA is not set', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/Program Files/MyApp/my_app.exe',
          environment: {},
          isIOS: false,
          isMacOS: false,
          isAndroid: false,
          isLinux: false,
          isWindows: true,
        );

        expect(result, isNull);
      });
    });

    group('Android', () {
      test('returns /data/data/<packageName>/files', () {
        final result = resolveAppFilesDirectory(
          resolvedExecutable: '/system/bin/app_process',
          environment: {},
          isIOS: false,
          isMacOS: false,
          isAndroid: true,
          isLinux: false,
          isWindows: false,
          androidPackageName: 'com.example.myapp',
        );

        expect(result, '/data/data/com.example.myapp/files');
      });
    });
  });

  group('detectMacOSBundleId', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('bundle_id_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('detects bundle ID from .app bundle', () {
      final macosDir = Directory(
        p.join(tempDir.path, 'Test.app', 'Contents', 'MacOS'),
      )..createSync(recursive: true);
      File(
        p.join(tempDir.path, 'Test.app', 'Contents', 'Info.plist'),
      ).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.test.bundle</string>
</dict>
</plist>
''');

      expect(
        detectMacOSBundleId(p.join(macosDir.path, 'Test')),
        'com.test.bundle',
      );
    });

    test('returns null for non-.app executable', () {
      expect(detectMacOSBundleId('/usr/local/bin/tool'), isNull);
    });

    test('returns null when Info.plist is missing', () {
      final macosDir = Directory(
        p.join(tempDir.path, 'Test.app', 'Contents', 'MacOS'),
      )..createSync(recursive: true);

      expect(detectMacOSBundleId(p.join(macosDir.path, 'Test')), isNull);
    });

    test('returns null when CFBundleIdentifier is missing from plist', () {
      final macosDir = Directory(
        p.join(tempDir.path, 'Test.app', 'Contents', 'MacOS'),
      )..createSync(recursive: true);
      File(
        p.join(tempDir.path, 'Test.app', 'Contents', 'Info.plist'),
      ).writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Test</string>
</dict>
</plist>
''');

      expect(detectMacOSBundleId(p.join(macosDir.path, 'Test')), isNull);
    });

    test('handles path with too few components', () {
      expect(detectMacOSBundleId('/a'), isNull);
      expect(detectMacOSBundleId('/a/b'), isNull);
    });
  });

  group('parseBundleIdFromPlistXml', () {
    test('parses standard plist format', () {
      expect(
        parseBundleIdFromPlistXml('''
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.example.app</string>
</dict>
'''),
        'com.example.app',
      );
    });

    test('handles whitespace variations', () {
      expect(
        parseBundleIdFromPlistXml(
          '<key> CFBundleIdentifier </key>\n  <string>com.test</string>',
        ),
        'com.test',
      );
    });

    test('returns null for missing key', () {
      expect(
        parseBundleIdFromPlistXml('''
<dict>
  <key>CFBundleName</key>
  <string>MyApp</string>
</dict>
'''),
        isNull,
      );
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
}
