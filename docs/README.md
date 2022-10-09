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

## Formatting

This documentation uses [Prettier](https://prettier.io/) to format code. You can
format your code by running:

```shell
npm run prettier:write
```

There are IDE plugins for Prettier that you can use to format code on save:

- [IntelliJ](https://plugins.jetbrains.com/plugin/10456-prettier)
- [VSCode](https://github.com/prettier/prettier-vscode)

## Page Header

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

## Callouts

For notes, warnings and other callouts, use
[Docosaurus admonitions](https://docusaurus.io/docs/markdown-features/admonitions).

## Linking to API Reference

Documentation often references elements of a Dart package API in backticks:

```
When opening a `Database` it will be created if it doesn't exist yet.
```

To make such a reference link to the corresponding API reference, use the `api|`
prefix:

```
When opening a `api|Database` it will be created if it doesn't exist yet.
```

The example above links to the `Database` class in the `cbl` package in the
`cbl` library. This is default package and library.

If you want to link to a different package, you need to specify it:

```
`api|moor|Database`
```

If the referenced element is not in the library with same name as the package,
you need to specify the library:

```
`api|sentry:sentry_io|Sentry`
```

You can also reference elements from the Dart standard library:

```
`api|dart:isolate|Isolate`
```

To reference (static) members (field, getters, setters, methods) of a type,
separate the type name and the member name with a dot:

```
`api|Database.document`
```

To reference a constructor, specify the `new` type before the type name:

```
`api|new:MutableDocument`
`api|new:MutableDocument.withId`
```

To reference elements other than classes and mixins, specify a type:

```
A typedef             `api|td:Foo`
An extension          `api|ext:Foo`
A top-level function  `api|fn:foo`
A top-level property  `api|prop:foo`
A top-level const     `api|const:foo`
An enum               `api|enum:Foo`
An enum-value         `api|enum-value:Foo.bar`
```

To link to the API reference of a package use the `pkg` type:

```
`api|cbl|pkg:`
```

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
