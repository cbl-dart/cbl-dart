# Supported Platforms

## Flutter

| Platform | Version                |
| -------: | :--------------------- |
|      iOS | >= 10.0                |
|    macOS | >= 10.14               |
|  Android | >= 22                  |
|    Linux | == Ubuntu 20.04 x86_64 |
|  Windows | >= 10 x86_64           |

### Default database directory

When opening a database without specifying a directory,
[`path_provider`][path_provider]'s
[`getApplicationSupportDirectory`][getapplicationsupportdirectory] is used to
resolve it. See that function's documentation for the concrete locations on the
various platforms.

## Standalone Dart

| Platform | Version                |
| -------: | :--------------------- |
|    macOS | >= 10.14               |
|    Linux | == Ubuntu 20.04 x86_64 |
|  Windows | >= 10 x86_64           |

### Default database directory

When opening a database without specifying a directory, the current working
directory will be used. [`CouchbaseLiteDart.init`][couchbaselitedart.init]
allows you to specify a different default directory.

[path_provider]: https://pub.dev/packages/path_provider
[getapplicationsupportdirectory]:
  https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationSupportDirectory.html
[couchbaselitedart.init]:
  https://pub.dev/documentation/cbl_dart/latest/cbl_dart/CouchbaseLiteDart/init.html
