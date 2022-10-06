---
slug: /
---

# Overview

Couchbase Lite is an embedded, NoSQL database that makes it easy to build
offline-enabled applications.

Couchbase Lite for Dart is a platform implementation of Couchbase Lite for Dart
and Flutter. It has feature parity with Couchbase Lite implementations for other
platforms, with a few [exceptions](#limitations).

Couchbase Lite for Dart is a community provided solution that is actively
developed and maintained by the community. It is not an official Couchbase
product.

## Documentation

This documentation is primarily for specifics of Couchbase Lite for Dart.

Even though the [Couchbase Lite for Dart API][cbl-api] is well documented, a lot
of additional information is available in the official Couchbase Lite
documentation for the different platforms. Since the Swift API is closest to the
Dart API, I recommend consulting the [Couchbase Lite for Swift
documentation][cbl-swfit-docs] in addition to this documentation.

## Features

- Offline First
- Documents
  - Schemaless
  - Stored in efficient binary format
- Blobs
  - Store and sync binary data, for example JPGs or PDFs
- Queries
  - [SQL++] query language
    - Extension of familiar SQL for JSON-like data
    - Many builtin functions
  - Type safe builder API for [SQL++]
  - Full-Text Search
  - Indexing
- Data Sync
  - Remote [Sync Gateway]
  - Intra-device Sync **\***
  - Delta Sync **\***
- Data Conflict Handling
- Change Notifications for:
  - Documents
  - Queries
  - Replicators
- Encryption
  - Full Database **\***

**\***: **Enterprise Edition** only feature

## Limitations

Some of the features supported by other platform implementations of Couchbase
Lite are currently not supported:

- Predictive Queries
- Peer-to-Peer Data Sync
- Background Data Sync on iOS and Android
- Integration with system-wide configured proxies
- VPN On Demand on iOS

[sql++]: https://www.couchbase.com/products/n1ql
[cbl-api]: https://pub.dev/documentation/cbl/latest/cbl/cbl-library.html
[cbl-swfit-docs]:
  https://docs.couchbase.com/couchbase-lite/current/swift/quickstart.html
