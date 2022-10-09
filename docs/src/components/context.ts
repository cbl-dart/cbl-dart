import type { PropDocContent } from '@docusaurus/plugin-content-docs'
import React from 'react'

export const MDXContent = React.createContext<PropDocContent>({} as any)

/**
 * Returns the MDX content of the current page, including frontmatter.
 */
export function useMDXContent(): PropDocContent {
  return React.useContext(MDXContent)
}
