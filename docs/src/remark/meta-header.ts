import { Plugin } from 'unified'
import * as flatMap from 'unist-util-flatmap'
import { is } from 'unist-util-is'

/**
 * Remark plugin that inserts the meta header under each level 1 heading.
 */
export const metaHeader: Plugin = function () {
  return async (ast: any) => {
    flatMap.default(ast, (node) => {
      if (is(node, 'heading') && (node as any).depth == 1) {
        return [
          node,
          {
            type: 'mdxJsxFlowElement',
            name: 'MetaHeader',
            attributes: [],
            children: [],
          },
        ]
      } else {
        return [node]
      }
    })
  }
}
