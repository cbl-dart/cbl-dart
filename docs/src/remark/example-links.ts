const exampleRegex = /Example ([0-9]+)/

/**
 * Remark plugin that adds the URL for simple code example links.
 *
 * A link is simple if it has the form: [Example 1](#).
 * It will be transformed into: [Example 1](#example-1).
 */
export function exampleLinks() {
  return async (ast: any) => {
    // Workaround for import ES6 modules.
    const is = (await import('unist-util-is')).is
    const visit = (await import('unist-util-visit')).visit

    visit(ast, 'link', (node) => {
      if (node.url == '#' && is(node.children[0], 'text')) {
        const value = (node.children[0] as any).value
        const match = value.match(exampleRegex)
        if (match) {
          node.url = `#example-${match[1]}`
        }
      }
    })
  }
}
