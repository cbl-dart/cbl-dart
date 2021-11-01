[![Version](https://badgen.net/pub/v/cbl)](https://pub.dev/packages/cbl)
[![License](https://badgen.net/pub/license/cbl)](https://github.com/cbl-dart/cbl-dart/blob/main/packages/cbl/LICENSE)
[![CI](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml/badge.svg)](https://github.com/cbl-dart/cbl-dart/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/cbl-dart/cbl-dart/branch/main/graph/badge.svg?token=XNUVBY3Y39)](https://codecov.io/gh/cbl-dart/cbl-dart)

> :warning: This project has not yet reached a stable production release.

## Features

- Offline first
- Data is stored in JSON documents
  - Schemaless
  - Stored in efficient binary format
  - Support storing binary blobs
- Queries
  - Construct queries through a type safe builder API or write them in [N1QL]
  - Full text search
  - Indexes
- Synchronization with central Database
  - Synchronize with Couchbase Server through Sync Gateway
  - Local conflict resolution
- Change observer APIs for:
  - Database
  - Query
  - Replicator

## Supported Platforms

| Platform | Version                |
| -------: | ---------------------- |
|      iOS | >= 10.0                |
|    macOS | >= 10.14               |
|  Android | >= 22                  |
|    Linux | == Ubuntu 20.04 x86_64 |

## Getting started for Flutter

Head over to the [Flutter plugin for Couchbase Lite][cbl_flutter] to get started
using Couchbase Lite in your Flutter App.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

Please make sure to update tests as appropriate.

Read [CONTRIBUTING] to get started developing.

# Disclaimer

> **Warning:** This is not an official Couchbase product.

[contributing]: https://github.com/cbl-dart/cbl-dart/blob/main/CONTRIBUTING.md
[n1ql]: https://www.couchbase.com/products/n1ql
[cbl_flutter]: https://pub.dev/packages/cbl_flutter
