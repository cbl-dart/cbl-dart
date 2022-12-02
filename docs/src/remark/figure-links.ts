const visitImport = import('unist-util-visit').then((m) => m.visit)
const isImport = import('unist-util-is').then((m) => m.is)

const referenceRegex = /(Figure|Table|Example) ([0-9]+)/

/**
 * Remark plugin that adds the URL for simple figure links.
 *
 * Figure references start with "Figure".
 * Table references start with "Table".
 * Code examples references start with "Example".
 *
 * A link is simple if it has the form: [Figure 1](#), [Table 1](#) or [Example 1](#).
 * It will be transformed into: [Figure 1](#figure-1), [Table 1](#table-1) [Example 1](#example-1).
 */
export function figureLinks() {
  return async (ast: any) => {
    // Workaround for import ES6 modules.
    const is = await isImport
    const visit = await visitImport

    visit(ast, 'link', (node) => {
      if (node.url == '#' && is(node.children[0], 'text')) {
        const value = (node.children[0] as any).value
        const match = value.match(referenceRegex)
        if (match) {
          const type = match[1].toLowerCase()
          node.url = `#${type}-${match[2]}`
        }
      }
    })
  }
}
