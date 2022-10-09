const exampleRegex = /Example ([0-9]+)/

/**
 * Remark plugin that inserts the meta header under each level 1 heading.
 */
export function metaHeader() {
  return async (ast: any) => {
    // Workaround for import ES6 modules.
    const is = (await import('unist-util-is')).is
    const flatMap = (await import('unist-util-flatmap')).default

    flatMap(ast, (node) => {
      if (is(node, 'heading') && (node as any).depth == 1) {
        return [
          node,
          {
            type: 'html',
            value: '<MetaHeader />',
          },
        ]
      } else {
        return [node]
      }
    })
  }
}
