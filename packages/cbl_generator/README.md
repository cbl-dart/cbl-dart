<p align="center">
  <a href="https://cbl-dart.dev">
    <img src="https://raw.githubusercontent.com/cbl-dart/cbl-dart/main/docs/static/img/logo.png" width="100" alt="Couchbase Lite for Dart and Flutter">
  </a>
</p>

<p align="center">
  <strong>Code Generator for Couchbase Lite</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/cbl_generator"><img src="https://badgen.net/pub/v/cbl_generator" alt="Version"></a>
  <a href="https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml"><img src="https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg" alt="CI"></a>
  <a href="https://codecov.io/gh/cbl-dart/cbl-dart"><img src="https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39" alt="codecov"></a>
</p>

Generates typed document model classes for
[cbl](https://pub.dev/packages/cbl), giving you type-safe access to document
properties with zero boilerplate.

## Getting Started

Add the package as a dev dependency alongside `build_runner`:

```bash
dart pub add --dev cbl_generator build_runner
```

Define your document model:

```dart
import 'package:cbl/cbl.dart';

part 'user.cbl.type.g.dart';

@TypedDocument()
abstract class User with _$User {
  factory User({
    @DocumentId() String? id,
    required String username,
    required String email,
    required DateTime createdAt,
  }) = MutableUser;
}
```

Run the code generator:

```bash
dart run build_runner build
```

Use the generated classes:

```dart
final user = MutableUser(
  username: 'alice',
  email: 'alice@example.com',
  createdAt: DateTime.now(),
);
await collection.saveTypedDocument(user).withConcurrencyControl();
```

**[Read the full documentation at cbl-dart.dev](https://cbl-dart.dev/typed-data)**

## Contributing

Pull requests are welcome. For major changes, please open an
[issue](https://github.com/cbl-dart/cbl-dart/issues) first. Read
[CONTRIBUTING](https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md)
to get started.

## Disclaimer

This is not an official Couchbase product.
