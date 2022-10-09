import React from 'react'

export interface DartClassRefProps {
  package?: string
  name: string
  accessor?: string
  method?: string
  constr?: string
}

export default function DartClassRef(props: DartClassRefProps) {
  const pkg = resolvePackage(props.package)
  const { name, accessor, method, constr } = props

  const urlBase = `${packageDocsUrlBase(pkg)}/${name}`

  let url: string
  let displayName: string
  if (props.constr !== undefined) {
    if (constr == '') {
      url = `${urlBase}/${name}.html`
      displayName = `${name}()`
    } else {
      url = `${urlBase}/${name}.${constr}.html`
      displayName = `${name}.${constr}()`
    }
  } else if (accessor) {
    url = `${urlBase}/${method}.html`
    displayName = `${name}.${method}`
  } else if (method) {
    url = `${urlBase}/${method}.html`
    displayName = `${name}.${method}()`
  } else {
    url = `${urlBase}-class.html`
    displayName = name
  }

  return (
    <a href={url} target="_blank" rel="noopener noreferrer">
      <code>{displayName}</code>
    </a>
  )
}

function resolvePackage(pgk?: string) {
  return pgk || 'cbl'
}

function packageDocsUrlBase(pkg: string) {
  if (pkg.startsWith('dart:')) {
    return `https://api.dart.dev/${pkg.replace(':', '-')}`
  } else {
    return `https://pub.dev/documentation/${pkg}/latest/${pkg}`
  }
}
