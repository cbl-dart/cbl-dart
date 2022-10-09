# Website

This website is built using [Docusaurus 2](https://docusaurus.io/), a modern
static website generator.

## Installation

```
$ npm ci
```

## Local Development

```
$ npm start
```

This command starts a local development server and opens up a browser window.
Most changes are reflected live without having to restart the server.

## Style Guide

### Formatting

This documentation uses [Prettier](https://prettier.io/) to format code. You can
format your code by running:

```shell
npm run prettier:write
```

There are IDE plugins for Prettier that you can use to format code on save:

- [IntelliJ](https://plugins.jetbrains.com/plugin/10456-prettier)
- [VSCode](https://github.com/prettier/prettier-vscode)

### Page Header

Each page usually starts with a description of the content of the page and links
to related content.

This information has to be specified in the front-matter of the page:

```
---
description: This is a description of the page.
related_content:
  - name: Related Content
    url: /related/content
---
```

### Callouts

For notes, warnings and other callouts, use
[Docosaurus admonitions](https://docusaurus.io/docs/markdown-features/admonitions).

## Custom Components

### CodeExample

Code examples are titled code blocks with a unique ID.

The `CodeExample` component is available without importing it.

Assign each code example a unique ID and give it a title:

````mdx
<CodeExample id={1} title="Close a Database">

```dart
print('Hello, World!');
```

</CodeExample>
````

The full ID that can be used to refer to a code example in URLs is
`example-{ID}`. For example to link to the code example above from the same
document, use `[Example 1](#example-1)`. For simple links like this, you can use
a short hand: `[Example 1](#)`. The link will be automatically updated with the
full URL when the document is rendered.
