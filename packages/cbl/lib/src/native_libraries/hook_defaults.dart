import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'package.dart';

final class NativeLibraryDefaults {
  NativeLibraryDefaults({
    required this.editions,
    required this.vectorSearch,
    required this.baseDirectory,
  });

  final Set<Edition> editions;
  final bool vectorSearch;
  final Directory? baseDirectory;
}

Edition parseEdition(String value) => switch (value) {
  'community' => Edition.community,
  'enterprise' => Edition.enterprise,
  _ => throw ArgumentError.value(
    value,
    'value',
    'edition must be "community" or "enterprise"',
  ),
};

void validateNativeLibraryConfiguration({
  required Set<Edition> editions,
  required bool vectorSearch,
}) {
  if (vectorSearch && !editions.contains(Edition.enterprise)) {
    throw BuildError(
      message:
          'vector_search: true requires edition: enterprise in user_defines.',
    );
  }
}

NativeLibraryDefaults resolveNativeLibraryDefaults({
  Object? editionValue,
  Object? vectorSearchValue,
  Directory? baseDirectory,
}) {
  final edition = switch (editionValue) {
    null => Edition.community,
    final Object value => _parseEditionUserDefine(value),
  };
  final vectorSearch = switch (vectorSearchValue) {
    true => true,
    'true' => true,
    _ => false,
  };

  final defaults = NativeLibraryDefaults(
    editions: {edition},
    vectorSearch: vectorSearch,
    baseDirectory: baseDirectory,
  );
  validateNativeLibraryConfiguration(
    editions: defaults.editions,
    vectorSearch: defaults.vectorSearch,
  );
  return defaults;
}

NativeLibraryDefaults resolveNativeLibraryDefaultsFromUserDefines(
  Object userDefines, {
  Directory? baseDirectory,
}) {
  final editionValue = switch (userDefines) {
    final HookInputUserDefines userDefines => userDefines['edition'],
    final Map<dynamic, dynamic> userDefines => userDefines['edition'],
    _ => throw ArgumentError.value(
      userDefines,
      'userDefines',
      'must be a HookInputUserDefines or Map',
    ),
  };
  final vectorSearchValue = switch (userDefines) {
    final HookInputUserDefines userDefines => userDefines['vector_search'],
    final Map<dynamic, dynamic> userDefines => userDefines['vector_search'],
    _ => null,
  };
  return resolveNativeLibraryDefaults(
    editionValue: editionValue,
    vectorSearchValue: vectorSearchValue,
    baseDirectory: baseDirectory,
  );
}

NativeLibraryDefaults readHookUserDefines([Directory? startDirectory]) {
  final nearestPubspec = _findRelevantPubspec(
    startDirectory ?? Directory.current,
  );
  if (nearestPubspec == null) {
    return NativeLibraryDefaults(
      editions: {Edition.community},
      vectorSearch: false,
      baseDirectory: null,
    );
  }

  final yaml = loadYaml(nearestPubspec.readAsStringSync());
  final hooks = yaml is YamlMap ? yaml['hooks'] : null;
  final userDefines = hooks is YamlMap ? hooks['user_defines'] : null;
  final cbl = userDefines is YamlMap ? cblUserDefinesMap(userDefines) : null;

  return resolveNativeLibraryDefaults(
    editionValue: cbl?['edition'],
    vectorSearchValue: cbl?['vector_search'],
    baseDirectory: nearestPubspec.parent,
  );
}

Map<dynamic, dynamic>? cblUserDefinesMap(Map<dynamic, dynamic> userDefines) {
  final cbl = userDefines['cbl'];
  return cbl is YamlMap || cbl is Map ? cbl as Map<dynamic, dynamic> : null;
}

File? findRelevantPubspec(Directory startDirectory) =>
    _findRelevantPubspec(startDirectory);

File? _findRelevantPubspec(Directory startDirectory) {
  Directory? nearestPubspecDir;
  var current = startDirectory.absolute;

  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      nearestPubspecDir ??= current;
      final content = pubspec.readAsStringSync();
      if (RegExp('^workspace:', multiLine: true).hasMatch(content)) {
        return pubspec;
      }
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }

  return nearestPubspecDir == null
      ? null
      : File(p.join(nearestPubspecDir.path, 'pubspec.yaml'));
}

Edition _parseEditionUserDefine(Object value) {
  final stringValue = value.toString();
  return switch (stringValue) {
    'community' => Edition.community,
    'enterprise' => Edition.enterprise,
    _ => throw BuildError(
      message:
          'edition must be "community" or "enterprise", '
          'got "$stringValue".',
    ),
  };
}
