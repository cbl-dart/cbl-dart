const isImport = import('unist-util-is').then((m) => m.is)
const flatMapImport = import('unist-util-flatmap').then((m) => m.default)

/**
 * Remark plugin that inserts the meta header under each level 1 heading.
 */
export function metaHeader() {
  return async (ast: any) => {
    // Workaround for import ES6 modules.
    const is = await isImport
    const flatMap = await flatMapImport

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
