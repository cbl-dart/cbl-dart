import '../support/ffi.dart';
import 'database.dart';

late final _defaultConfiguration = cblBindings.database.defaultConfiguration();

/// Configuration for opening a [Database].
class DatabaseConfiguration {
  /// Creates a configuration for opening a [Database].
  DatabaseConfiguration({String? directory})
      : directory = directory ?? _defaultConfiguration.directory;

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
