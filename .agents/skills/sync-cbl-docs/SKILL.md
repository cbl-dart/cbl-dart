---
name: sync-cbl-docs
description: >
  Sync a Couchbase Lite for Dart documentation page with the official Couchbase
  Lite docs. Use this skill whenever the user wants to update, sync, refresh, or
  align a documentation page in the cbl-dart project with the upstream official
  Couchbase docs. Also use when the user mentions that docs are outdated, asks to
  check for upstream doc changes, or wants to port content from the official
  Couchbase Lite documentation. Trigger on phrases like "sync docs", "update the
  databases page", "check if our docs are current", "port the official docs",
  "align with upstream docs".
---

# Sync Couchbase Lite Docs

Sync a page in the Couchbase Lite for Dart documentation site with the official
Couchbase Lite documentation from
https://github.com/couchbase/docs-couchbase-lite.

## Overview

The Dart docs at `docs/docs/*.mdx` mirror topics from the official Couchbase
Lite docs. The official docs are written in AsciiDoc for Antora and use the
Swift module as the primary reference implementation. This skill fetches the
official page, compares it to the Dart version, and rewrites the Dart page to
incorporate new or changed content — adapted for Dart APIs, MDX format, and the
project's custom components.

## Workflow

### Step 1: Identify the page mapping

Use the page mapping in `references/page-mapping.md` to find which official doc
file corresponds to the user's request. If the user gives you a Dart page name
(e.g., "databases"), look up the corresponding official file path. If they give
you an official page name, find the Dart counterpart.

After resolving the mapping, verify that the mapped Dart MDX file actually
exists in `docs/docs/`. If the mapping is stale, find the current file in the
repo and update `references/page-mapping.md` as part of the task.

Never derive the official AsciiDoc filename from the Dart page name or title.
Always use the mapping file for the upstream page name.

### Step 2: Fetch the official page

Use `curl` (via Bash) to fetch the raw AsciiDoc source from GitHub. Do not use
WebFetch — it summarizes AsciiDoc content instead of returning the raw source,
which causes sections to be lost.

```bash
curl -sL "https://raw.githubusercontent.com/couchbase/docs-couchbase-lite/release/4.0/modules/swift/pages/{filename}.adoc"
```

The official docs use AsciiDoc with Antora conventions:
- `= Title` for H1, `== Section` for H2, etc.
- `include::` directives pull in code snippets from example files — see below
  for how to fetch them
- `xref:swift:page.adoc[Label]` for cross-references
- Admonitions: `NOTE:`, `TIP:`, `CAUTION:`, `IMPORTANT:`
- Code blocks: `[source, swift]` followed by `----` delimited blocks
- Tags in code: `tag::name[]` / `end::name[]` delimit named regions

#### Fetching included code snippets

The AsciiDoc pages use `include::` directives to pull in Swift code examples.
These are available on GitHub and should be fetched so you can see the actual
Swift code being shown in the official docs.

Include paths follow the Antora convention `module:example$path`. For example:

```
include::swift:example$code_snippets/SampleCodeTest.swift[tags="fts-index"]
```

maps to:

```bash
curl -sL "https://raw.githubusercontent.com/couchbase/docs-couchbase-lite/release/4.0/modules/swift/examples/code_snippets/SampleCodeTest.swift"
```

The `[tags="name"]` attribute selects the region between `// tag::name[]` and
`// end::name[]` markers in the source file. Use `grep` to extract the relevant
tagged regions after fetching the file.

Seeing the original Swift code helps you write accurate Dart equivalents — you
can see the exact API calls, parameter names, and patterns used.

### Step 3: Read the current Dart page and build a section map

Read the existing MDX file from `docs/docs/`.

Before writing anything, build a section-by-section comparison between the
official page and the Dart page. List every section heading from the official
page and note whether it exists in the Dart page, is missing, or has different
content. This prevents accidentally dropping sections during the rewrite.

The Dart page may be a **stub** (just a placeholder pointing to the Swift docs)
or a **full page** with existing content. For stubs, you're writing the page
from scratch based on the official docs. For full pages, you're doing a
differential update. Either way, the section map ensures completeness.

### Step 4: Check available Dart APIs and behavior

Before writing code examples or referencing APIs, verify they exist in the Dart
codebase. The public API lives in `packages/cbl/lib/src/`. Key locations:

- Database API: `packages/cbl/lib/src/database/`
- Document API: `packages/cbl/lib/src/document/`
- Query API: `packages/cbl/lib/src/query/`
- Replicator: `packages/cbl/lib/src/replication/`
- Blobs: `packages/cbl/lib/src/document/blob.dart`
- Logging: `packages/cbl/lib/src/log/`

Use Grep/Glob to find the actual class names, method signatures, and enum
values. The Dart API doesn't always have a 1:1 correspondence with Swift — for
example, Dart has separate `openAsync`/`openSync` methods where Swift has a
single initializer.

Differences between the Dart SDK behavior should be verified with runtime
checks while implementing or updating docs. If a Dart-specific behavior could
reasonably differ from the upstream documentation, verify it with an existing
test or a focused runtime check before documenting it as fact.

### Step 5: Rewrite the Dart page

Produce an updated MDX file that:

1. **Incorporates new sections** from the official docs that are missing in the
   Dart version
2. **Updates existing sections** where the official docs have changed
3. **Removes sections** that no longer exist in the official docs (use judgment —
   some Dart-specific sections like "Couchbase Lite for VSCode" should be kept)
4. **Preserves Dart-specific content** that doesn't have an official equivalent
   (e.g., async/sync API tabs, Dart-specific tips)
5. **Writes Dart code examples** instead of Swift ones, using actual Dart API
   names verified against the codebase

Read `references/doc-conventions.md` for the full MDX format conventions before
writing.

### Step 6: Format and verify

After writing the updated page:
1. Run `npm run prettier:write` from the `docs/` directory to format the file
   (the docs use Prettier, not `daco format`)
2. Verify all `api|` references point to real APIs by spot-checking against the
   codebase
3. Verify any behavior-sensitive Dart-specific claims you added or changed are
   backed by runtime checks or existing tests

## Important guidelines

- The official docs are the source of truth for **conceptual content** (what a
  feature does, why it matters, best practices). The Dart docs adapt this
  content for the Dart SDK.
- **Never blindly copy Swift code.** All code examples must be valid Dart using
  the actual `cbl` package API.
- **Keep the existing page's voice.** The Dart docs are slightly more concise
  than the official ones. Don't add verbosity.
- **Stay close to the official structure.** Use the same section headings and
  organization as the official docs. Don't invent new sections, split content
  into standalone sections that don't exist upstream, or inline content that the
  official docs link to. Dart-specific additions (like async/sync API tabs) are
  fine, but the overall page skeleton should mirror the official page.
- Distinguish between verified facts and inferences while adapting content. Do
  not present a Dart-specific inference as a fact unless it has been checked in
  source or at runtime.
- **Enterprise features** should use the `<EnterpriseFeatureCallout />`
  component, not raw text.
- When the official docs reference platform-specific details (iOS Keychain,
  Android Keystore, etc.), adapt for the Dart context (which runs on all
  platforms).
- Sections about features not supported in the Dart SDK should be omitted
  entirely, not included with "not supported" notes.
- If you're unsure whether a feature exists in the Dart SDK, check the codebase
  before including it.
