# Dart Docs Conventions

Reference for the MDX format and custom components used in the Couchbase Lite
for Dart documentation site (`docs/docs/`).

## File structure

Every doc page is an MDX file with this structure:

```mdx
---
description: Short description for meta header
related_content:
  - name: Related Page
    url: /relative-url
---

import TabItem from '@theme/TabItem'
import Tabs from '@theme/Tabs'

# Page Title

Content here...
```

- `description` is required — shown in the MetaHeader component below H1
- `related_content` is an array of `{name, url}` pairs for contextual navigation
- Imports go right after the frontmatter, before the H1

## Custom components

### CodeExample

Wraps code blocks with a numbered caption. Takes `id` (number) and `title`
(string).

```mdx
<CodeExample id={1} title="Opening a Database">

```dart
final database = await Database.openAsync('my-database');
```

</CodeExample>
```

Cross-reference with `[Example 1](#)` — the figure-links plugin auto-resolves
the anchor.

Important: blank lines are required around the content inside `<CodeExample>`.

### APITabs / APITab

Groups content by sync/async API variant. Use when showing both flavors:

```mdx
<APITabs>
<APITab api="Async">

```dart
final database = await Database.openAsync('my-database');
```

</APITab>
<APITab api="Sync">

```dart
final database = Database.openSync('my-database');
```

</APITab>
</APITabs>
```

Use inside `<CodeExample>` when both sync and async examples are needed.

### EmbedderTabs / EmbedderTab

Groups content by Dart/Flutter platform variant:

```mdx
<EmbedderTabs>
<EmbedderTab embedder="Dart">
Dart-specific content
</EmbedderTab>
<EmbedderTab embedder="Flutter">
Flutter-specific content
</EmbedderTab>
</EmbedderTabs>
```

### Table / Figure

Like CodeExample but for tables and figures:

```mdx
<Table id={1} title="Comparison">

| A | B |
| - | - |
| 1 | 2 |

</Table>
```

### EnterpriseFeatureCallout

Use for Enterprise Edition features. Renders an info admonition:

```mdx
<EnterpriseFeatureCallout />
```

## API link syntax

Inline code with the `api|` prefix auto-links to pub.dev API docs:

| Syntax                          | Links to                              |
| ------------------------------- | ------------------------------------- |
| `` `api\|Database` ``           | Database class                        |
| `` `api\|Database.openAsync` `` | openAsync method on Database          |
| `` `api\|enum:LogLevel` ``      | LogLevel enum                         |
| `` `api\|new:MutableDocument` ``| MutableDocument constructor           |
| `` `api\|fn:someFunction` ``    | Top-level function                    |
| `` `api\|prop:someProp` ``      | Top-level property                    |
| `` `api\|const:someConst` ``    | Constant                              |
| `` `api\|ext:SomeExtension` ``  | Extension                             |
| `` `api\|td:SomeTypedef` ``     | Typedef                               |
| `` `api\|enum-value:Foo.bar` `` | Enum value                            |
| `` `api\|dart:core\|DateTime` ``| Dart SDK type                         |
| `` `api\|cbl_sentry:...\|Cls` ``| Type from another package             |

The default package is `cbl`. Only use package prefix for other packages.

## Admonitions

Use Docusaurus admonition syntax:

```mdx
:::tip[Optional Title]
Content here
:::

:::note
Content here
:::

:::caution
Content here
:::

:::info
Content here
:::
```

## Code blocks

All code examples use fenced code blocks with the `dart` language tag:

````mdx
```dart
final db = await Database.openAsync('test');
```
````

Code is always inline in the MDX — never loaded from external files.

## Internal links

Use relative paths with `.mdx` extension:

```mdx
See [Supported Platforms](./supported-platforms.mdx) for details.
```

Or absolute paths from docs root for `related_content`:

```yaml
related_content:
  - name: Databases
    url: /databases
```

## Cross-referencing figures/tables/examples

Use `[Example 1](#)`, `[Table 1](#)`, or `[Figure 1](#)` — the remark plugin
auto-resolves these to `#example-1`, `#table-1`, `#figure-1`.

## Formatting

After editing, run `npm run prettier:write` from the `docs/` directory to format
with Prettier. The docs site uses Prettier (not `daco format`, which is for Dart
files only).
