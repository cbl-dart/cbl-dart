const React = require('react')

export const MDXContent = React.createContext()

/**
 * Returns the MDX content of the current page, including frontmatter.
 */
export function useMDXContent() {
  return React.useContext(MDXContent)
}
