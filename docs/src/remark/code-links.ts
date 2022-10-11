const visitImport = import('unist-util-visit').then((m) => m.visit)

const refRegexp =
  /(api\|)([^|]+\|)?((pkg|type|new|td|ext|fn|prop|const|enum|enum-value):)?([^.|]+)?(\.[^\(\)|]+)?(\(\))?/

const defaultPackage = 'cbl'

/**
 * Remark plugin that turns <code> into links.
 *
 * The code must be formatting a specific way.
 */
export function codeLinks() {
  return async (ast: any) => {
    // Workaround for import ES6 modules.

    const visit = await visitImport

    visit(ast, 'inlineCode', (node, index, parent) => {
      const value = (node as any).value as string
      const match = value.match(refRegexp)
      if (match) {
        const pkgAndLibrary = match[2] ? match[2].slice(0, -1) : defaultPackage
        let type = match[4] ? match[4] : undefined
        const name = match[5]
        const member = match[6] ? match[6].slice(1) : undefined
        const hasParentheses = !!match[7]

        const [pkg, library] = pkgAndLibrary.split(':')

        // Type for top-level elements defaults to type.
        type ??= !member ? 'type' : undefined

        const codeRef: CodeRef = {
          pkg: pkg,
          library: library ?? pkg,
          type: type as RefType | undefined,
          name,
          member,
          hasParentheses,
        }

        const newNode = {
          type: 'link',
          url: codeRefUrl(codeRef),
          children: [
            {
              type: 'inlineCode',
              value: codeRefDisplayName(codeRef),
            },
          ],
        }

        ;(parent.children as Array<any>).splice(index, 1, newNode)
      }
    })
  }
}

type RefType =
  | 'pkg'
  | 'type'
  | 'new'
  | 'td'
  | 'ext'
  | 'fn'
  | 'prop'
  | 'const'
  | 'enum'
  | 'enum-value'

interface CodeRef {
  pkg: string
  library: string
  type?: RefType
  name?: string
  member?: string
  hasParentheses: boolean
}

function codeRefDisplayName({
  pkg,
  type,
  name,
  member,
  hasParentheses,
}: CodeRef): string {
  if (type === 'pkg') {
    return pkg
  }

  let result = name
  if (member) {
    result += '.' + member
  }
  if (hasParentheses) {
    result += '()'
  }
  return result
}

function codeRefUrl(codeRef: CodeRef): string {
  const { type, name, member } = codeRef

  if (type === 'pkg') {
    return `${packageDocsUrlBase(codeRef, { pkgRoot: true })}/index.html`
  }

  let result = `${packageDocsUrlBase(codeRef)}/${name}`

  if (type === 'type') {
    result = `${result}-class`
  } else if (type === 'new') {
    if (member) {
      result = `${result}/${name}.${member}`
    } else {
      result = `${result}/${name}`
    }
  } else if (type === 'const') {
    result = `${result}/${name}-constant`
  } else if (type === 'enum-value') {
    // Enum values have no page of their own, so we link to the enum page.
  } else {
    if (member) {
      result = `${result}/${member}`
    } else {
      result = `${result}`
    }
  }

  return `${result}.html`
}

function packageDocsUrlBase(
  { pkg, library }: CodeRef,
  { pkgRoot }: { pkgRoot?: boolean } = {}
) {
  if (pkg.startsWith('dart')) {
    return `https://api.dart.dev/${pkg}-${library}`
  } else {
    if (pkgRoot) {
      return `https://pub.dev/documentation/${pkg}/latest`
    }
    return `https://pub.dev/documentation/${pkg}/latest/${library}`
  }
}
