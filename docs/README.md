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

TODO

### Callouts

For notes, warnings and other callouts, use
[Docosaurus admonitions](https://docusaurus.io/docs/markdown-features/admonitions).

## Custom Components

### CodeExample

Code examples are titled code blocks with a unique ID.

To use the `CodeExample` component, make sure it is imported at the top of the
document:

```
import CodeExample from '@site/src/components/CodeExample'
```

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
