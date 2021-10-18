// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:io';

import '../support/ffi.dart';
import '../support/isolate.dart';
import 'database.dart';

/// Configuration for opening a [Database].
class DatabaseConfiguration {
  /// Creates a configuration for opening a [Database].
  DatabaseConfiguration({String? directory})
      : directory = directory ?? _defaultDirectory();

  /// Creates a configuration of another [config] be copying its properties.
  DatabaseConfiguration.from(DatabaseConfiguration config)
      : this(directory: config.directory);

  /// Path to the directory to store the [Database] in.
  String directory;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseConfiguration &&
          runtimeType == other.runtimeType &&
          directory == other.directory;

  @override
  int get hashCode => directory.hashCode;

  @override
  String toString() => [
        'DatabaseConfiguration(',
        [
          'directory: $directory',
        ].join(', '),
        ')',
      ].join();
}

String _defaultDirectory() {
  final filesDir = IsolateContext.instance.initContext?.filesDir;
  if (filesDir != null) {
    return '$filesDir${Platform.pathSeparator}CouchbaseLite';
  }

  return cblBindings.database.defaultConfiguration().directory;
}
