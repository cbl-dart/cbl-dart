# Page Mapping: Dart Docs → Official Couchbase Lite Docs

The official docs live at
`https://github.com/couchbase/docs-couchbase-lite/tree/release/4.0/modules/swift/pages/`.

The Dart docs live at `docs/docs/` in the workspace.

## Mapping

| Dart MDX file                                    | Official AsciiDoc file (Swift module)             |
| ------------------------------------------------ | ------------------------------------------------- |
| `databases.mdx`                                  | `database.adoc`                                   |
| `documents.mdx`                                  | `document.adoc`                                   |
| `blobs.mdx`                                      | `blob.adoc`                                       |
| `indexing.mdx`                                   | `indexing.adoc`                                    |
| `scopes-and-collections.mdx`                     | `scopes-collections-manage.adoc`                  |
| `prebuilt-database.mdx`                          | `prebuilt-database.adoc`                           |
| `queries/query-builder.mdx`                      | `querybuilder.adoc`                                |
| `queries/sqlplusplus-mobile.mdx`                 | `query-n1ql-mobile.adoc`                           |
| `queries/sqlplusplus-server-diff.mdx`            | `query-n1ql-mobile-server-diffs.adoc`              |
| `queries/sqlplusplus-query-builder-diff.mdx`     | `query-n1ql-mobile-querybuilder-diffs.adoc`        |
| `queries/query-result-sets.mdx`                  | `query-resultsets.adoc`                            |
| `queries/live-queries.mdx`                       | `query-live.adoc`                                  |
| `queries/query-troubleshooting.mdx`              | `query-troubleshooting.adoc`                       |
| `search/full-text-search.mdx`                    | `fts.adoc`                                         |
| `search/vector-search.mdx`                       | `vector-search.adoc`                               |
| `data-sync/peer-to-peer/websocket.mdx`           | `p2psync-websocket.adoc`                           |
| `data-sync/peer-to-peer/passive-peer.mdx`        | `p2psync-websocket-using-passive.adoc`             |
| `data-sync/peer-to-peer/active-peer.mdx`         | `p2psync-websocket-using-active.adoc`              |

## Pages without an official counterpart

These Dart doc pages don't have a direct mapping to the official docs:

- `overview.mdx` — Project-specific overview
- `install.mdx` — Dart/Flutter-specific installation
- `migration-v3-to-v4.mdx` — Dart SDK migration guide
- `general-concepts.mdx` — Dart-specific concepts (sync/async APIs, etc.)
- `typed-data.mdx` — cbl_generator feature, Dart-specific
- `usage-examples.mdx` — Dart-specific examples
- `supported-platforms.mdx` — Dart-specific platform support

## Notes

- The official docs have platform-specific modules (swift, android, java, etc.).
  We use `swift` as the reference because it's the most complete and closest in
  API style to the Dart SDK.
- Some official pages don't have Dart equivalents (e.g., `gs-build.adoc`,
  `gs-install.adoc`, `quickstart.adoc`) because those are covered differently
  in the Dart docs.
- The official `replication.adoc` covers Sync Gateway replication, which the
  Dart docs don't have a dedicated page for yet.
